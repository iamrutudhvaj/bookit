import 'package:bookit/helpers/database_helper.dart';
import 'package:bookit/helpers/firebase_helper.dart';
import 'package:bookit/rooms/rooms_state.dart';
import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<List<RoomModel>> rooms;

  @override
  void initState() {
    super.initState();
    // Fetch data from the local database when the page loads
    rooms = DatabaseHelper.instance.fetchRoomsWithMembers();
  }

  void _clearDatabase() async {
    // Clear local database
    await DatabaseHelper.instance.clearDatabase();

    // Clear Firestore data
    await FirebaseHelper.clearAllFirestoreData();

    // Update UI
    setState(() {
      rooms = Future.value([]); // Reset the rooms list to empty
    });

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Local and Firebase data cleared successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearDatabase, // Call the clear database method
            tooltip: 'Clear Database',
          ),
        ],
      ),
      body: FutureBuilder<List<RoomModel>>(
        future: rooms,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available.'));
          }

          final rooms = snapshot.data!;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Room ${index + 1}:',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Display members
                      ...room.members
                          .where((member) => !member.isChild)
                          .map((member) {
                        return Text(
                          '${member.firstName} ${member.lastName} - ${_calculateAge(member.dob)} years',
                          style: const TextStyle(fontSize: 16),
                        );
                      }),
                      // Display children if any
                      if (room.members.any((member) => member.isChild))
                        ...room.members
                            .where((member) => member.isChild)
                            .map((child) {
                          return Text(
                            '${child.firstName} ${child.lastName} - ${_calculateAge(child.dob)} years (Child)',
                            style: const TextStyle(fontSize: 16),
                          );
                        }),
                      // Display pet status
                      Text(
                        room.hasPet ? 'Pet: Yes' : 'Pet: No',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Calculate the age based on DOB
  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
