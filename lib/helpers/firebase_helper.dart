import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to delete all documents in a Firestore collection
  static Future<void> clearFirestoreCollection(String collectionName) async {
    try {
      final collection = _firestore.collection(collectionName);
      final snapshots = await collection.get();

      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }

      print('$collectionName collection cleared successfully.');
    } catch (e) {
      print('Error clearing Firestore collection: $e');
    }
  }

  // Method to clear multiple collections
  static Future<void> clearAllFirestoreData() async {
    await clearFirestoreCollection(
        'rooms'); // Replace 'rooms' with your collection name
    // Add more collections if needed
  }
}
