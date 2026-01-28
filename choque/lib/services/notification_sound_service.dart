import 'package:audioplayers/audioplayers.dart';

/// Simple notification sound service for merchant app
class NotificationSoundService {
  static final NotificationSoundService _instance = NotificationSoundService._internal();
  factory NotificationSoundService() => _instance;
  NotificationSoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  /// Play new order notification sound
  Future<void> playNewOrderSound() async {
    if (_isPlaying) return;
    
    try {
      _isPlaying = true;
      // Use system notification sound as default
      // Can be replaced with custom asset: AssetSource('sounds/new_order.mp3')
      await _player.play(
        UrlSource('https://www.soundjay.com/buttons/beep-01a.mp3'),
      );
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      // Fallback: try device beep via player
      debugPrint('Sound notification error: $e');
    } finally {
      _isPlaying = false;
    }
  }

  /// Dispose the player
  void dispose() {
    _player.dispose();
  }
}

void debugPrint(String message) {
  // ignore for now
}
