import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newsflow/Routes/AppPage.dart'; // Import AppPage for routes
import 'package:newsflow/loading_screen.dart'; // Import your loading screen

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Custom error handling
  FlutterError.onError = (details) {
    // Suppress specific errors (e.g., ImpellerValidationBreak)
    if (details.exception.toString().contains('ImpellerValidationBreak')) return;
    // Print the error to the console
    FlutterError.presentError(details);
  };

  // Run the app with error handling
  runZonedGuarded(() {
    runApp(MyApp());
  }, (error, stackTrace) {
    // Handle any uncaught errors
    print('Uncaught error: $error');
    print('Stack trace: $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NewsFlow',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system, // Use system theme mode
      debugShowCheckedModeBanner: false, // Hide the debug banner
      home: const LuxuryLoadingScreen(), // Display the loading screen immediately
      getPages: AppPage.pages, // Use the defined routes from AppPage
      translations: AppTranslations(), // Add translations
      locale: Get.deviceLocale, // Use the device's locale
      fallbackLocale: const Locale('en', 'US'), // Fallback locale
      builder: (context, child) {
        // Custom scroll behavior to disable mouse tracking
        return ScrollConfiguration(
          behavior: ScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
            },
          ),
          child: child!,
        );
      },
    );
  }
}

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'welcome': 'Welcome',
      'no_articles': 'No articles found.',
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'preferences': 'Preferences',
      'logout': 'Logout',
      'add_article': 'Add new article feature is under development!',
      'categories_all': 'All',
      'categories_politics': 'Politics',
      'categories_technology': 'Technology',
      'categories_sports': 'Sports',
      'categories_entertainment': 'Entertainment',
    },
    'ar_AR': {
      'welcome': 'مرحبًا',
      'no_articles': 'لم يتم العثور على مقالات.',
      'settings': 'الإعدادات',
      'dark_mode': 'الوضع الليلي',
      'preferences': 'التفضيلات',
      'logout': 'تسجيل الخروج',
      'add_article': 'ميزة إضافة مقال جديد قيد التطوير!',
      'categories_all': 'الكل',
      'categories_politics': 'السياسة',
      'categories_technology': 'التكنولوجيا',
      'categories_sports': 'الرياضة',
      'categories_entertainment': 'الترفيه',
    },
  };
}