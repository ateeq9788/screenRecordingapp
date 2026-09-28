import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recording_settings.dart';
import '../services/remote_ad_config.dart';
import '../services/screen_recording_service.dart';
import '../theme/app_config.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/pro_upgrade_sheet.dart';
import '../widgets/theme_picker_sheet.dart';
import 'recordings_screen.dart';
import 'settings_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final recordingService = context.watch<ScreenRecordingService>();

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _DashboardTab(onNavigateToStudio: () => setState(() => _currentIndex = 1)),
              const RecordingsScreen(),
              const SettingsScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.radio_button_checked_rounded),
                label: 'Record',
              ),
              NavigationDestination(
                icon: Icon(Icons.video_library_rounded),
                label: 'Studio',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
        if (recordingService.isCountdownActive)
          CountdownOverlay(secondsRemaining: recordingService.countdownSeconds),
      ],
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final VoidCallback onNavigateToStudio;

  const _DashboardTab({required this.onNavigateToStudio});

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>();
    final settings = context.watch<RecordingSettings>();
    final recordingService = context.watch<ScreenRecordingService>();
    final remoteConfig = context.watch<RemoteAdConfig>();
    final isDark = appConfig.isDarkMode;

    if (!appConfig.isVipUser && settings.resolution == '1080p') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        settings.sanitizeForVip(appConfig.isVipUser);
      });
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: appConfig.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fiber_smart_record_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Screen Recorder',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17.5),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              gradient: appConfig.isVipUser
                  ? appConfig.primaryGradient
                  : LinearGradient(
                      colors: [AppConfig.accentAmber, AppConfig.accentAmber.withOpacity(0.8)],
                    ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => ProUpgradeSheet.show(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      appConfig.isVipUser ? 'VIP PRO' : 'GET PRO',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Customize Theme & Accents',
            onPressed: () => ThemePickerSheet.show(context),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: 'Toggle Theme Mode',
            onPressed: () => appConfig.toggleTheme(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // Active Config Quality Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppConfig.darkSurface : AppConfig.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppConfig.darkBorder : AppConfig.lightBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQualityInfo(
                          Icons.hd_rounded,
                          'Resolution',
                          settings.resolution,
                          isPro: settings.resolution == '1080p',
                        ),
                        _buildDivider(isDark),
                        _buildQualityInfo(Icons.speed_rounded, 'FPS', '${settings.fps} FPS'),
                        _buildDivider(isDark),
                        _buildQualityInfo(
                          Icons.mic_rounded,
                          'Audio',
                          settings.audioSource == 'mic'
                              ? 'Mic'
                              : (settings.audioSource == 'internal' ? 'Internal' : 'Mute'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 38),

                  // Big Center Glowing Record Trigger / Timer
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        if (recordingService.isRecording) {
                          final item = await recordingService.stopRecording(
                            settings: settings,
                            isVip: appConfig.isVipUser,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            if (item != null && item.fileSizeBytes > 1024) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppConfig.success,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Recording saved: ${item.title}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  action: SnackBarAction(
                                    label: 'PLAY',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => VideoPlayerScreen(recording: item),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            } else if (item != null && item.fileSizeBytes <= 1024) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppConfig.accentAmber,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  content: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Recording stopped too quickly (0 bytes). Please record for at least 3 seconds.',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppConfig.accentAmber,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 3),
                                  content: Text('Recording ended.'),
                                ),
                              );
                            }
                          }
                        } else {
                          final err = await recordingService.startRecording(
                            settings: settings,
                            isVip: appConfig.isVipUser,
                          );
                          if (err != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppConfig.error,
                                behavior: SnackBarBehavior.floating,
                                content: Text(err),
                              ),
                            );
                          }
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: recordingService.isRecording
                              ? AppConfig.recordGradient
                              : appConfig.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: (recordingService.isRecording
                                      ? AppConfig.recordRed
                                      : appConfig.primary)
                                  .withOpacity(0.5),
                              blurRadius: recordingService.isRecording ? 36 : 24,
                              spreadRadius: recordingService.isRecording ? 8 : 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                recordingService.isRecording
                                    ? Icons.stop_rounded
                                    : Icons.videocam_rounded,
                                size: 56,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                recordingService.isRecording
                                    ? recordingService.formattedDuration
                                    : 'START RECORD',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // If recording, show pause/resume control
                  if (recordingService.isRecording) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppConfig.darkSurface : AppConfig.lightSurface,
                            foregroundColor: isDark ? Colors.white : Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          icon: Icon(
                            recordingService.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            color: AppConfig.accentCyan,
                          ),
                          label: Text(
                            recordingService.isPaused ? 'Resume Capture' : 'Pause Capture',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            if (recordingService.isPaused) {
                              recordingService.resumeRecording();
                            } else {
                              recordingService.pauseRecording();
                            }
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 38),

                  // Quick Tools Row
                  Row(
                    children: [
                      _buildQuickTool(
                        icon: Icons.high_quality_rounded,
                        label: 'Quality',
                        value: settings.resolution,
                        isDark: isDark,
                        primaryColor: appConfig.primary,
                        proBadge: settings.resolution == '1080p',
                        onTap: () => _showQualitySelector(context, settings, appConfig, isDark),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickTool(
                        icon: Icons.timer_outlined,
                        label: 'Timer',
                        value: '${settings.countdownSeconds}s',
                        isDark: isDark,
                        primaryColor: appConfig.primary,
                        onTap: () {
                          final next = settings.countdownSeconds == 0 ? 3 : (settings.countdownSeconds == 3 ? 5 : 0);
                          settings.setCountdown(next);
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildQuickTool(
                        icon: Icons.vibration_rounded,
                        label: 'Shake Stop',
                        value: settings.shakeToStop ? 'ON' : 'OFF',
                        isDark: isDark,
                        primaryColor: appConfig.primary,
                        onTap: () {
                          settings.setShakeToStop(!settings.shakeToStop);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Studio Library Stats Card
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onNavigateToStudio,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppConfig.darkSurface : AppConfig.lightSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? AppConfig.darkBorder : AppConfig.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: appConfig.primary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.video_library_rounded, color: appConfig.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recording Studio Library',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${recordingService.recordings.length} video${recordingService.recordings.length == 1 ? "" : "s"} saved • Tap to preview & export',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }

  Widget _buildQualityInfo(IconData icon, String label, String value, {bool isPro = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: isPro ? AppConfig.accentAmber : AppConfig.accentCyan),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            if (isPro) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppConfig.accentAmber, Colors.orangeAccent]),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('PRO', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 30,
      color: isDark ? AppConfig.darkBorder : AppConfig.lightBorder,
    );
  }

  Widget _buildQuickTool({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    required Color primaryColor,
    bool proBadge = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppConfig.darkSurface : AppConfig.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppConfig.darkBorder : AppConfig.lightBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: primaryColor, size: 24),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  if (proBadge) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppConfig.accentAmber, Colors.orangeAccent]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('PRO', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQualitySelector(BuildContext context, RecordingSettings settings, AppConfig appConfig, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppConfig.darkSurface : AppConfig.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? AppConfig.darkBorder : AppConfig.lightBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.high_quality_rounded, color: appConfig.primary, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Select Video Resolution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 1080p PRO option
              _buildQualityTile(
                title: '1080p Full HD',
                subtitle: '1920 × 1080 • Crystal-Clear 12 Mbps Capture',
                isSelected: settings.resolution == '1080p',
                isPro: true,
                isUnlocked: appConfig.isVipUser,
                isDark: isDark,
                primaryColor: appConfig.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  if (!appConfig.isVipUser) {
                    ProUpgradeSheet.show(context);
                  } else {
                    settings.setResolution('1080p');
                  }
                },
              ),
              const SizedBox(height: 10),
              // 720p HD option
              _buildQualityTile(
                title: '720p HD',
                subtitle: '1280 × 720 • Smooth & High Quality 5 Mbps (Standard)',
                isSelected: settings.resolution == '720p',
                isPro: false,
                isUnlocked: true,
                isDark: isDark,
                primaryColor: appConfig.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  settings.setResolution('720p');
                },
              ),
              const SizedBox(height: 10),
              // 480p SD option
              _buildQualityTile(
                title: '480p SD',
                subtitle: '854 × 480 • Fast & Lightweight 2.5 Mbps',
                isSelected: settings.resolution == '480p',
                isPro: false,
                isUnlocked: true,
                isDark: isDark,
                primaryColor: appConfig.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  settings.setResolution('480p');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualityTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isPro,
    required bool isUnlocked,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.12)
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? AppConfig.darkBorder : AppConfig.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? primaryColor : null,
                        ),
                      ),
                      if (isPro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppConfig.accentAmber, Colors.orangeAccent],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'VIP PRO',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isPro && !isUnlocked)
              const Icon(Icons.lock_rounded, color: AppConfig.accentAmber, size: 20)
            else if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryColor, size: 22)
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: isDark ? Colors.white24 : Colors.black26,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
