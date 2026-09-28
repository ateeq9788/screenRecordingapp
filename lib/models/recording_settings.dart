import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingSettings extends ChangeNotifier {
  static const String _prefResolution = 'rec_setting_resolution';
  static const String _prefFps = 'rec_setting_fps';
  static const String _prefAudio = 'rec_setting_audio';
  static const String _prefCountdown = 'rec_setting_countdown';
  static const String _prefShakeToStop = 'rec_setting_shake';
  static const String _prefFloating = 'rec_setting_floating';

  String _resolution = '720p'; // '480p', '720p', '1080p' (1080p is VIP PRO)
  int _fps = 60; // 30, 60
  String _audioSource = 'mic'; // 'mic', 'internal', 'mute'
  int _countdownSeconds = 3; // 0, 3, 5
  bool _shakeToStop = true;
  bool _floatingControlsEnabled = true;

  String get resolution => _resolution;
  bool get isProResolution => _resolution == '1080p';
  int get fps => _fps;
  String get audioSource => _audioSource;
  int get countdownSeconds => _countdownSeconds;
  bool get shakeToStop => _shakeToStop;
  bool get floatingControlsEnabled => _floatingControlsEnabled;

  int get width {
    switch (_resolution) {
      case '480p':
        return 480;
      case '720p':
        return 720;
      case '1080p':
      default:
        return 1080;
    }
  }

  int get height {
    switch (_resolution) {
      case '480p':
        return 854;
      case '720p':
        return 1280;
      case '1080p':
      default:
        return 1920;
    }
  }

  int get bitrate {
    switch (_resolution) {
      case '480p':
        return 2500000;
      case '720p':
        return 5000000;
      case '1080p':
      default:
        return 12000000; // 12 Mbps crystal-clear capture
    }
  }

  RecordingSettings() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _resolution = prefs.getString(_prefResolution) ?? '720p';
    _fps = prefs.getInt(_prefFps) ?? 60;
    _audioSource = prefs.getString(_prefAudio) ?? 'mic';
    _countdownSeconds = prefs.getInt(_prefCountdown) ?? 3;
    _shakeToStop = prefs.getBool(_prefShakeToStop) ?? true;
    _floatingControlsEnabled = prefs.getBool(_prefFloating) ?? true;
    notifyListeners();
  }

  /// Automatically downgrade to 720p if user is not VIP and current setting is 1080p
  Future<void> sanitizeForVip(bool isVip) async {
    if (!isVip && _resolution == '1080p') {
      await setResolution('720p');
    }
  }

  Future<void> setResolution(String res) async {
    _resolution = res;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefResolution, res);
  }

  Future<void> setFps(int fpsVal) async {
    _fps = fpsVal;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefFps, fpsVal);
  }

  Future<void> setAudioSource(String source) async {
    _audioSource = source;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefAudio, source);
  }

  Future<void> setCountdown(int seconds) async {
    _countdownSeconds = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefCountdown, seconds);
  }

  Future<void> setShakeToStop(bool enabled) async {
    _shakeToStop = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefShakeToStop, enabled);
  }

  Future<void> setFloatingControls(bool enabled) async {
    _floatingControlsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefFloating, enabled);
  }
}
