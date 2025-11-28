import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/home.dart';
import 'services/room_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SyncMusicApp());
}

class SyncMusicApp extends StatelessWidget {
  const SyncMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoomService()),
      ],
      child: MaterialApp(
        title: 'CoupleSync',
        theme: ThemeData(
          primarySwatch: Colors.pink,
          brightness: Brightness.dark,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
