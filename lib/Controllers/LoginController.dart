import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:newsflow/Core/Network/DioClient.dart';
import 'package:newsflow/Core/showSuccessDialog.dart';
import 'package:newsflow/Core/showErrorDialog.dart';
import 'package:newsflow/Routes/AppRoute.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController extends GetxController {
  // Controllers for email and password fields
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  // Loading state
  var isLoading = false.obs;

  // SharedPreferences instance
  late SharedPreferences prefs;

  @override
  void onInit() {
    super.onInit();
    _loadSharedPreferences();
  }

  // Load SharedPreferences and check for existing token
  void _loadSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      // Navigate to home if token exists
      final staffJson = prefs.getString('staff');
      final userProfileJson = prefs.getString('user_profile');

      if (staffJson != null) {
        Get.offAllNamed(
          AppRoute.home,
          arguments: {
            'staff': jsonDecode(staffJson), // Decode staff data
            'userProfile': userProfileJson != null ? jsonDecode(userProfileJson) : null,
          },
        );
      }
    }
  }

  // Handle login process
  void login() async {
    if (isLoading.value) return; // Prevent multiple clicks

    // Validate email and password fields
    if (email.text.isEmpty || password.text.isEmpty) {
      showErrorDialog("Oops! 😕", "Please fill in all fields to continue.");
      return;
    }

    isLoading(true); // Start loading

    final data = {
      'email': email.text.trim(),
      'password': password.text.trim(),
    };

    try {
      final response = await DioClient().getInstance().post("/login", data: data);

      if (response.statusCode == 200) {
        // Parse the response
        final staff = response.data['staff'];
        final userProfile = response.data['user_profile']; // Extract user profile
        final token = response.data['token'];

        // Save token, staff, and userProfile data
        await prefs.setString('token', token);
        await prefs.setString('staff', jsonEncode(staff));
        await prefs.setString('user_profile', jsonEncode(userProfile));

        // Debug logs
        print("Staff data: $staff");
        print("User Profile data: $userProfile");
        print("User ID from userProfile: ${userProfile['user_id']}");

        // Navigate to home page with staff and userProfile data
        Get.offNamed(
          AppRoute.home,
          arguments: {
            'staff': staff, // Pass staff data
            'userProfile': userProfile, // Pass user profile
          },
        );

        // Show success dialog
        showSuccessDialog(
          "Welcome Back! 🎉", // Title with emoji for a modern touch
          "You've successfully logged in. Let's dive back into the news!", // Friendly success message
              () {}, // Callback (optional)
        );
      } else if (response.statusCode == 401) {
        // Handle invalid credentials
        showErrorDialog("Uh-oh! 🔒", "The email or password you entered is incorrect. Please try again.");
      } else {
        // Handle other errors
        showErrorDialog("Oops! 😕", "Something went wrong on our end. Please try again later.");
      }
    } catch (e) {
      // Handle network or unexpected errors
      showErrorDialog("Network Issue 🌐", "It seems you're offline. Please check your internet connection and try again.");
    } finally {
      isLoading(false); // Stop loading
    }
  }
}