import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ed_screen_recorder/ed_screen_recorder.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recording_item.dart';
import '../models/recording_settings.dart';
import 'ad_service.dart';
import 'remote_ad_config.dart';

class ScreenRecordingService extends ChangeNotifier {
  static const String _recordingsPrefKey = "screen_recorder_items_list";

  final EdScreenRecorder _recorder = EdScreenRecorder();
  final List<RecordingItem> _recordings = [];
  List<RecordingItem> get recordings => List.unmodifiable(_recordings);

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isCountdownActive = false;
  int _countdownSeconds = 3;

  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  DateTime? _recordingStartTime;
  String? _currentFileName;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  bool get isCountdownActive => _isCountdownActive;
  int get countdownSeconds => _countdownSeconds;
  Duration get recordingDuration => _recordingDuration;

  String get formattedDuration {
    final m = _recordingDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _recordingDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  ScreenRecordingService() {
    loadSavedRecordings();
  }

  Future<void> loadSavedRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recordingsPrefKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _recordings.clear();
        for (var item in decoded) {
          final rec = RecordingItem.fromJson(item as Map<String, dynamic>);
          // Only keep existing files
          if (File(rec.path).existsSync()) {
            _recordings.add(rec);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ScreenRecordingService] Error loading recordings: $e');
    }
  }

