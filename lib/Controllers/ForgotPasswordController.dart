import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:newsflow/Core/Network/DioClient.dart';
import 'package:newsflow/Core/showSuccessDialog.dart';
import 'package:newsflow/Core/showErrorDialog.dart';

class ForgotPasswordController extends GetxController {
  final TextEditingController email = TextEditingController();
  var isLoading = false.obs;

  Future<void> sendResetLink() async {
    if (isLoading.value) return;
    if (email.text.isEmpty || !GetUtils.isEmail(email.text)) {
      showErrorDialog("Invalid Email", "Please enter a valid email address");
      return;
    }

    isLoading.value = true;
    try {
      final response = await DioClient().getInstance().post(
        '/forgot-password',
        data: {'email': email.text.trim()},
      );

      if (response.statusCode == 200) {
        showSuccessDialog(
          "Email Sent",
          "If your email exists in our system, you'll receive a reset link",
              () => Get.back(),
        );
      } else {
        showErrorDialog(
          "Error",
          response.data['message'] ?? "Failed to send reset link",
        );
      }
    } catch (e) {
      showErrorDialog(
        "Network Error",
        "Please check your internet connection",
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    email.dispose();
    super.onClose();
  }
}