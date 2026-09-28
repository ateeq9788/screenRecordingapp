import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAccentPalette {
  violet,
  crimson,
  cyan,
  gold,
  emerald,
  sapphire,
}

class AppConfig extends ChangeNotifier {
  static const String _themePrefKey = "screen_recorder_theme_mode";
  static const String _accentPrefKey = "screen_recorder_accent_palette";
  static const String _vipPrefKey = "screen_recorder_vip_status";

  ThemeMode _themeMode = ThemeMode.dark;
  AppAccentPalette _accentPalette = AppAccentPalette.violet;
  bool _isVipUser = false;

  ThemeMode get themeMode => _themeMode;
  AppAccentPalette get accentPalette => _accentPalette;
  bool get isVipUser => _isVipUser;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AppConfig() {
    _loadPreferences();
  }

  // ==========================================
  // 🎨 DYNAMIC ACCENT COLORS & GRADIENTS
  // ==========================================
  Color get activePrimary {
    switch (_accentPalette) {
      case AppAccentPalette.crimson:
        return const Color(0xFFEF4444);
      case AppAccentPalette.cyan:
        return const Color(0xFF06B6D4);
      case AppAccentPalette.gold:
        return const Color(0xFFF59E0B);
      case AppAccentPalette.emerald:
        return const Color(0xFF10B981);
      case AppAccentPalette.sapphire:
        return const Color(0xFF3B82F6);
      case AppAccentPalette.violet:
      default:
        return const Color(0xFF7C3AED);
    }
  }

  Color get activePrimaryGradientStart {
    switch (_accentPalette) {
      case AppAccentPalette.crimson:
        return const Color(0xFFF87171);
      case AppAccentPalette.cyan:
        return const Color(0xFF22D3EE);
      case AppAccentPalette.gold:
        return const Color(0xFFFBBF24);
      case AppAccentPalette.emerald:
        return const Color(0xFF34D399);
      case AppAccentPalette.sapphire:
        return const Color(0xFF60A5FA);
      case AppAccentPalette.violet:
      default:
        return const Color(0xFF9333EA);
    }
  }

  Color get activePrimaryGradientEnd {
    switch (_accentPalette) {
      case AppAccentPalette.crimson:
        return const Color(0xFFDC2626);
      case AppAccentPalette.cyan:
        return const Color(0xFF0284C7);
      case AppAccentPalette.gold:
        return const Color(0xFFD97706);
      case AppAccentPalette.emerald:
        return const Color(0xFF059669);
      case AppAccentPalette.sapphire:
        return const Color(0xFF1D4ED8);
      case AppAccentPalette.violet:
      default:
        return const Color(0xFF6366F1);
    }
  }

  LinearGradient get activePrimaryGradient => LinearGradient(
        colors: [activePrimaryGradientStart, activePrimaryGradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Instance aliases for reactive theme consumption
  Color get primary => activePrimary;
  Color get primaryGradientStart => activePrimaryGradientStart;
  Color get primaryGradientEnd => activePrimaryGradientEnd;
  LinearGradient get primaryGradient => activePrimaryGradient;

  // Static Fallback Defaults (Violet)
  static const Color primaryViolet = Color(0xFF7C3AED);
  static const Color primaryVioletStart = Color(0xFF9333EA);
  static const Color primaryVioletEnd = Color(0xFF6366F1);
  static const Color defaultPrimary = primaryViolet;
  static const Color defaultPrimaryGradientStart = primaryVioletStart;
  static const Color defaultPrimaryGradientEnd = primaryVioletEnd;
  static const LinearGradient defaultPrimaryGradient = LinearGradient(
    colors: [primaryVioletStart, primaryVioletEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Constants
  static const Color recordRed = Color(0xFFEF4444);
  static const Color recordRedEnd = Color(0xFFB91C1C);
  static const LinearGradient recordGradient = LinearGradient(
    colors: [recordRed, recordRedEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Light Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // OLED Dark Palette
  static const Color darkBg = Color(0xFF0A0C14);
  static const Color darkSurface = Color(0xFF131722);
  static const Color darkSurfaceVariant = Color(0xFF1E2433);
  static const Color darkBorder = Color(0xFF262D3D);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Dynamic Theme Data Generators
  ThemeData get lightThemeData => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBg,
        primaryColor: activePrimary,
        colorScheme: ColorScheme.light(
          primary: activePrimary,
          secondary: activePrimaryGradientEnd,
          surface: lightSurface,
          surfaceContainerHighest: lightSurfaceVariant,
          outline: lightBorder,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: lightBg,
          foregroundColor: lightTextPrimary,
          elevation: 0,
        ),
      );

  ThemeData get darkThemeData => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        primaryColor: activePrimary,
        colorScheme: ColorScheme.dark(
          primary: activePrimary,
          secondary: activePrimaryGradientEnd,
          surface: darkSurface,
          surfaceContainerHighest: darkSurfaceVariant,
          outline: darkBorder,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBg,
          foregroundColor: darkTextPrimary,
          elevation: 0,
        ),
      );

  // Persistence
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedTheme = prefs.getString(_themePrefKey);
    if (savedTheme == "light") {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == "system") {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark;
    }

    final savedAccent = prefs.getString(_accentPrefKey);
    if (savedAccent != null) {
      _accentPalette = AppAccentPalette.values.firstWhere(
        (e) => e.name == savedAccent,
        orElse: () => AppAccentPalette.violet,
      );
    }

    _isVipUser = prefs.getBool(_vipPrefKey) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String modeString = "dark";
    if (mode == ThemeMode.light) modeString = "light";
    if (mode == ThemeMode.system) modeString = "system";
    await prefs.setString(_themePrefKey, modeString);
  }

  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setAccentPalette(AppAccentPalette palette) async {
    _accentPalette = palette;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentPrefKey, palette.name);
  }

  Future<void> setVipUser(bool isVip) async {
    _isVipUser = isVip;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vipPrefKey, isVip);
  }

  void toggleVip() {
    setVipUser(!_isVipUser);
  }

  static String getAccentName(AppAccentPalette palette) {
    switch (palette) {
      case AppAccentPalette.violet:
        return 'Cyber Violet';
      case AppAccentPalette.crimson:
        return 'Gamer Crimson';
      case AppAccentPalette.cyan:
        return 'Electric Cyan';
      case AppAccentPalette.gold:
        return 'Luxury Gold';
      case AppAccentPalette.emerald:
        return 'Neon Emerald';
      case AppAccentPalette.sapphire:
        return 'Space Sapphire';
    }
  }

  static Color getAccentPreviewColor(AppAccentPalette palette) {
    switch (palette) {
      case AppAccentPalette.violet:
        return const Color(0xFF7C3AED);
      case AppAccentPalette.crimson:
        return const Color(0xFFEF4444);
      case AppAccentPalette.cyan:
        return const Color(0xFF06B6D4);
      case AppAccentPalette.gold:
        return const Color(0xFFF59E0B);
      case AppAccentPalette.emerald:
        return const Color(0xFF10B981);
      case AppAccentPalette.sapphire:
        return const Color(0xFF3B82F6);
    }
  }
}
