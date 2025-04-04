import 'package:get/get.dart';
import 'package:newsflow/Bindings/HomeBinding.dart';
import 'package:newsflow/Bindings/LoginBinding.dart';
import 'package:newsflow/Bindings/RegistrationBinding.dart';
import 'package:newsflow/Routes/AppRoute.dart';
import 'package:newsflow/Views/Registration.dart';
import '../Views/Login.dart';
import '../Views/Home.dart'; // Import the correct Home widget

class AppPage {
  static final List<GetPage> pages = [
    GetPage(
        name: AppRoute.register,
        page: () => Registration(),
        binding: RegistrationBinding()),
    GetPage(
        name: AppRoute.login,
        page: () => Login(),
        binding: LoginBinding()),
    GetPage(
        name: AppRoute.home,
        page: () => Home(), // Use the correct Home widget
        binding: HomeBinding()),
  ];
}