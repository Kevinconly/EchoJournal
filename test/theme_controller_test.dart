import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_journal/core/theme/theme_controller.dart';

void main() {
  group('ThemeController Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeController initializes to system default when no preference is saved', () async {
      await ThemeController.init();
      expect(ThemeController.currentMode, equals(ThemeMode.system));
    });

    test('ThemeController persists and updates ThemeMode.dark', () async {
      await ThemeController.setThemeMode(ThemeMode.dark);
      expect(ThemeController.currentMode, equals(ThemeMode.dark));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('dark'));
      expect(prefs.getBool('dark_mode'), isTrue);

      // Re-initialize to verify cold start loading
      await ThemeController.init();
      expect(ThemeController.currentMode, equals(ThemeMode.dark));
    });

    test('ThemeController persists and updates ThemeMode.light', () async {
      await ThemeController.setThemeMode(ThemeMode.light);
      expect(ThemeController.currentMode, equals(ThemeMode.light));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('light'));
      expect(prefs.getBool('dark_mode'), isFalse);
    });

    test('ThemeController supports legacy dark_mode boolean migration', () async {
      SharedPreferences.setMockInitialValues({
        'dark_mode': true,
      });

      await ThemeController.init();
      expect(ThemeController.currentMode, equals(ThemeMode.dark));
    });
  });
}
