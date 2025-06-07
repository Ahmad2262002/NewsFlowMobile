import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:newsflow/Core/Network/DioClient.dart';
import 'package:newsflow/Core/showSuccessDialog.dart';
import 'package:newsflow/Core/showErrorDialog.dart';
import 'package:newsflow/Routes/AppRoute.dart';

class ResetPasswordController extends GetxController {
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  // Add these observables for password visibility
  var obscureNewPassword = true.obs;
  var obscureConfirmPassword = true.obs;

  var token = ''.obs;
  var email = ''.obs;
  var isLoading = false.obs;

  // Add method to toggle password visibility
  void toggleNewPasswordVisibility() => obscureNewPassword.toggle();
  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.toggle();

  Future<void> resetPassword() async {
    if (newPassword.text.isEmpty || confirmPassword.text.isEmpty) {
      showErrorDialog("Error", "Please fill in all fields");
      return;
    }

    if (newPassword.text != confirmPassword.text) {
      showErrorDialog("Error", "Passwords don't match");
      return;
    }

    isLoading.value = true;
    try {
      final response = await DioClient().getInstance().post(
        '/auth/reset-password',
        data: {
          'token': token.value,
          'email': email.value,
          'password': newPassword.text,
          'password_confirmation': confirmPassword.text,
        },
      );

      if (response.statusCode == 200) {
        showSuccessDialog(
          "Success",
          "Password reset successfully",
              () => Get.offAllNamed(AppRoute.login),
        );
      } else {
        showErrorDialog(
          "Error",
          response.data['message'] ?? "Failed to reset password",
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
    newPassword.dispose();
    confirmPassword.dispose();
    super.onClose();
  }
}