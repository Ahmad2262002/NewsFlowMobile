import 'package:get/get.dart';
import 'package:newsflow/Controllers/ResetPasswordController.dart';

class ResetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => ResetPasswordController());
  }
}
