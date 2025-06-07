import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newsflow/Controllers/RegistrationController.dart';

class Registration extends StatelessWidget {
  final RegistrationController controller = Get.put(RegistrationController());

  Registration({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Registration",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (controller.showEmailScreen.value) {
              Get.back();
            } else {
              controller.showEmailScreen.value = true;
            }
          },
        ),
      ),
      body: Obx(() {
        if (controller.showEmailScreen.value) {
          return _EmailVerificationScreen(controller: controller);
        } else {
          return _CompleteRegistrationScreen(controller: controller);
        }
      }),
    );
  }
}

class _EmailVerificationScreen extends StatelessWidget {
  final RegistrationController controller;
  final FocusNode _emailFocusNode = FocusNode();

  _EmailVerificationScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Step 1: Verify Your Email",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Enter your Gmail address to receive a verification code",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 32),

          // Email Field
          TextField(
            controller: controller.email,
            focusNode: _emailFocusNode,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: "yourname@gmail.com",
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(Icons.email, color: Colors.white54),
            ),
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.sendOTP(),
          ),
          SizedBox(height: 24),

          // Send OTP Button
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.sendOTP,
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
                "Send Verification Code",
                style: TextStyle(fontSize: 16),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _CompleteRegistrationScreen extends StatelessWidget {
  final RegistrationController controller;
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  _CompleteRegistrationScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Step 2: Complete Registration",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: "Enter the 6-digit code sent to ",
              style: TextStyle(color: Colors.white70, fontSize: 14),
              children: [
                TextSpan(
                  text: controller.email.text,
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Name Field
          _buildTextField("Full Name", controller.name, focusNode: _nameFocusNode),

          // OTP Field
          TextField(
            controller: controller.otp,
            focusNode: _otpFocusNode,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: "Enter 6-digit code",
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.white54),
            ),
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          SizedBox(height: 8),

          Obx(() => Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: controller.countdown.value > 0 ? null : controller.resendOTP,
              child: Text(
                controller.countdown.value > 0
                    ? "Resend code in ${controller.countdown.value}s"
                    : "Resend code",
                style: TextStyle(
                  color: controller.countdown.value > 0
                      ? Colors.white54
                      : Colors.blueAccent,
                ),
              ),
            ),
          )),

          // Password Fields
          _buildTextField(
            "Password",
            controller.password,
            obscureText: true,
            focusNode: _passwordFocusNode,
            hintText: "At least 8 characters",
          ),
          _buildTextField(
            "Confirm Password",
            controller.passwordConfirm,
            obscureText: true,
            focusNode: _confirmPasswordFocusNode,
          ),

          SizedBox(height: 24),

          // Register Button
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.completeRegistration,
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
                "Create Account",
                style: TextStyle(fontSize: 16),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        bool obscureText = false,
        FocusNode? focusNode,
        String? hintText,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 16)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          focusNode: focusNode,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade900,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: hintText ?? "Enter your ${label.toLowerCase()}",
            hintStyle: TextStyle(color: Colors.white38),
          ),
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}