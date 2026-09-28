import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/purchase_service.dart';
import '../theme/app_config.dart';

class ProUpgradeSheet extends StatelessWidget {
  const ProUpgradeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ProUpgradeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>();
    final isDark = appConfig.isDarkMode;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
        decoration: BoxDecoration(
          color: isDark ? AppConfig.darkSurface : AppConfig.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: isDark ? AppConfig.darkBorder : AppConfig.lightBorder,
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: appConfig.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: appConfig.primary.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (bounds) => appConfig.primaryGradient.createShader(bounds),
                child: const Text(
                  'Screen Recorder PRO',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Unlock crystal-clear 1080p 60FPS recording, clean watermark-free exports, and internal game audio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _buildPerk(Icons.branding_watermark_outlined, 'No Watermark (100% Clean Exports)', isDark),
              _buildPerk(Icons.videocam_rounded, '1080p Full HD @ 60 FPS Video Capture', isDark),
              _buildPerk(Icons.volume_up_rounded, 'High-Definition Internal Game Audio', isDark),
              _buildPerk(Icons.block_rounded, '100% Ad-Free Experience', isDark),
              const SizedBox(height: 20),
              Consumer<PurchaseService>(
                builder: (context, purchaseService, child) {
                  if (appConfig.isVipUser) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppConfig.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppConfig.success.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppConfig.success, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'PRO Subscription Active',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppConfig.success,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppConfig.darkTextSecondary : AppConfig.lightTextSecondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            appConfig.setVipUser(false);
                            Navigator.pop(context);
                          },
                          child: const Text('Disable PRO (Preview Ad Mode)', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: appConfig.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: appConfig.primary.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: purchaseService.isPurchasing
                                ? null
                                : () async {
                                    try {
                                      final success = await purchaseService.buyMonthlySubscription(appConfig);
                                      if (context.mounted) Navigator.pop(context);
                                      if (context.mounted && success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppConfig.success,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            content: const Text('🎉 Welcome to PRO! All features unlocked.'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppConfig.error,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            content: Text('Subscription failed: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: purchaseService.isPurchasing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.bolt_rounded, color: AppConfig.accentAmber, size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Subscribe for 1 Month (${purchaseService.monthlyPriceDisplay})',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Colors.white),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Renews monthly. Cancel anytime in Google Play Store settings.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppConfig.darkTextSecondary.withOpacity(0.7) : AppConfig.lightTextSecondary.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: purchaseService.isPurchasing
                            ? null
                            : () async {
                                try {
                                  final restored = await purchaseService.restorePurchases(appConfig);
                                  if (context.mounted) Navigator.pop(context);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: restored ? AppConfig.success : appConfig.primary,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        content: Text(
                                          restored
                                              ? '✅ PRO Subscription successfully restored!'
                                              : 'No active PRO subscription found to restore.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppConfig.error,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        content: Text('Restore error: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Text(
                          'Restore Purchases',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? appConfig.primaryGradientStart : appConfig.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerk(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppConfig.accentCyan),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppConfig.darkTextPrimary : AppConfig.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
