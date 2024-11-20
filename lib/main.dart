import 'package:bookit/helpers/sync_helper.dart';
import 'package:bookit/pages/home_page.dart';
import 'package:bookit/rooms/rooms_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Workmanager
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Register a periodic task
  Workmanager().registerPeriodicTask(
    "syncTask",
    "syncLocalDbToFirebase",
    frequency: const Duration(minutes: 20), // Set the frequency to 20 minutes
  );
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<RoomBloc>(
          create: (context) => RoomBloc(context),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// Define the background task callback
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "syncLocalDbToFirebase") {
      await SyncService().fullSync();
    }
    return Future.value(true);
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SyncManager _syncManager = SyncManager();

  @override
  void initState() {
    super.initState();
    _syncManager.startSync(); // Start syncing when the app starts
  }

  @override
  void dispose() {
    _syncManager.stopSync(); // Stop syncing when the app is terminated
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
