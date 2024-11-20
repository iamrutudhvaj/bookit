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

class RoomModel {
  final List<MemberModel> members; // Updated to use MemberModel
  final bool hasPet;

  RoomModel({
    this.members = const [],
    this.hasPet = false,
  });

  RoomModel copyWith({
    List<MemberModel>? members,
    bool? hasPet,
  }) {
    return RoomModel(
      members: members ?? this.members,
      hasPet: hasPet ?? this.hasPet,
    );
  }
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

  @override
  List<Object> get props => [firstName, lastName, dob, isChild];
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
