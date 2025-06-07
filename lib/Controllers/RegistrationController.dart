import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newsflow/Core/Network/DioClient.dart';
import 'package:newsflow/Core/showSuccessDialog.dart';
import 'package:newsflow/Core/showErrorDialog.dart';
import 'package:newsflow/Routes/AppRoute.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationController extends GetxController {
  // Controllers
  final TextEditingController email = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController otp = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController passwordConfirm = TextEditingController();

  // State
  var isLoading = false.obs;
  var showEmailScreen = true.obs;
  var countdown = 0.obs;
  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    initSharedPreferences();
  }

  Future<void> initSharedPreferences() async {
    await SharedPreferences.getInstance().then((value) => prefs = value);
  }

  late SharedPreferences prefs;

  bool _isValidGmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@gmail\.com$');
    return regex.hasMatch(email);
  }

  Future<void> sendOTP() async {
    if (isLoading.value) return;

    final emailValue = email.text.trim();
    if (emailValue.isEmpty) {
      showErrorDialog("Email Required", "Please enter your Gmail address");
      return;
    }

    if (!_isValidGmail(emailValue)) {
      showErrorDialog(
        "Invalid Email",
        "Please use a valid Gmail address (e.g., yourname@gmail.com)",
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await DioClient().getInstance().post(
        '/register-user',
        data: {'email': emailValue},
      );

      if (response.statusCode == 200) {
        showEmailScreen.value = false;
        startCountdown();
        showSuccessDialog(
          "Verification Sent",
          "We've sent a 6-digit code to $emailValue",
              () {}, // Empty callback to match your original implementation
        );
      } else {
        showErrorDialog(
          "Failed to Send",
          response.data['message'] ?? "Couldn't send verification code",
        );
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      showErrorDialog("Error! 😕", "Something went wrong. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> completeRegistration() async {
    if (isLoading.value) return;

    // Validate all fields
    if (name.text.isEmpty) {
      showErrorDialog("Name Required", "Please enter your full name");
      return;
    }

    if (otp.text.length != 6) {
      showErrorDialog("Invalid Code! 😕", "Please enter the 6-digit verification code");
      return;
    }

    if (password.text.length < 8) {
      showErrorDialog(
        "Weak Password",
        "Password must be at least 8 characters long",
      );
      return;
    }

    if (password.text != passwordConfirm.text) {
      showErrorDialog(
        "Password Mismatch",
        "The passwords you entered don't match",
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await DioClient().getInstance().post(
        '/verify-otp',
        data: {
          'email': email.text.trim(),
          'otp': otp.text.trim(),
          'username': name.text.trim(),
          'password': password.text.trim(),
          'password_confirmation': passwordConfirm.text.trim(),
        },
      );

      if (response.statusCode == 201) {
        _handleRegistrationSuccess(response.data);
      } else {
        showErrorDialog(
          "Registration Failed",
          response.data['message'] ?? "Couldn't complete registration",
        );
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      showErrorDialog("Error", "Something went wrong. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  void _handleRegistrationSuccess(Map<String, dynamic> responseData) {
    showSuccessDialog(
      "Registration Complete!",
      "Your account has been successfully created",
          () {
        prefs.setString('token', responseData['token']);
        prefs.setString('staff', jsonEncode(responseData['staff']));
        prefs.setString('user_profile', jsonEncode(responseData['user_profile']));
        Get.toNamed(AppRoute.login);
      },
    );
  }

  void _handleDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      final errorMessage = response.data['error'] ??
          response.data['message'] ??
          "An error occurred (${response.statusCode})";
      showErrorDialog("Error", errorMessage.toString());
    } else {
      showErrorDialog(
        "Connection Error",
        "Network Issue 🌐, Please check your internet connection and try again"
          // Handle network errors

      );
    }
  }

  void startCountdown() {
    countdown.value = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> resendOTP() async {
    if (countdown.value > 0) return;
    await sendOTP();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    email.dispose();
    name.dispose();
    otp.dispose();
    password.dispose();
    passwordConfirm.dispose();
    super.onClose();
  }
}