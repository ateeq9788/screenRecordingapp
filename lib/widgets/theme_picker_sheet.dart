import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_config.dart';

class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ThemePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>();
    final isDark = appConfig.isDarkMode;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
        decoration: BoxDecoration(
          color: isDark ? AppConfig.darkSurface : AppConfig.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark ? AppConfig.darkBorder : AppConfig.lightBorder,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: appConfig.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.palette_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appearance & Theme',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Personalize your recording studio',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mode Selector (Dark / Light / System)
              Text(
                'APPEARANCE MODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildModeOption(
                    context,
                    title: 'OLED Dark',
                    icon: Icons.dark_mode_rounded,
                    isSelected: appConfig.themeMode == ThemeMode.dark,
                    onTap: () => appConfig.setThemeMode(ThemeMode.dark),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildModeOption(
                    context,
                    title: 'Clean Light',
                    icon: Icons.light_mode_rounded,
                    isSelected: appConfig.themeMode == ThemeMode.light,
                    onTap: () => appConfig.setThemeMode(ThemeMode.light),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildModeOption(
                    context,
                    title: 'System',
                    icon: Icons.brightness_auto_rounded,
                    isSelected: appConfig.themeMode == ThemeMode.system,
                    onTap: () => appConfig.setThemeMode(ThemeMode.system),
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Accent Palette Selector
              Text(
                'ACCENT COLOR PALETTE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppAccentPalette.values.map((palette) {
                  final isSelected = appConfig.accentPalette == palette;
                  final color = AppConfig.getAccentPreviewColor(palette);
                  final name = AppConfig.getAccentName(palette);

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => appConfig.setAccentPalette(palette),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.18)
                            : (isDark ? AppConfig.darkSurfaceVariant : AppConfig.lightSurfaceVariant),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? color
                                  : (isDark ? AppConfig.darkTextPrimary : AppConfig.lightTextPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Live Theme Preview Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppConfig.darkSurfaceVariant : AppConfig.lightSurfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppConfig.darkBorder : AppConfig.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: appConfig.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Style: ${AppConfig.getAccentName(appConfig.accentPalette)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gradients and UI controls adapt automatically in real-time.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final appConfig = context.watch<AppConfig>();

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? appConfig.primary.withOpacity(0.18)
                : (isDark ? AppConfig.darkSurfaceVariant : AppConfig.lightSurfaceVariant),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? appConfig.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? appConfig.primary
                    : (isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? appConfig.primary
                      : (isDark ? AppConfig.darkTextPrimary : AppConfig.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
