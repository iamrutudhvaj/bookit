import 'dart:async';

import 'package:bookit/rooms/rooms_state.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = 'rooms.db';
  static const _dbVersion = 1;

  static const tableRoom = 'rooms';
  static const tableMember = 'members';

  static Database? _database;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Initialize the database
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the path to the database
    String path = join(await getDatabasesPath(), _dbName);

    // Open the database (if it doesn't exist, it will be created)
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  // Create tables when the database is created
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableRoom (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hasPet INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableMember (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roomId INTEGER,
        firstName TEXT,
        lastName TEXT,
        dob TEXT,
        isChild INTEGER,
        FOREIGN KEY (roomId) REFERENCES $tableRoom (id)
      )
    ''');
  }

  // Insert a room into the rooms table
  Future<int> insertRoom(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableRoom, row);
  }

  // Insert a member into the members table
  Future<int> insertMember(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableMember, row);
  }

  // Get all rooms
  Future<List<Map<String, dynamic>>> getRooms() async {
    Database db = await instance.database;
    return await db.query(tableRoom);
  }

  // Get all members in a specific room
  Future<List<Map<String, dynamic>>> getMembersInRoom(int roomId) async {
    Database db = await instance.database;
    return await db.query(
      tableMember,
      where: 'roomId = ?',
      whereArgs: [roomId],
    );
  }

  // Update a room (e.g., hasPet status)
  Future<int> updateRoom(int roomId, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.update(
      tableRoom,
      row,
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  // Update a member (e.g., name, dob)
  Future<int> updateMember(int memberId, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.update(
      tableMember,
      row,
      where: 'id = ?',
      whereArgs: [memberId],
    );
  }

  // Delete a room
  Future<int> deleteRoom(int roomId) async {
    Database db = await instance.database;
    return await db.delete(
      tableRoom,
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  // Delete a member
  Future<int> deleteMember(int memberId) async {
    Database db = await instance.database;
    return await db.delete(
      tableMember,
      where: 'id = ?',
      whereArgs: [memberId],
    );
  }

  Future<List<RoomModel>> fetchRoomsWithMembers() async {
    final db = await DatabaseHelper.instance.database;

    // Fetch all rooms
    List<Map<String, dynamic>> roomMaps = await db.query('rooms');

    List<RoomModel> rooms = [];
    for (var roomMap in roomMaps) {
      // For each room, fetch associated members
      int roomId = roomMap['id'];
      List<Map<String, dynamic>> memberMaps = await db.query(
        'members',
        where: 'roomId = ?',
        whereArgs: [roomId],
      );

      List<MemberModel> members = memberMaps.map((memberMap) {
        return MemberModel(
          firstName: memberMap['firstName'],
          lastName: memberMap['lastName'],
          dob: DateTime.parse(memberMap['dob']),
          isChild: memberMap['isChild'] == 1,
        );
      }).toList();

      // Add room with members to the list
      rooms.add(RoomModel(
        hasPet: roomMap['hasPet'] == 1,
        members: members,
      ));
    }

    return rooms;
  }

  // clear the db
  Future<void> clearDatabase() async {
    Database db = await instance.database;
    await db.execute('DELETE FROM $tableRoom');
    await db.execute('DELETE FROM $tableMember');
  }
}
