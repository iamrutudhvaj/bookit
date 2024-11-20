import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'database_helper.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sync local database to Firebase
  Future<void> syncLocalDbToFirebase() async {
    final rooms = await DatabaseHelper.instance.fetchRoomsWithMembers();

    for (final room in rooms) {
      final roomDoc = _firestore
          .collection('rooms')
          .doc(room.roomId); // Use roomId as the document ID

      await roomDoc.set({
        'hasPet': room.hasPet,
        'members': room.members.map((member) {
          return {
            'firstName': member.firstName,
            'lastName': member.lastName,
            'dob': member.dob.toIso8601String(),
            'isChild': member.isChild,
          };
        }).toList(),
      });
    }

    print("Local database synced with Firebase!");
  }

  /// Sync Firebase data to local database
  Future<void> syncFirebaseToLocalDb() async {
    final db = await DatabaseHelper.instance.database;

    // Fetch all room documents from Firestore
    final roomsSnapshot = await _firestore.collection('rooms').get();

    for (final doc in roomsSnapshot.docs) {
      final roomData = doc.data();
      final roomId = doc.id;

      // Check if the room exists in the local database
      final existingRoom = await db.query(
        'rooms',
        where: 'roomId = ?',
        whereArgs: [roomId],
      );

      if (existingRoom.isEmpty) {
        // Insert new room
        await db.insert('rooms', {
          'roomId': roomId,
          'hasPet': roomData['hasPet'] ? 1 : 0,
        });

        // Insert members
        for (final member in roomData['members']) {
          await db.insert('members', {
            'roomId': roomId,
            'firstName': member['firstName'],
            'lastName': member['lastName'],
            'dob': member['dob'],
            'isChild': member['isChild'] ? 1 : 0,
          });
        }
      } else {
        // Update existing room
        await db.update(
          'rooms',
          {'hasPet': roomData['hasPet'] ? 1 : 0},
          where: 'roomId = ?',
          whereArgs: [roomId],
        );

        // Replace members
        await db.delete('members', where: 'roomId = ?', whereArgs: [roomId]);
        for (final member in roomData['members']) {
          await db.insert('members', {
            'roomId': roomId,
            'firstName': member['firstName'],
            'lastName': member['lastName'],
            'dob': member['dob'],
            'isChild': member['isChild'] ? 1 : 0,
          });
        }
      }
    }

    print("Firebase data synced to local database!");
  }

  /// Full Sync: Sync both directions
  Future<void> fullSync() async {
    await syncLocalDbToFirebase();
    await syncFirebaseToLocalDb();
  }
}

class SyncManager {
  Timer? _timer;

  void startSync() {
    // Schedule the sync every 20 minutes
    _timer = Timer.periodic(const Duration(minutes: 20), (timer) async {
      await SyncService().fullSync();
    });
    print("Sync scheduled every 20 minutes.");
  }

  void stopSync() {
    _timer?.cancel();
    print("Sync stopped.");
  }
}
