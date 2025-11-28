// lib/screens/room.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:share_plus/share_plus.dart';
import '../services/room_service.dart';
import '../services/background_player.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;
  const RoomScreen({super.key, required this.roomId});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late YoutubePlayerController _ytController;
  final videoController = TextEditingController();
  Timer? _syncTimer;
  Timer? _localTicker;
  bool _isSeeking = false;

  late BackgroundAudioHandler _bgHandler;

  @override
  void initState() {
    super.initState();

    final roomSvc = Provider.of<RoomService>(context, listen: false);
    roomSvc.joinRoom(widget.roomId);

    _bgHandler = BackgroundAudioHandler();

    _ytController = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        autoPlay: false,
        controlsVisibleAtStart: true,
      ),
    );

    _ytController.listen((value) async {
      if (_isSeeking) return;
      final playing = value.playerState == PlayerState.playing;
      final pos = await _ytController.currentTime;
      await roomSvc.updateRoom({'position': pos, 'isPlaying': playing});
    });

    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) => _applyServerState());

    _localTicker = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      final room = roomSvc.roomData;
      if (room == null) return;
      final serverPos = (room['position'] ?? 0).toDouble();
      final isPlaying = room['isPlaying'] ?? false;
      final lastUpdate = room['lastUpdate'] ?? DateTime.now().millisecondsSinceEpoch;
      final drift = (DateTime.now().millisecondsSinceEpoch - lastUpdate) / 1000.0;
      final expectedPos = isPlaying ? serverPos + drift : serverPos;
      final currentLocal = await _ytController.currentTime;
      final diff = (expectedPos - currentLocal).abs();
      if (diff > 1.0) {
        _isSeeking = true;
        await _ytController.seekTo(expectedPos);
        _isSeeking = false;
      }
    });
  }

  Future<void> _applyServerState() async {
    final roomSvc = Provider.of<RoomService>(context, listen: false);
    final room = roomSvc.roomData;
    if (room == null) return;

    final videoId = room['videoId'];
    final serverPos = (room['position'] ?? 0).toDouble();
    final isPlaying = room['isPlaying'] ?? false;
    final lastUpdate = room['lastUpdate'] ?? DateTime.now().millisecondsSinceEpoch;
    final drift = (DateTime.now().millisecondsSinceEpoch - lastUpdate) / 1000.0;
    final targetPos = isPlaying ? serverPos + drift : serverPos;

    final currentVid = await _ytController.getVideoId();
    if (videoId != null && videoId != currentVid) {
      _isSeeking = true;
      await _ytController.loadVideoById(videoId: videoId, startSeconds: targetPos);
      _isSeeking = false;

      // Play background audio
      final videoUrl = "https://www.youtube.com/watch?v=$videoId";
      await _bgHandler.playYoutubeAudio(videoUrl);
    }

    final state = await _ytController.playerState;
    if (isPlaying && state != PlayerState.playing) {
      await _ytController.playVideo();
    } else if (!isPlaying && state == PlayerState.playing) {
      await _ytController.pauseVideo();
    }

    final localPos = await _ytController.currentTime;
    final diff = (localPos - targetPos).abs();
    if (diff > 0.8) {
      _isSeeking = true;
      await _ytController.seekTo(targetPos);
      _isSeeking = false;
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _localTicker?.cancel();
    Provider.of<RoomService>(context, listen: false).leaveRoom();
    _ytController.close();
    _bgHandler.dispose();
    super.dispose();
  }

  void _shareRoom() {
    Share.share('Join my CoupleSync room: ${widget.roomId}');
  }

  @override
  Widget build(BuildContext context) {
    final roomSvc = Provider.of<RoomService>(context);
    final room = roomSvc.roomData;
    final videoId = room?['videoId'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomId}'),
        actions: [IconButton(onPressed: _shareRoom, icon: const Icon(Icons.share))],
      ),
      body: Column(
        children: [
          if (videoId != null)
            SizedBox(height: 220, child: YoutubePlayer(controller: _ytController)),
          if (videoId == null)
            Container(
              height: 180,
              color: Colors.pink.shade900,
              child: const Center(child: Text('No song loaded — add a YouTube ID below')),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: videoController,
                  decoration: const InputDecoration(labelText: 'YouTube Video ID or full URL'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final raw = videoController.text.trim();
                  if (raw.isEmpty) return;

                  String id = raw;
                  if (raw.contains('v=')) {
                    final uri = Uri.parse(raw);
                    id = uri.queryParameters['v'] ?? raw;
                  } else if (raw.contains('youtu.be/')) {
                    id = raw.split('youtu.be/').last;
                  }

                  await roomSvc.updateRoom({'videoId': id, 'position': 0});
                  videoController.clear();

                  // Play audio in background
                  final videoUrl = "https://www.youtube.com/watch?v=$id";
                  await _bgHandler.playYoutubeAudio(videoUrl);
                },
                child: const Text('Load'),
              )
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final state = await _ytController.playerState;
          final isPlaying = state == PlayerState.playing;
          await roomSvc.updateRoom({'isPlaying': !isPlaying});

          if (isPlaying) {
            await _bgHandler.pause();
          } else {
            await _bgHandler.play();
          }
        },
        label: const Text('Play/Pause (sync)'),
        icon: const Icon(Icons.sync),
      ),
    );
  }
}
