import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:newsflow/Routes/AppPage.dart';
import 'package:app_links/app_links.dart';
import 'package:newsflow/loading_screen.dart';
import 'package:newsflow/Views/ResetPasswordScreen.dart';
import 'package:newsflow/Services/weather_location_service.dart';
import 'package:newsflow/Controllers/ThemeController.dart';

import 'Routes/AppRoute.dart';

// Deep link handler function
// Deep link handler function
void _handleDeepLink(Uri uri) {
  debugPrint('Handling deep link: $uri');
  if (uri.host == 'reset-password') {
    final token = uri.queryParameters['token'];
    final email = uri.queryParameters['email'];

    if (token != null && email != null) {
      Get.toNamed(
        AppRoute.resetPassword,
        arguments: {
          'token': token,
          'email': Uri.decodeComponent(email),
        },
      );
    }
  }
}

// Initialize deep linking
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

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await GetStorage.init();

    // Initialize GetX services
    await Get.putAsync(() => WeatherLocationService().init());
    final ThemeController themeController = Get.put(ThemeController());

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
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GetMaterialApp(
          title: 'NewsFlow',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeController.themeColors[themeController.selectedTheme.value]!,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeController.themeColors[themeController.selectedTheme.value]!,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
          home: const LuxuryLoadingScreen(),
          getPages: AppPage.pages,
          translations: AppTranslations(),
          locale: Get.deviceLocale,
          fallbackLocale: const Locale('en', 'US'),
          supportedLocales: const [
            Locale('en', 'US'), // English
            Locale('ar', 'AR'), // Arabic
            Locale('fr', 'FR'), // French
            Locale('es', 'ES'), // Spanish
            Locale('it', 'IT'), // Italian
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final locale = Get.locale ?? const Locale('en', 'US');
            return Localizations(
              locale: locale,
              delegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              child: Directionality(
                textDirection: locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'NewsFlow': 'NewsFlow',
      'no_articles': 'No articles found',
      'all categories': 'All categories',
      'Select category': 'Select category',
      'share feedback': 'Share feedback',
      'How would you rate this article': 'How would you rate this article?',
      'share your thoughts': 'Share your thoughts',
      'cancel': 'Cancel',
      'submit': 'Submit',
      'error': 'Error',
      'feedback_cannot_be_empty': 'Feedback cannot be empty',
      'success': 'Success',
      'thanks for your feedback': 'Thanks for your feedback!',
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'Language': 'Language',
      'Theme': 'Theme',
      'Delete Account': 'Delete Account',
      'logout': 'Logout',
      'Posted by': 'Posted by',
      'Close': 'Close',
      'Post': 'Post',
      'Comments': 'Comments',
      'No comments yet': 'No comments yet',
      'Confirm Delete': 'Confirm Delete',
      'Are you sure you want to delete this comment?': 'Are you sure you want to delete this comment?',
      'failed_to_load_articles': 'Failed to load articles: {error}',
    },
    'ar_AR': {
      'NewsFlow': 'نيوزفلو',
      'no_articles': 'لا توجد مقالات',
      'all categories': 'جميع الفئات',
      'Select category': 'اختر الفئة',
      'share feedback': 'شارك رأيك',
      'How would you rate this article': 'كيف تقيم هذا المقال؟',
      'share your thoughts': 'شاركنا أفكارك',
      'cancel': 'إلغاء',
      'submit': 'إرسال',
      'error': 'خطأ',
      'feedback_cannot_be_empty': 'لا يمكن أن يكون التعليق فارغًا',
      'success': 'نجاح',
      'thanks for your feedback': 'شكرًا لك على ملاحظاتك!',
      'settings': 'الإعدادات',
      'dark_mode': 'الوضع الليلي',
      'Language': 'اللغة',
      'Theme': 'السمة',
      'Delete Account': 'حذف الحساب',
      'logout': 'تسجيل الخروج',
      'Posted by': 'نشر بواسطة',
      'Close': 'إغلاق',
      'Post': 'نشر',
      'Comments': 'التعليقات',
      'No comments yet': 'لا توجد تعليقات بعد',
      'Confirm Delete': 'تأكيد الحذف',
      'Are you sure you want to delete this comment?': 'هل أنت متأكد أنك تريد حذف هذا التعليق؟',
      'failed_to_load_articles': 'فشل تحميل المقالات: {error}',
    },
    'fr_FR': {
      'NewsFlow': 'NewsFlow',
      'no_articles': 'Aucun article trouvé',
      'all categories': 'Toutes les catégories',
      'Select category': 'Sélectionner une catégorie',
      'share feedback': 'Partager un commentaire',
      'How would you rate this article': 'Comment évaluez-vous cet article ?',
      'share your thoughts': 'Partagez vos pensées',
      'cancel': 'Annuler',
      'submit': 'Soumettre',
      'error': 'Erreur',
      'feedback_cannot_be_empty': 'Le commentaire ne peut pas être vide',
      'success': 'Succès',
      'thanks for your feedback': 'Merci pour votre commentaire !',
      'settings': 'Paramètres',
      'dark_mode': 'Mode sombre',
      'Language': 'Langue',
      'Theme': 'Thème',
      'Delete Account': 'Supprimer le compte',
      'logout': 'Déconnexion',
      'Posted by': 'Posté par',
      'Close': 'Fermer',
      'Post': 'Publier',
      'Comments': 'Commentaires',
      'No comments yet': 'Pas encore de commentaires',
      'Confirm Delete': 'Confirmer la suppression',
      'Are you sure you want to delete this comment?': 'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
      'failed_to_load_articles': 'Échec du chargement des articles: {error}',
    },
    'es_ES': {
      'NewsFlow': 'NewsFlow',
      'no_articles': 'No se encontraron artículos',
      'all categories': 'Todas las categorías',
      'Select category': 'Seleccionar categoría',
      'share feedback': 'Compartir comentarios',
      'How would you rate this article': '¿Cómo calificarías este artículo?',
      'share your thoughts': 'Comparte tus pensamientos',
      'cancel': 'Cancelar',
      'submit': 'Enviar',
      'error': 'Error',
      'feedback_cannot_be_empty': 'El comentario no puede estar vacío',
      'success': 'Éxito',
      'thanks for your feedback': '¡Gracias por tus comentarios!',
      'settings': 'Configuración',
      'dark_mode': 'Modo oscuro',
      'Language': 'Idioma',
      'Theme': 'Tema',
      'Delete Account': 'Eliminar cuenta',
      'logout': 'Cerrar sesión',
      'Posted by': 'Publicado por',
      'Close': 'Cerrar',
      'Post': 'Publicar',
      'Comments': 'Comentarios',
      'No comments yet': 'Aún no hay comentarios',
      'Confirm Delete': 'Confirmar eliminación',
      'Are you sure you want to delete this comment?': '¿Estás seguro de que quieres eliminar este comentario?',
      'failed_to_load_articles': 'Error al cargar artículos: {error}',
    },
    'it_IT': {
      'NewsFlow': 'NewsFlow',
      'no_articles': 'Nessun articolo trovato',
      'all categories': 'Tutte le categorie',
      'Select category': 'Seleziona categoria',
      'share feedback': 'Condividi feedback',
      'How would you rate this article': 'Come valuteresti questo articolo?',
      'share your thoughts': 'Condividi i tuoi pensieri',
      'cancel': 'Annulla',
      'submit': 'Invia',
      'error': 'Errore',
      'feedback_cannot_be_empty': 'Il feedback non può essere vuoto',
      'success': 'Successo',
      'thanks for your feedback': 'Grazie per il tuo feedback!',
      'settings': 'Impostazioni',
      'dark_mode': 'Modalità scura',
      'Language': 'Lingua',
      'Theme': 'Tema',
      'Delete Account': 'Elimina account',
      'logout': 'Esci',
      'Posted by': 'Pubblicato da',
      'Close': 'Chiudi',
      'Post': 'Pubblica',
      'Comments': 'Commenti',
      'No comments yet': 'Ancora nessun commento',
      'Confirm Delete': 'Conferma eliminazione',
      'Are you sure you want to delete this comment?': 'Sei sicuro di voler eliminare questo commento?',
      'failed_to_load_articles': 'Errore nel caricamento degli articoli: {error}',
    },
  };
}