// lib/services/background_player.dart

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'secrets.dart'; // contains your YouTube API key if needed

class BackgroundAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final _yt = YoutubeExplode();

  BackgroundAudioHandler() {
    // Listen to player state changes and update playback state
    _player.playerStateStream.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.play,
          MediaControl.pause,
          MediaControl.stop,
        ],
        playing: state.playing,
        processingState: AudioProcessingState.ready,
      ));
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  /// Play audio from a YouTube URL in background
  Future<void> playYoutubeAudio(String url) async {
    try {
      // Extract video info
      var videoId = YoutubeExplode.parseVideoId(url);
      if (videoId == null) throw Exception('Invalid YouTube URL');

      var video = await _yt.videos.get(videoId);

      // Get the audio stream manifest
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      var audioStreamInfo = manifest.audioOnly.withHighestBitrate();

      if (audioStreamInfo != null) {
        // Play audio from the URL
        await _player.setUrl(audioStreamInfo.url.toString());
        await _player.play();
      }
    } catch (e) {
      print('Error playing YouTube audio: $e');
    }
  }

  @override
  Future<void> setUrl(String url) async {
    // Direct URL support
    await _player.setUrl(url);
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stopAudio() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
    _yt.close();
  }
}
