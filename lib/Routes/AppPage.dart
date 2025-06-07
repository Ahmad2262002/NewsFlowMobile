import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:newsflow/Bindings/LoginBinding.dart';
import 'package:newsflow/Bindings/RegistrationBinding.dart';
import 'package:newsflow/Bindings/ForgotBinding.dart';
import 'package:newsflow/Bindings/ResetPasswordBinding.dart';
import 'package:newsflow/Bindings/HomeBinding.dart'; // Add this import

import 'package:newsflow/Routes/AppRoute.dart';
import 'package:newsflow/Views/ForgotPasswordScreen.dart';
import 'package:newsflow/Views/ResetPasswordScreen.dart'; // Add this import
import 'package:newsflow/Views/Registration.dart';
import 'package:newsflow/Views/Login.dart';
import 'package:newsflow/Views/Home.dart'; // Add this import

class AppPage {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoute.register,
      page: () => Registration(),
      binding: RegistrationBinding(),
    ),
    GetPage(
      name: AppRoute.login,
      page: () => Login(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoute.home,  // Add this route
      page: () => Home(),   // Use your actual Home widget
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoute.forgotPassword,
      page: () => ForgotPasswordScreen(),
      binding: ForgotBinding(),
    ),
    GetPage(
      name: AppRoute.resetPassword,
      page: () {
        final arguments = Get.arguments as Map<String, dynamic>?;
        if (arguments == null || arguments['token'] == null || arguments['email'] == null) {
          Get.back(); // Or redirect to error page
          return Container(); // Return empty widget as fallback
        }
        return ResetPasswordScreen(
          token: arguments['token'],
          email: arguments['email'],
        );
      },
      binding: ResetPasswordBinding(),
    ),
  ];
}