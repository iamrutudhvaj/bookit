import 'package:bookit/helpers/sync_helper.dart';
import 'package:bookit/pages/report_pages.dart';
import 'package:bookit/rooms/rooms_event.dart';
import 'package:bookit/rooms/rooms_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../rooms/rooms_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomBloc, RoomState>(
      listener: (context, state) {
        // Check if the state is SubmissionSuccess
        if (state is SubmissionSuccess) {
          context.read<RoomBloc>().add(DeleteAllRoomEvent());
          // Navigate to ReportPage after successful submission
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportPage()),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Home page'),
          actions: [
            IconButton.filledTonal(
                onPressed: () async {
                  await SyncService().fullSync();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Sync completed successfully!')),
                  );
                },
                icon: const Icon(Icons.sync)),
            IconButton.filledTonal(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportPage()),
                  );
                },
                icon: const Icon(Icons.list)),
            ElevatedButton.icon(
              onPressed: () {
                context.read<RoomBloc>().add(AddRoomEvent());
              },
              label: const Text("Add Room"),
              icon: const Icon(Icons.add),
              iconAlignment: IconAlignment.end,
            ),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
        body: BlocBuilder<RoomBloc, RoomState>(
          builder: (context, state) {
            if (state.rooms.isEmpty) {
              return const Center(
                child: Text('No Rooms Added. Click + to add a room.'),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: state.rooms.length,
                    itemBuilder: (context, index) {
                      final room = state.rooms[index];
                      return RoomCard(
                        room: room,
                        index: index,
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<RoomBloc>().add(const SubmitRoomDataEvent());
                  },
                  child: const Text('Submit'),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final int index;

  const RoomCard({
    super.key,
    required this.room,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Room ${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton.filledTonal(
                    onPressed: () {
                      context
                          .read<RoomBloc>()
                          .add(DeleteRoomEvent(roomIndex: index));
                    },
                    icon: const Icon(Icons.delete))
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: room.hasPet,
                  onChanged: (value) {
                    context.read<RoomBloc>().add(AddPetEvent(roomIndex: index));
                  },
                ),
                const Text('Do you have a pet?'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Members',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    context
                        .read<RoomBloc>()
                        .add(AddBlankMemberEvent(roomIndex: index));
                  },
                  icon: const Icon(Icons.add),
                )
              ],
            ),
            ...room.members.asMap().entries.map((entry) {
              final memberIndex = entry.key;
              final member = entry.value;
              return MemberInputField(
                member: member,
                roomIndex: index,
                memberIndex: memberIndex,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class MemberInputField extends StatelessWidget {
  final MemberModel member;
  final int roomIndex;
  final int memberIndex;

  const MemberInputField({
    super.key,
    required this.member,
    required this.roomIndex,
    required this.memberIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Member ${memberIndex + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  context.read<RoomBloc>().add(DeleteMemberEvent(
                        roomIndex: roomIndex,
                        memberIndex: memberIndex,
                      ));
                },
                icon: const Icon(Icons.delete),
              )
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: member.firstName,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  onChanged: (value) {
                    context.read<RoomBloc>().add(UpdateMemberEvent(
                          roomIndex: roomIndex,
                          memberIndex: memberIndex,
                          firstName: value,
                        ));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: member.lastName,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  onChanged: (value) {
                    context.read<RoomBloc>().add(UpdateMemberEvent(
                          roomIndex: roomIndex,
                          memberIndex: memberIndex,
                          lastName: value,
                        ));
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: member.dob.toLocal().toString().split(' ')[0],
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: member.dob,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      context.read<RoomBloc>().add(UpdateMemberEvent(
                            roomIndex: roomIndex,
                            memberIndex: memberIndex,
                            dob: pickedDate,
                          ));
                    }
                  },
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: member.isChild,
                      onChanged: (_) {
                        // No manual toggle; derived from DOB
                      },
                    ),
                    const Text(
                      'Child',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider()
        ],
      ),
    );
  }
}
