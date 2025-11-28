```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../secrets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = SupabaseClient(
  Secrets.supabaseUrl,
  Secrets.supabaseAnonKey,
);

class RoomService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSub;
  String? currentRoomId;
  Map<String, dynamic>? roomData;

  void joinRoom(String roomId) {
    leaveRoom();
    currentRoomId = roomId;
    _roomSub = _db.collection('rooms').doc(roomId).snapshots().listen((snap) {
      if (!snap.exists) return;
      roomData = snap.data()!;
      notifyListeners();
    });
  }

  void leaveRoom() {
    _roomSub?.cancel();
    _roomSub = null;
    currentRoomId = null;
    roomData = null;
    notifyListeners();
  }

  Future<void> updateRoom(Map<String, dynamic> data) async {
    if (currentRoomId == null) return;
    data['lastUpdate'] = DateTime.now().millisecondsSinceEpoch;
    await _db.collection('rooms').doc(currentRoomId).set(data, SetOptions(merge: true));
  }

  Future<void> sendMessage(String user, String text) async {
    if (currentRoomId == null) return;
    await _db.collection('rooms').doc(currentRoomId).collection('chat').add({
      'user': user,
      'text': text,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> addToQueue(String videoId, String title) async {
    if (currentRoomId == null) return;
    final queueRef = _db.collection('rooms').doc(currentRoomId).collection('queue');
    await queueRef.add({'videoId': videoId, 'title': title, 'addedAt': DateTime.now().millisecondsSinceEpoch});
  }

  Future<void> popNextInQueueAndPlay() async {
    if (currentRoomId == null) return;
    final queueRef = _db.collection('rooms').doc(currentRoomId).collection('queue');
    final snaps = await queueRef.orderBy('addedAt').limit(1).get();
    if (snaps.docs.isEmpty) return;
    final doc = snaps.docs.first;
    final data = doc.data();
    await updateRoom({'videoId': data['videoId'], 'position': 0, 'isPlaying': true});
    await doc.reference.delete();
  }
}
```
