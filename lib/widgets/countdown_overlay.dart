import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_config.dart';

class CountdownOverlay extends StatelessWidget {
  final int secondsRemaining;

  const CountdownOverlay({super.key, required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    if (secondsRemaining <= 0) return const SizedBox.shrink();
    final appConfig = Provider.of<AppConfig>(context);

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: appConfig.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: appConfig.primary.withOpacity(0.6),
                    blurRadius: 36,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$secondsRemaining',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Get Ready to Record...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
