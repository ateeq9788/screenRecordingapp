import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/recording_settings.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';
import 'services/remote_ad_config.dart';
import 'services/screen_recording_service.dart';
import 'theme/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase Remote Config
  await RemoteAdConfig.instance.initialize();

  // 2. Initialize Google Mobile Ads
  await AdService.instance.initialize();

  final appConfig = AppConfig();

  // 3. Initialize RevenueCat Subscriptions
  await PurchaseService.instance.initialize(appConfig: appConfig);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appConfig),
        ChangeNotifierProvider(create: (_) => RecordingSettings()),
        ChangeNotifierProvider(create: (_) => ScreenRecordingService()),
        ChangeNotifierProvider.value(value: RemoteAdConfig.instance),
        ChangeNotifierProvider.value(value: AdService.instance),
        ChangeNotifierProvider.value(value: PurchaseService.instance),
      ],
      child: const ScreenRecorderApp(),
    ),
  );
}

class ScreenRecorderApp extends StatelessWidget {
  const ScreenRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>();

    return MaterialApp(
      title: 'Screen Recorder Master',
      debugShowCheckedModeBanner: false,
      theme: appConfig.lightThemeData,
      darkTheme: appConfig.darkThemeData,
      themeMode: appConfig.themeMode,
      home: const HomeScreen(),
    );
  }
}
