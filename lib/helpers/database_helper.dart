import 'dart:async';

import 'package:bookit/rooms/rooms_state.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static const _dbName = 'rooms.db';
  static const _dbVersion = 1;

  static const tableRoom = 'rooms';
  static const tableMember = 'members';

  static Database? _database;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  final uuid = const Uuid();
  String generateRoomId() {
    return uuid.v4(); // Generates a unique UUID
  }

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
      onUpgrade: _onUpgrade,
    );
  }

  // Add migration to handle schema upgrades (in case roomId column is missing)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the roomId column if it's not present
      await db.execute('''
        ALTER TABLE $tableRoom ADD COLUMN roomId TEXT UNIQUE;
      ''');
    }
  }

  // Create tables when the database is created
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableRoom (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roomId TEXT UNIQUE, -- Common unique ID
        hasPet INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableMember (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roomId TEXT,
        firstName TEXT,
        lastName TEXT,
        dob TEXT,
        isChild INTEGER,
        FOREIGN KEY (roomId) REFERENCES $tableRoom (roomId)
      )
    ''');
  }

  // // Insert a room into the rooms table
  // Future<int> insertRoom(Map<String, dynamic> row) async {
  //   Database db = await instance.database;
  //   return await db.insert(tableRoom, row);
  // }

  Future<int> insertRoom({required bool hasPet}) async {
    final db = await instance.database;
    final roomId = generateRoomId(); // Generate unique room ID

    return await db.insert('rooms', {
      'roomId': roomId,
      'hasPet': hasPet ? 1 : 0,
    });
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
      String roomId = roomMap['roomId'];
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
        roomId: roomMap['roomId'],
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
