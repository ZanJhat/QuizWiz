import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class QuizFeedback {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> correct() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sfx/correct.wav'));
    } catch (_) {}
  }

  static Future<void> wrong() async {
    try {
      await HapticFeedback.vibrate();
      await HapticFeedback.heavyImpact();
    } catch (_) {}
    try {
      await _player.stop();
      await _player.play(AssetSource('sfx/wrong.wav'));
    } catch (_) {}
  }
}
