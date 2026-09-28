import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/screen_recording_service.dart';
import '../theme/app_config.dart';
import '../widgets/ad_banner_widget.dart';
import 'video_player_screen.dart';

class RecordingsScreen extends StatelessWidget {
  const RecordingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordingService = context.watch<ScreenRecordingService>();
    final appConfig = context.watch<AppConfig>();
    final isDark = appConfig.isDarkMode;
    final recordings = recordingService.recordings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio & Recordings', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: recordings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppConfig.darkSurfaceVariant : AppConfig.lightSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.video_library_outlined,
                            size: 48,
                            color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'No recordings yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppConfig.darkTextPrimary : AppConfig.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your screen and gameplay captures will appear here.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: recordings.length,
                    itemBuilder: (context, index) {
                      final item = recordings[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppConfig.darkSurface : AppConfig.lightSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? AppConfig.darkBorder : AppConfig.lightBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoPlayerScreen(recording: item),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    gradient: appConfig.primaryGradient,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isDark ? AppConfig.darkTextPrimary : AppConfig.lightTextPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: appConfig.primary.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              '${item.resolution} • ${item.fps}FPS',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                color: appConfig.primary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            item.formattedDuration,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                                            ),
                                          ),
                                          const Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                          Text(
                                            item.formattedSize,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download_rounded, size: 19),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  color: AppConfig.accentCyan,
                                  tooltip: 'Save to Gallery',
                                  onPressed: () async {
                                    try {
                                      final hasAccess = await Gal.hasAccess();
                                      if (!hasAccess) await Gal.requestAccess();
                                      await Gal.putVideo(item.path, album: 'ScreenRecorder');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            backgroundColor: AppConfig.success,
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(seconds: 3),
                                            content: Text('Saved to Gallery!'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppConfig.error,
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Could not save: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_rounded, size: 17),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                  color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                                  onPressed: () {
                                    Share.shareXFiles([XFile(item.path)], text: item.title);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                  color: AppConfig.error,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Recording?'),
                                        content: const Text('This video file will be permanently removed from device storage.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              recordingService.deleteRecording(item.id);
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: AppConfig.error)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }
}
