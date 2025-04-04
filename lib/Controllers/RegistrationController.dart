import 'dart:convert';

import 'package:dio/dio.dart' as dio_package; // Alias for Dio
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:newsflow/Core/Network/DioClient.dart';
import 'package:newsflow/Core/showSuccessDialog.dart';
import 'package:newsflow/Core/showErrorDialog.dart';
import 'package:newsflow/Models/User.dart';
import 'package:newsflow/Routes/AppRoute.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationController extends GetxController {
  // Controllers for form fields
  final TextEditingController email = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController passwordConfirm = TextEditingController();

  // Loading state
  var isLoading = false.obs;

  // SharedPreferences instance
  late SharedPreferences prefs;

  @override
  void onInit() {
    super.onInit();
    _loadSharedPreferences();
  }

  // Load SharedPreferences
  void _loadSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Handle registration process
  Future<void> register() async {
    if (isLoading.value) return; // Prevent multiple clicks

    // Validate form fields
    if (name.text.isEmpty || email.text.isEmpty || password.text.isEmpty || passwordConfirm.text.isEmpty) {
      showErrorDialog("Error", "Please fill in all fields.");
      return;
    }

    if (password.text != passwordConfirm.text) {
      showErrorDialog("Error", "Passwords do not match.");
      return;
    }

    isLoading.value = true; // Start loading

    try {
      final user = User(
        name: name.text.trim(),
        email: email.text.trim(),
        password: password.text.trim(),
        passwordConfirm: passwordConfirm.text.trim(),
      );

      final response = await DioClient().getInstance().post(
        '/register-user',
        data: user.toMap(),
      );

      if (response.statusCode == 201) {
        // Handle successful registration
        _handleRegistrationSuccess(response.data);
      } else {
        // Handle server errors
        _handleErrorResponse(response);
      }
    } on dio_package.DioException catch (e) { // Use alias for DioException
      // Handle Dio errors (e.g., bad response)
      if (e.response != null) {
        // Handle API response errors
        _handleErrorResponse(e.response!);
      } else {
        // Handle network or unexpected errors
        _handleNetworkError(e);
      }
    } catch (e) {
      // Handle other unexpected errors
      _handleNetworkError(e);
    } finally {
      isLoading.value = false; // Stop loading
    }
  }

  // Handle successful registration
  void _handleRegistrationSuccess(Map<String, dynamic> responseData) {
    showSuccessDialog(
      "Success 🎉", // Title with emoji for a modern touch
      'Your account has been successfully created!', // Friendly success message
          () { // Callback
        prefs.setString('token', responseData['token']);
        prefs.setString('staff', jsonEncode(responseData['staff'])); // Save staff data
        prefs.setString('user_profile', jsonEncode(responseData['user_profile'])); // Save user profile
        Get.toNamed(AppRoute.login);
      },
    );
  }

  // Handle server errors
  void _handleErrorResponse(dio_package.Response response) { // Use alias for Response
    final statusCode = response.statusCode;
    final responseData = response.data;

    if (statusCode == 409) {
      // Handle username or email already taken
      final errors = responseData['errors'] as Map<String, dynamic>?;
      if (errors != null) {
        final usernameError = errors['username']?.first as String?;
        final emailError = errors['email']?.first as String?;

        if (usernameError != null && emailError != null) {
          showErrorDialog("Oops! 😕", "Both username and email are already taken. Please try different ones.");
        } else if (usernameError != null) {
          showErrorDialog("Oops! 😕", "The username is already taken. Please choose a different one.");
        } else if (emailError != null) {
          showErrorDialog("Oops! 😕", "The email is already registered. Please use a different email.");
        } else {
          showErrorDialog("Oops! 😕", "Username or email is already taken.");
        }
      } else {
        showErrorDialog("Oops! 😕", "Username or email is already taken.");
      }
    } else {
      // Handle other server errors
      final message = responseData['message'] as String? ?? "Something went wrong. Please try again later.";
      showErrorDialog("Error", message);
    }
  }

  // Handle network errors
  void _handleNetworkError(dynamic error) {
    showErrorDialog("Network Issue 🌐", "Please check your internet connection and try again.");
  }
}