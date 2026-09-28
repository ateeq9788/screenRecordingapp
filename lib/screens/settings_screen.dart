import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recording_settings.dart';
import '../services/purchase_service.dart';
import '../services/remote_ad_config.dart';
import '../theme/app_config.dart';
import '../widgets/pro_upgrade_sheet.dart';
import '../widgets/theme_picker_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<RecordingSettings>();
    final appConfig = context.watch<AppConfig>();
    final remoteConfig = context.watch<RemoteAdConfig>();
    final isDark = appConfig.isDarkMode;

    if (!appConfig.isVipUser && settings.resolution == '1080p') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        settings.sanitizeForVip(appConfig.isVipUser);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio Settings', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live Cloud Announcement from Firebase Remote Config
          if (remoteConfig.announcementEnabled) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: appConfig.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: appConfig.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.campaign_rounded, color: appConfig.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          remoteConfig.announcementTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: isDark ? AppConfig.darkTextPrimary : AppConfig.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remoteConfig.announcementMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // VIP Banner Card
          if (!appConfig.isVipUser) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: appConfig.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: appConfig.primary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 38, color: Colors.white),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Screen Recorder PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'No watermark, 1080p 60FPS & internal game audio.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: appConfig.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => ProUpgradeSheet.show(context),
                    child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          _buildSectionHeader('VIDEO CONFIGURATION', isDark),
          _buildCard(
            isDark,
            children: [
              _buildDropdownTile(
                title: 'Resolution',
                subtitle: settings.resolution,
                value: settings.resolution,
                items: [
                  const DropdownMenuItem(value: '480p', child: Text('480p SD (Small Size)')),
                  const DropdownMenuItem(value: '720p', child: Text('720p HD (Balanced)')),
                  DropdownMenuItem(
                    value: '1080p',
                    child: Row(
                      children: [
                        const Text('1080p Full HD '),
                        if (!appConfig.isVipUser) _buildProTag(appConfig),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == '1080p' && !appConfig.isVipUser) {
                    ProUpgradeSheet.show(context);
                  } else if (val != null) {
                    settings.setResolution(val);
                  }
                },
              ),
              const Divider(height: 1),
              _buildDropdownTile(
                title: 'Frame Rate',
                subtitle: '${settings.fps} FPS',
                value: settings.fps,
                items: [
                  const DropdownMenuItem(value: 30, child: Text('30 FPS (Standard)')),
                  DropdownMenuItem(
                    value: 60,
                    child: Row(
                      children: [
                        const Text('60 FPS (Silky Smooth) '),
                        if (!appConfig.isVipUser) _buildProTag(appConfig),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == 60 && !appConfig.isVipUser) {
                    ProUpgradeSheet.show(context);
                  } else if (val != null) {
                    settings.setFps(val);
                  }
                },
              ),
              const Divider(height: 1),
              _buildDropdownTile(
                title: 'Audio Source',
                subtitle: settings.audioSource == 'mic'
                    ? 'Microphone'
                    : (settings.audioSource == 'internal' ? 'Internal Game Audio' : 'Mute'),
                value: settings.audioSource,
                items: [
                  const DropdownMenuItem(value: 'mic', child: Text('Microphone (Voice)')),
                  DropdownMenuItem(
                    value: 'internal',
                    child: Row(
                      children: [
                        const Text('Internal Audio '),
                        if (!appConfig.isVipUser) _buildProTag(),
                      ],
                    ),
                  ),
                  const DropdownMenuItem(value: 'mute', child: Text('Mute (Silent)')),
                ],
                onChanged: (val) {
                  if (val == 'internal' && !appConfig.isVipUser) {
                    ProUpgradeSheet.show(context);
                  } else if (val != null) {
                    settings.setAudioSource(val);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('CONTROL SETTINGS', isDark),
          _buildCard(
            isDark,
            children: [
              _buildDropdownTile(
                title: 'Countdown Timer',
                subtitle: settings.countdownSeconds == 0 ? 'None' : '${settings.countdownSeconds}s',
                value: settings.countdownSeconds,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('No Countdown')),
                  DropdownMenuItem(value: 3, child: Text('3 Seconds')),
                  DropdownMenuItem(value: 5, child: Text('5 Seconds')),
                ],
                onChanged: (val) {
                  if (val != null) settings.setCountdown(val);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Shake Phone to Stop', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                subtitle: const Text('Stop recording automatically by shaking device', style: TextStyle(fontSize: 12)),
                value: settings.shakeToStop,
                onChanged: (val) => settings.setShakeToStop(val),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Floating Controls Ball', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                subtitle: const Text('Show floating action bubble over games and apps', style: TextStyle(fontSize: 12)),
                value: settings.floatingControlsEnabled,
                onChanged: (val) => settings.setFloatingControls(val),
              ),
            ],
          ),

          if (remoteConfig.crossPromoEnabled) ...[
            const SizedBox(height: 20),
            _buildSectionHeader('FEATURED PARTNER APP', isDark),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppConfig.darkSurface : AppConfig.lightSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: appConfig.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: appConfig.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          remoteConfig.crossPromoTitle,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          remoteConfig.crossPromoDesc,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          _buildSectionHeader('APPEARANCE & THEME', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appConfig.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.palette_rounded, color: appConfig.primary, size: 22),
                ),
                title: const Text(
                  'Theme & Accent Palettes',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                subtitle: Text(
                  '${AppConfig.getAccentName(appConfig.accentPalette)} • ${appConfig.themeMode == ThemeMode.dark ? "OLED Dark" : (appConfig.themeMode == ThemeMode.light ? "Clean Light" : "System")}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: appConfig.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: appConfig.primary.withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Colors.grey),
                  ],
                ),
                onTap: () => ThemePickerSheet.show(context),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('OLED Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                subtitle: const Text('Pure black background optimized for battery life', style: TextStyle(fontSize: 12)),
                value: appConfig.isDarkMode,
                onChanged: (val) => appConfig.toggleTheme(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restore_rounded, size: 20),
                ),
                title: const Text('Restore Purchases', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                subtitle: const Text('Recover active PRO subscription on this device', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Colors.grey),
                onTap: () async {
                  final restored = await PurchaseService.instance.restorePurchases(appConfig);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: restored ? AppConfig.success : appConfig.primary,
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          restored ? '✅ Purchases restored successfully!' : 'No active PRO subscription found.',
                        ),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (remoteConfig.isFirebaseConnected ? AppConfig.success : Colors.grey).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    remoteConfig.isFirebaseConnected ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                    color: remoteConfig.isFirebaseConnected ? AppConfig.success : Colors.grey,
                    size: 20,
                  ),
                ),
                title: const Text('Firebase Remote Config', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                subtitle: Text(
                  remoteConfig.isFirebaseConnected
                      ? 'Connected: screen-recording-2b210 (${remoteConfig.activeKeysCount} keys live)'
                      : 'Offline default mode (Tap sync to test)',
                  style: TextStyle(
                    fontSize: 12,
                    color: remoteConfig.isFirebaseConnected ? AppConfig.success : Colors.grey,
                    fontWeight: remoteConfig.isFirebaseConnected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.sync_rounded, size: 20),
                  tooltip: 'Sync with Firebase',
                  onPressed: () async {
                    final success = await remoteConfig.forceFetch();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: success ? AppConfig.success : AppConfig.accentAmber,
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            success
                                ? '✅ Synced with Firebase! ${remoteConfig.activeKeysCount} parameters loaded.'
                                : 'Could not reach Firebase. Using offline fallback defaults.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppConfig.darkSurface : AppConfig.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppConfig.darkBorder : AppConfig.lightBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildProTag([AppConfig? appConfig]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        gradient: appConfig?.primaryGradient ?? AppConfig.defaultPrimaryGradient,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
      ),
    );
  }
}
