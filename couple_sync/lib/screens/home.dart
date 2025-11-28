import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'room.dart';
import '../widgets/couple_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final roomController = TextEditingController();

  @override
  void dispose() {
    roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CoupleSync 💕")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CoupleHeader(
              partner1Name: "Ankit",
              partner2Name: "",
              partner1Image: "https://example.com/partner1.jpg",
              partner2Image: "https://example.com/partner2.jpg",
            ),
            const SizedBox(height: 20),
            TextField(
              controller: roomController,
              decoration: const InputDecoration(
                labelText: "Enter Room ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (roomController.text.trim().isEmpty) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RoomScreen(roomId: roomController.text.trim()),
                  ),
                );
              },
              child: const Text("Join Room"),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                String newRoom = const Uuid().v4().substring(0, 6);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomScreen(roomId: newRoom),
                  ),
                );
              },
              child: const Text("Create Room"),
            ),
            const SizedBox(height: 20),
            const Text('Designed for couples — pink hearts theme 😘'),
          ],
        ),
      ),
    );
  }
}
