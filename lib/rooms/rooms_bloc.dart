import 'package:bookit/helpers/database_helper.dart';
import 'package:bookit/rooms/rooms_event.dart';
import 'package:bookit/rooms/rooms_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final BuildContext context;
  RoomBloc(this.context) : super(const RoomState()) {
    on<AddRoomEvent>(_onAddRoom);
    on<DeleteAllRoomEvent>(_onDeleteAllRoom);
    on<UpdateRoomEvent>(_onUpdateRoom);
    on<DeleteRoomEvent>(_onDeleteRoom);
    on<SubmitRoomDataEvent>(_onSubmitRoomData);
    on<AddBlankMemberEvent>(_onAddBlankMember);
    on<UpdateMemberEvent>(_onUpdateMember);
    on<DeleteMemberEvent>(_onDeleteMember);
    on<AddPetEvent>(_onAddPet);
  }

  void _onAddRoom(AddRoomEvent event, Emitter<RoomState> emit) {
    final newRoom = RoomModel();
    final updatedRooms = List<RoomModel>.from(state.rooms)..add(newRoom);
    emit(state.copyWith(rooms: updatedRooms));
  }

  void _onDeleteAllRoom(DeleteAllRoomEvent event, Emitter<RoomState> emit) {
    final updatedRooms = List<RoomModel>.from(state.rooms);
    updatedRooms.clear();
    emit(state.copyWith(rooms: updatedRooms));
  }

  void _onDeleteRoom(DeleteRoomEvent event, Emitter<RoomState> emit) {
    final updatedRooms = List<RoomModel>.from(state.rooms);
    if (event.roomIndex < updatedRooms.length) {
      updatedRooms.removeAt(event.roomIndex);
    }
    emit(state.copyWith(rooms: updatedRooms));
  }

  void _onUpdateRoom(UpdateRoomEvent event, Emitter<RoomState> emit) {
    final updatedRooms = List<RoomModel>.from(state.rooms);
    if (event.roomIndex < updatedRooms.length) {
      updatedRooms[event.roomIndex] = updatedRooms[event.roomIndex].copyWith(
        members: event.members,
        hasPet: event.hasPet,
      );
    }
    emit(state.copyWith(rooms: updatedRooms));
  }

  void _onAddBlankMember(AddBlankMemberEvent event, Emitter<RoomState> emit) {
    final rooms = List<RoomModel>.from(state.rooms);
    final room = rooms[event.roomIndex];

    // Add a blank member
    final blankMember = MemberModel(
      firstName: '',
      lastName: '',
      dob: DateTime.now(),
      isChild: false, // Default to false; updated based on DOB later
    );

    final updatedMembers = List<MemberModel>.from(room.members)
      ..add(blankMember);
    rooms[event.roomIndex] = room.copyWith(members: updatedMembers);

    emit(state.copyWith(rooms: rooms));
  }

  void _onUpdateMember(UpdateMemberEvent event, Emitter<RoomState> emit) {
    final rooms = List<RoomModel>.from(state.rooms);
    final room = rooms[event.roomIndex];

    final updatedMembers = List<MemberModel>.from(room.members);
    final member = updatedMembers[event.memberIndex];

    // Update member fields
    updatedMembers[event.memberIndex] = member.copyWith(
      firstName: event.firstName ?? member.firstName,
      lastName: event.lastName ?? member.lastName,
      dob: event.dob ?? member.dob,
      isChild: event.dob != null
          ? DateTime.now().difference(event.dob!).inDays ~/ 365 < 3
          : member.isChild,
    );

    rooms[event.roomIndex] = room.copyWith(members: updatedMembers);

    emit(state.copyWith(rooms: rooms));
  }

  void _onDeleteMember(DeleteMemberEvent event, Emitter<RoomState> emit) {
    final rooms = List<RoomModel>.from(state.rooms);
    final room = rooms[event.roomIndex];

    final updatedMembers = List<MemberModel>.from(room.members);
    updatedMembers.removeAt(event.memberIndex);

    rooms[event.roomIndex] = room.copyWith(members: updatedMembers);

    emit(state.copyWith(rooms: rooms));
  }

  void _onAddPet(AddPetEvent event, Emitter<RoomState> emit) {
    final rooms = List<RoomModel>.from(state.rooms);
    final room = rooms[event.roomIndex];

    // Validate pet constraint
    if (room.hasPet) {
      // Room already has a pet
      rooms[event.roomIndex] = room.copyWith(hasPet: false);

      emit(state.copyWith(rooms: rooms));
      return;
    }

    // Ensure no other room has a pet
    if (rooms.any((r) => r.hasPet)) {
      // Another room already has a pet
      return;
    }

    // Add pet to the room
    rooms[event.roomIndex] = room.copyWith(hasPet: true);

    emit(state.copyWith(rooms: rooms));
  }

  void _onSubmitRoomData(
      SubmitRoomDataEvent event, Emitter<RoomState> emit) async {
    emit(SubmissionState(rooms: state.rooms, isSubmitting: true));

    try {
      await _saveToLocalDatabase(state.rooms);
      await _uploadToFirebase(state.rooms);

      // Navigate to the Report Page
      emit(SubmissionSuccess());

      // Back to normal state after success
      emit(state);
    } catch (e) {
      // Handle error
      emit(SubmissionState(
        rooms: state.rooms,
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
    }
  }

// Save rooms to local database
  Future<void> _saveToLocalDatabase(List<RoomModel> rooms) async {
    final db = await DatabaseHelper.instance.database;

    // Start a database transaction to ensure consistency
    await db.transaction((txn) async {
      // Loop through each room and insert into the rooms table
      for (var room in rooms) {
        // Insert room into 'rooms' table
        final roomId = await txn.insert('rooms', {
          'hasPet':
              room.hasPet ? 1 : 0, // Store hasPet as 1 (true) or 0 (false)
        });

        // Insert each member for the room into the 'members' table
        for (var member in room.members) {
          await txn.insert('members', {
            'roomId': roomId, // Associate the member with the room ID
            'firstName': member.firstName,
            'lastName': member.lastName,
            'dob': member.dob.toIso8601String(), // Store DOB as ISO 8601 string
            'isChild': member.isChild
                ? 1
                : 0, // Store 'isChild' as 1 (true) or 0 (false)
          });
        }
      }
    });
  }

// Upload rooms to Firebase
  Future<void> _uploadToFirebase(List<RoomModel> rooms) async {
    final firestore = FirebaseFirestore.instance;

    for (var room in rooms) {
      final roomDoc = firestore.collection('rooms').doc();
      await roomDoc.set({
        'hasPet': room.hasPet,
        'members': room.members
            .map((member) => {
                  'firstName': member.firstName,
                  'lastName': member.lastName,
                  'dob': member.dob.toIso8601String(),
                  'isChild': member.isChild,
                })
            .toList(),
      });
    }
  }
}
