import 'package:get/get.dart';
import 'package:newsflow/Controllers/HomeController.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.lazyPut(() => HomeController());
  }
}