  Future<void> _saveRecordingsList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_recordings.map((e) => e.toJson()).toList());
      await prefs.setString(_recordingsPrefKey, encoded);
    } catch (e) {
      debugPrint('[ScreenRecordingService] Error saving list: $e');
    }
  }

  /// Request all required system permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    // Microphone
    await Permission.microphone.request();

    // Notifications (Android 13+)
    await Permission.notification.request();

    // Storage / Videos
    if (Platform.isAndroid) {
      await Permission.videos.request();
      await Permission.storage.request();
    }

    return true;
  }

  /// Start recording with countdown sequence
  Future<String?> startRecording({
    required RecordingSettings settings,
    required bool isVip,
    VoidCallback? onRecordingStarted,
  }) async {
    if (_isRecording || _isCountdownActive) return null;

    await requestPermissions();

    // Run Countdown sequence
    if (settings.countdownSeconds > 0) {
      _isCountdownActive = true;
      _countdownSeconds = settings.countdownSeconds;
      notifyListeners();

      while (_countdownSeconds > 0) {
        await Future.delayed(const Duration(seconds: 1));
        _countdownSeconds--;
        notifyListeners();
      }

      _isCountdownActive = false;
      notifyListeners();
    }

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentFileName = "REC_$timestamp";

      final recordAudio = settings.audioSource != 'mute';

      // Security Check: 1080p Full HD is strictly VIP PRO. Guard against bypassed settings
      if (!isVip && settings.resolution == '1080p') {
        await settings.setResolution('720p');
      }

      // Both Android and iOS native plugins now automatically match the device's native screen
      // bounds and aspect ratio when width and height are 0.
      const int captureWidth = 0;
      const int captureHeight = 0;

      // Start hardware recording with platform-optimized dimensions and configured bitrate/fps
      final result = await _recorder.startRecordScreen(
        fileName: _currentFileName!,
        dirPathToSave: dir.path,
        width: captureWidth,
        height: captureHeight,
        videoBitrate: settings.bitrate,
        videoFrame: settings.fps,
        audioEnable: recordAudio,
        addTimeCode: false,
      );

      debugPrint('[ScreenRecordingService] Recording started: ${result.eventName}, file: ${result.file.path}');

      if (!result.success) {
        _isRecording = false;
        _isCountdownActive = false;
        notifyListeners();
        if (result.eventName == 'cancelled') {
          return 'Screen recording was cancelled';
        }
        return (result.message != null && result.message!.isNotEmpty)
            ? result.message!
            : 'Failed to start screen recording';
      }

      _isRecording = true;
      _isPaused = false;
      _recordingStartTime = DateTime.now();
      _recordingDuration = Duration.zero;

      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration += const Duration(seconds: 1);
        notifyListeners();
      });

      notifyListeners();
      onRecordingStarted?.call();
      return null;
    } catch (e) {
      debugPrint('[ScreenRecordingService] Start recording error: $e');
      _isRecording = false;
      _isCountdownActive = false;
      notifyListeners();
      return e.toString();
    }
  }

  /// Pause current recording
  Future<void> pauseRecording() async {
    if (!_isRecording || _isPaused) return;
    try {
      await _recorder.pauseRecord();
      _isPaused = true;
      _durationTimer?.cancel();
      notifyListeners();
    } catch (e) {
      debugPrint('[ScreenRecordingService] Pause error: $e');
    }
  }

  /// Resume current recording
  Future<void> resumeRecording() async {
    if (!_isRecording || !_isPaused) return;
    try {
      await _recorder.resumeRecord();
      _isPaused = false;
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration += const Duration(seconds: 1);
        notifyListeners();
      });
      notifyListeners();
    } catch (e) {
      debugPrint('[ScreenRecordingService] Resume error: $e');
    }
  }

  /// Stop current recording and save to local studio & gallery
  Future<RecordingItem?> stopRecording({
    required RecordingSettings settings,
    required bool isVip,
  }) async {
    if (!_isRecording) return null;

    _durationTimer?.cancel();
    _durationTimer = null;

    // Safety: Android MediaRecorder needs at least ~1.8 seconds of frames
    // before stopRecord() can finalize cleanly without "stop failed" or missing moov atom.
    if (_recordingStartTime != null) {
      final elapsedMs = DateTime.now().difference(_recordingStartTime!).inMilliseconds;
      if (elapsedMs < 1800) {
        await Future.delayed(Duration(milliseconds: 1800 - elapsedMs));
      }
    }

    _isRecording = false;
    _isPaused = false;
    notifyListeners();

    try {
      final stopResult = await _recorder.stopRecord().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('[ScreenRecordingService] stopRecord timed out - forcing completion');
          return RecordOutput(
            success: true,
            file: File(''),
            isProgress: false,
            eventName: 'timeout',
            message: 'Timeout fallback',
            videoHash: '',
            startDate: 0,
            endDate: 0,
          );
        },
      );

      // Brief pause to allow Android MediaRecorder / MediaMuxer to write MP4 trailer & close handle
      await Future.delayed(const Duration(milliseconds: 600));

      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();

      String resolvedPath = stopResult.file.path;
      if (resolvedPath.isEmpty || !File(resolvedPath).existsSync()) {
        final fallback = p.join(dir.path, "${_currentFileName ?? 'REC'}.mp4");
        if (File(fallback).existsSync()) {
          resolvedPath = fallback;
        } else {
          final appDocDir = await getApplicationDocumentsDirectory();
          final appDocFallback = p.join(appDocDir.path, "${_currentFileName ?? 'REC'}.mp4");
          if (File(appDocFallback).existsSync()) {
            resolvedPath = appDocFallback;
          }
        }
      }

      final videoFile = File(resolvedPath);
      int fileSize = 0;
      
      // Poll up to 6 times (300ms intervals) to ensure file has flushed non-zero bytes to disk
      for (int i = 0; i < 6; i++) {
        if (await videoFile.exists()) {
          fileSize = await videoFile.length();
          if (fileSize > 1024) break;
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (fileSize > 1024) {
        // Auto-save to phone gallery album
        try {
          final hasAccess = await Gal.hasAccess();
          if (!hasAccess) await Gal.requestAccess();
          await Gal.putVideo(resolvedPath, album: 'ScreenRecorder');
          debugPrint('[ScreenRecordingService] Video saved to gallery: $resolvedPath');
        } catch (galErr) {
          debugPrint('[ScreenRecordingService] Gal save note: $galErr');
        }
      } else {
        debugPrint('[ScreenRecordingService] Warning: Video file is empty or missing ($fileSize bytes): $resolvedPath');
      }

      final item = RecordingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _currentFileName ?? 'Screen_Recording_${DateTime.now().millisecondsSinceEpoch}',
        path: resolvedPath,
        duration: _recordingDuration,
        fileSizeBytes: fileSize,
        createdAt: DateTime.now(),
        resolution: (!isVip && settings.resolution == '1080p') ? '720p' : settings.resolution,
        fps: settings.fps,
        hasAudio: settings.audioSource != 'mute',
        isWatermarked: !isVip && RemoteAdConfig.instance.watermarkEnabledForFree,
      );

      _recordings.insert(0, item);
      await _saveRecordingsList();
      notifyListeners();

      // Fire completion interstitial ad
      AdService.instance.showInterstitialAd();

      return item;
    } catch (e) {
      debugPrint('[ScreenRecordingService] Stop recording error: $e');
      _isRecording = false;
      _isPaused = false;
      notifyListeners();
      return null;
    }
  }

  /// Delete a recording
  Future<void> deleteRecording(String id) async {
    final index = _recordings.indexWhere((e) => e.id == id);
    if (index != -1) {
      final item = _recordings[index];
      final file = File(item.path);
      if (await file.exists()) {
        await file.delete();
      }
      _recordings.removeAt(index);
      await _saveRecordingsList();
      notifyListeners();
    }
  }

  /// Rename a recording
  Future<void> renameRecording(String id, String newTitle) async {
    final index = _recordings.indexWhere((e) => e.id == id);
    if (index != -1) {
      final old = _recordings[index];
      _recordings[index] = RecordingItem(
        id: old.id,
        title: newTitle,
        path: old.path,
        duration: old.duration,
        fileSizeBytes: old.fileSizeBytes,
        createdAt: old.createdAt,
        resolution: old.resolution,
        fps: old.fps,
        hasAudio: old.hasAudio,
        isWatermarked: old.isWatermarked,
      );
      await _saveRecordingsList();
      notifyListeners();
    }
  }
}
