import 'package:equatable/equatable.dart';

class RoomState extends Equatable {
  final List<RoomModel> rooms;

  const RoomState({this.rooms = const []});

  RoomState copyWith({List<RoomModel>? rooms}) {
    return RoomState(
      rooms: rooms ?? this.rooms,
    );
  }

  @override
  List<Object> get props => [rooms];
}

class RoomModel extends Equatable {
  final String roomId; // Common unique identifier for Firebase and local DB
  final List<MemberModel> members; // List of members
  final bool hasPet; // Indicates if the room has a pet

  const RoomModel({
    required this.roomId,
    this.members = const [],
    this.hasPet = false,
  });

  RoomModel copyWith({
    String? roomId,
    List<MemberModel>? members,
    bool? hasPet,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      members: members ?? this.members,
      hasPet: hasPet ?? this.hasPet,
    );
  }

  // Convert RoomModel to a Map for Firebase or local DB
  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'hasPet': hasPet,
      'members': members.map((member) => member.toMap()).toList(),
    };
  }

  // Create a RoomModel from a Map (e.g., from Firebase or local DB)
  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      roomId: map['roomId'],
      hasPet: map['hasPet'] ?? false,
      members: (map['members'] as List<dynamic>)
          .map((member) => MemberModel.fromMap(member))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [roomId, members, hasPet];
}

class MemberModel extends Equatable {
  final String firstName;
  final String lastName;
  final DateTime dob;
  final bool isChild; // Derived based on DOB

  const MemberModel({
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.isChild,
  });

  MemberModel copyWith({
    String? firstName,
    String? lastName,
    DateTime? dob,
    bool? isChild,
  }) {
    return MemberModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dob: dob ?? this.dob,
      isChild: isChild ?? this.isChild,
    );
  }

  // Convert MemberModel to a Map for Firebase or local DB
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'dob': dob.toIso8601String(),
      'isChild': isChild,
    };
  }

  // Create a MemberModel from a Map
  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      firstName: map['firstName'],
      lastName: map['lastName'],
      dob: DateTime.parse(map['dob']),
      isChild: map['isChild'] ?? false,
    );
  }

  @override
  List<Object?> get props => [firstName, lastName, dob, isChild];
}

class SubmissionState extends RoomState {
  final bool isSubmitting;
  final String? errorMessage;

  const SubmissionState({
    required super.rooms,
    this.isSubmitting = false,
    this.errorMessage,
  });
}

class SubmissionSuccess extends RoomState {}
