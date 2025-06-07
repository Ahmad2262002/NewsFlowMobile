import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newsflow/Routes/AppPage.dart';
// import 'package:uni_links/uni_links.dart';
import 'package:app_links/app_links.dart';

import 'package:newsflow/loading_screen.dart';
import 'package:newsflow/Views/ResetPasswordScreen.dart';

// Deep link handler function
void _handleDeepLink(Uri uri) {
  debugPrint('Handling deep link: $uri');
  if (uri.host == 'reset-password') {
    final token = uri.queryParameters['token'];
    final email = uri.queryParameters['email'];

    if (token != null && email != null) {
      Get.to(() => ResetPasswordScreen(
        token: token,
        email: Uri.decodeComponent(email),
      ));
    }
  }
}

// Initialize deep linking
// Replace your initDeepLinking with:
Future<void> initDeepLinking() async {
  final appLinks = AppLinks();

  // Handle initial link
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    _handleDeepLink(initialUri);
  }

  // Listen for links while app is running
  appLinks.uriLinkStream.listen(_handleDeepLink);
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize deep linking
    await initDeepLinking();

    // Custom error handling
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('ImpellerValidationBreak')) return;
      FlutterError.presentError(details);
    };

    runApp(const MyApp());
  }, (error, stackTrace) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stackTrace');
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
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const LuxuryLoadingScreen(),
      getPages: AppPage.pages,
      translations: AppTranslations(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      builder: (context, child) {
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