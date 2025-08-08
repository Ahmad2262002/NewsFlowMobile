import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final box = GetStorage();

  final selectedTheme = 'blue'.obs;
  final isDarkMode = false.obs;

  // Define your theme colors
  final Map<String, MaterialColor> themeColors = {
    'blue': Colors.blue,
    'green': Colors.green,
    'red': Colors.red,
  };

  // Getter for available theme names (used in the UI)
  List<String> get themeNames => themeColors.keys.toList();

  @override
  void onInit() {
    super.onInit();
    _loadThemePreferences();
  }

  void _loadThemePreferences() {
    selectedTheme.value = box.read('theme') ?? 'blue';
    isDarkMode.value = box.read('darkMode') ?? false;
    _applyTheme();
  }

  void changeTheme(String themeName) {
    selectedTheme.value = themeName;
    box.write('theme', themeName);
    _applyTheme();
    update(); // Explicitly notify listeners

  }

  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
    box.write('darkMode', isDarkMode.value);
    _applyTheme();
    update(); // Explicitly notify listeners
  }

  void _applyTheme() {
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    Get.changeTheme(_getThemeData());
  }

  ThemeData _getThemeData() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: themeColors[selectedTheme.value]!,
        brightness: isDarkMode.value ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
    );
  }
}