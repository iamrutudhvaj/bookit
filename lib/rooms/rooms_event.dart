import 'package:bookit/rooms/rooms_state.dart';
import 'package:equatable/equatable.dart';

abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object> get props => [];
}

class AddRoomEvent extends RoomEvent {}

class DeleteAllRoomEvent extends RoomEvent {}

class UpdateRoomEvent extends RoomEvent {
  final int roomIndex;
  final List<MemberModel> members;
  final bool hasPet;

  const UpdateRoomEvent({
    required this.roomIndex,
    required this.members,
    required this.hasPet,
  });

  @override
  List<Object> get props => [roomIndex, members, hasPet];
}

class DeleteRoomEvent extends RoomEvent {
  final int roomIndex;

  const DeleteRoomEvent({
    required this.roomIndex,
  });

  @override
  List<Object> get props => [roomIndex];
}

class AddBlankMemberEvent extends RoomEvent {
  final int roomIndex;

  const AddBlankMemberEvent({
    required this.roomIndex,
  });

  @override
  List<Object> get props => [roomIndex];
}

class UpdateMemberEvent extends RoomEvent {
  final int roomIndex;
  final int memberIndex;
  final String? firstName;
  final String? lastName;
  final DateTime? dob;

  const UpdateMemberEvent({
    required this.roomIndex,
    required this.memberIndex,
    this.firstName,
    this.lastName,
    this.dob,
  });

  @override
  List<Object> get props => [
        roomIndex,
        memberIndex,
        firstName ?? '',
        lastName ?? '',
        dob ?? DateTime(1970)
      ];
}

class DeleteMemberEvent extends RoomEvent {
  final int roomIndex;
  final int memberIndex;

  const DeleteMemberEvent({required this.roomIndex, required this.memberIndex});

  @override
  List<Object> get props => [roomIndex, memberIndex];
}

class AddPetEvent extends RoomEvent {
  final int roomIndex;

  const AddPetEvent({
    required this.roomIndex,
  });

  @override
  List<Object> get props => [roomIndex];
}

class SubmitRoomDataEvent extends RoomEvent {
  const SubmitRoomDataEvent();

  @override
  List<Object> get props => [];
}
