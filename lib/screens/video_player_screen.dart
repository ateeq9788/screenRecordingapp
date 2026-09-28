import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../models/recording_item.dart';
import '../theme/app_config.dart';

class VideoPlayerScreen extends StatefulWidget {
  final RecordingItem recording;

  const VideoPlayerScreen({super.key, required this.recording});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  int _fileSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final file = File(widget.recording.path);
    if (!file.existsSync()) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "The video file does not exist on your device storage.\n\nPath: ${widget.recording.path}";
        });
      }
      return;
    }

    try {
      _fileSizeBytes = await file.length();
      // If the file is empty or too small to be a valid MP4 (< 1024 bytes)
      if (_fileSizeBytes < 1024) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "The recorded file is empty (0 bytes).\n\n"
                "This usually occurs if the Android screen recording permission dialog was dismissed or if the recording duration was less than 1 second.\n\n"
                "Please start a new recording and tap 'Start Now' on the Android screen capture prompt.";
          });
        }
        return;
      }

      final controller = VideoPlayerController.file(file);
      _videoPlayerController = controller;

      // Initialize with timeout to prevent infinite hanging
      await controller.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception("Video player initialization timed out. The file may still be finalizing.");
        },
      );

      if (!controller.value.isInitialized || controller.value.duration <= Duration.zero) {
        throw Exception("The recording contains no playable video frames or duration is 0.");
      }

      final aspect = controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 9 / 16;

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        aspectRatio: aspect,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppConfig.defaultPrimary,
          handleColor: AppConfig.accentCyan,
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white10,
        ),
        errorBuilder: (context, errorMsg) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_rounded, size: 54, color: AppConfig.accentAmber),
                  const SizedBox(height: 16),
                  Text(
                    errorMsg,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.defaultPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _openInSystemGallery,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Open in Device Gallery'),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Explicitly trigger play to prevent freeze on first frame
      await controller.play();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[VideoPlayerScreen] Error: $e');
      if (mounted) {
        String friendlyMessage = "Unable to preview video in-app: $e\n\nYou can still play or open this video directly in your device's Gallery.";
        if (e.toString().contains("-12848")) {
          friendlyMessage = "This recording contains no video frames (0 frames captured).\n\n"
              "⚠️ Note: Apple's ReplayKit screen capture requires real hardware GPU access and is NOT supported by Apple on the iOS Simulator.\n\n"
              "To record and play back screen videos on iOS, please connect a physical iPhone, or test on your Android device!";
        }
        setState(() {
          _isLoading = false;
          _errorMessage = friendlyMessage;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _openInSystemGallery() async {
    try {
      await Gal.open();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Gallery: $e')),
        );
      }
    }
  }

  Future<void> _saveToGallery() async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();
      await Gal.putVideo(widget.recording.path, album: 'ScreenRecorder');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppConfig.success,
            behavior: SnackBarBehavior.floating,
            content: Text('Saved to Gallery (Movies / ScreenRecorder)!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppConfig.error,
            behavior: SnackBarBehavior.floating,
            content: Text('Could not save to gallery: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.recording.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_rounded),
            tooltip: 'Open Device Gallery',
            onPressed: _openInSystemGallery,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Save to Gallery',
            onPressed: _saveToGallery,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Video',
            onPressed: () {
              Share.shareXFiles([XFile(widget.recording.path)], text: widget.recording.title);
            },
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(color: AppConfig.defaultPrimary),
                  SizedBox(height: 16),
                  Text(
                    'Loading recording...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              )
            : _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppConfig.accentAmber,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConfig.defaultPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _initializePlayer,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _openInSystemGallery,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Open Gallery'),
                            ),
                            if (File(widget.recording.path).existsSync() && _fileSizeBytes > 0)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Share.shareXFiles([XFile(widget.recording.path)], text: widget.recording.title);
                                },
                                icon: const Icon(Icons.share_rounded),
                                label: const Text('Share'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  )
                : _chewieController != null &&
                        _chewieController!.videoPlayerController.value.isInitialized
                    ? Chewie(controller: _chewieController!)
                    : const Text(
                        'Unable to load video player',
                        style: TextStyle(color: Colors.white70),
                      ),
      ),
    );
  }
}
