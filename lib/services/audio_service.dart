import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  void playStartSound() async {
    try {
      // Plays system cheer/beep audio sound
      await _player.play(AssetSource('audio/start.mp3'));
    } catch (_) {
      // Silent catch if audio assets are missing in dev mode
    }
  }

  void playFinishSound() async {
    try {
      await _player.play(AssetSource('audio/finish.mp3'));
    } catch (_) {}
  }

  void playRandomCheer() async {
    try {
      await _player.play(AssetSource('audio/cheer.mp3'));
    } catch (_) {}
  }
}
