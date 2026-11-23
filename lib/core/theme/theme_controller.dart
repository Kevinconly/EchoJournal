import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight reactive theme controller for EchoJournal.
/// Synchronizes ThemeMode state between SharedPreferences and MaterialApp.
class ThemeController {
  static const String _themeKey = 'app_theme_mode';
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Initialize theme mode from persistent storage.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeKey);
      if (savedMode == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
      } else if (savedMode == 'light') {
        themeModeNotifier.value = ThemeMode.light;
      } else {
        // Also check legacy boolean key 'dark_mode' if present
        final legacyDark = prefs.getBool('dark_mode');
        if (legacyDark != null) {
          themeModeNotifier.value = legacyDark ? ThemeMode.dark : ThemeMode.light;
        } else {
          themeModeNotifier.value = ThemeMode.system;
        }
      }
    } catch (_) {
      themeModeNotifier.value = ThemeMode.system;
    }
  }

  /// Get current ThemeMode value
  static ThemeMode get currentMode => themeModeNotifier.value;

  /// Whether dark mode is currently active (explicitly or via system).
  static bool isDarkMode(BuildContext context) {
    if (themeModeNotifier.value == ThemeMode.dark) return true;
    if (themeModeNotifier.value == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  /// Update and persist theme mode.
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (mode) {
        case ThemeMode.dark:
          await prefs.setString(_themeKey, 'dark');
          await prefs.setBool('dark_mode', true);
          break;
        case ThemeMode.light:
          await prefs.setString(_themeKey, 'light');
          await prefs.setBool('dark_mode', false);
          break;
        case ThemeMode.system:
          await prefs.setString(_themeKey, 'system');
          await prefs.remove('dark_mode');
          break;
      }
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}
