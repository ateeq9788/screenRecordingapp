import 'dart:io';

class RecordingItem {
  final String id;
  final String title;
  final String path;
  final Duration duration;
  final int fileSizeBytes;
  final DateTime createdAt;
  final String resolution;
  final int fps;
  final bool hasAudio;
  final bool isWatermarked;

  RecordingItem({
    required this.id,
    required this.title,
    required this.path,
    required this.duration,
    required this.fileSizeBytes,
    required this.createdAt,
    this.resolution = '1080p',
    this.fps = 60,
    this.hasAudio = true,
    this.isWatermarked = false,
  });

  bool get exists => File(path).existsSync();

  String get formattedDuration {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String get formattedSize {
    if (fileSizeBytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = fileSizeBytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'path': path,
        'durationMs': duration.inMilliseconds,
        'fileSizeBytes': fileSizeBytes,
        'createdAt': createdAt.toIso8601String(),
        'resolution': resolution,
        'fps': fps,
        'hasAudio': hasAudio,
        'isWatermarked': isWatermarked,
      };

  factory RecordingItem.fromJson(Map<String, dynamic> json) => RecordingItem(
        id: json['id'] as String,
        title: json['title'] as String,
        path: json['path'] as String,
        duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        resolution: json['resolution'] as String? ?? '1080p',
        fps: json['fps'] as int? ?? 60,
        hasAudio: json['hasAudio'] as bool? ?? true,
        isWatermarked: json['isWatermarked'] as bool? ?? false,
      );
}
