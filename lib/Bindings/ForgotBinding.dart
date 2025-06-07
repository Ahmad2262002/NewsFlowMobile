import 'package:get/get.dart';
import 'package:newsflow/Controllers/ForgotPasswordController.dart';

class ForgotBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => ForgotPasswordController());
  }
}
