import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newsflow/Controllers/ResetPasswordController.dart';

class ResetPasswordScreen extends StatelessWidget {
  final ResetPasswordController controller = Get.put(ResetPasswordController());
  final String token;
  final String email; // Add email parameter

  ResetPasswordScreen({
    required this.token,
    required this.email,
    super.key
  }) {
    controller.token.value = token;
    controller.email.value = email; // Initialize email in controller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Reset Password',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create new password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your new password must be different from previous ones',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 32),

            // New Password Field
            Obx(() => TextField(
              controller: controller.newPassword,
              obscureText: controller.obscureNewPassword.value,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'New Password',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white54),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscureNewPassword.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: controller.toggleNewPasswordVisibility,
                ),
              ),
              style: TextStyle(color: Colors.white),
            )),
            SizedBox(height: 16),

            // Confirm Password Field
            Obx(() => TextField(
              controller: controller.confirmPassword,
              obscureText: controller.obscureConfirmPassword.value,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Confirm Password',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white54),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscureConfirmPassword.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
              ),
              style: TextStyle(color: Colors.white),
            )),
            SizedBox(height: 24),

            // Reset Button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: controller.isLoading.value
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}