import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:newsflow/Core/Network/DioClient.dart';
import 'package:newsflow/Core/showErrorDialog.dart';
import 'package:newsflow/Core/showSuccessDialog.dart';
import 'package:newsflow/Routes/AppRoute.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController extends GetxController {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  late final SharedPreferences prefs;

  // Fun messages for different scenarios
  final _funnyMessages = {
    'welcome': [
      "Welcome back! Ready for some news?",
      "Ah, you're back! Missed us, didn't you?",
      "News awaits! Let's get you in.",
    ],
    'emptyFields': [
      "Oops! You forgot to fill something!",
      "Empty fields? That's like a newspaper with no news!",
      "We need those deets to let you in!",
    ],
    'invalidEmail': [
      "That email looks... suspicious. Like fake news!",
      "Is that a real email or are you testing us?",
      "Even our AI thinks that email looks funny!",
    ],
    'networkError': [
      "Who turned off the internet? Check your connection!",
      "No signal? Try waving your phone around!",
      "Our servers are on a coffee break. Try again soon!",
    ],
    'timeout': [
      "The server is taking a nap. Try again!",
      "This is slower than snail mail! Try again?",
      "Timeout! Even turtles would be faster!",
    ],
    'loginFailed': [
      "Oops! Wrong combo. Try again?",
      "Invalid credentials. Are you a robot? 🤖",
      "That didn't work. Maybe your cat walked on the keyboard?",
    ],
    'unexpectedError': [
      "Something weird happened. Blame the gremlins!",
      "Our app just did a somersault. Try again?",
      "Error 42: Meaning of life not found. Try again!",
    ],
    'success': [
      "Success! Let's get you the freshest news!",
      "You're in! Time to read all the things!",
      "Access granted! Prepare for news overload!",
    ]
  };

  String _getRandomMessage(String key) {
    final messages = _funnyMessages[key] ?? ["Please try again."];
    return messages[DateTime.now().millisecond % messages.length];
  }

  @override
  void onInit() async {
    super.onInit();
    await _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    try {
      prefs = await SharedPreferences.getInstance();
      final bool hasToken = prefs.getString('token') != null;

      if (hasToken) {
        final staffData = prefs.getString('staff');
        final userProfileData = prefs.getString('userProfile'); // Changed from user_profile
        if (staffData != null) {
          final staff = jsonDecode(staffData) as Map<String, dynamic>;
          showSuccessDialog(
            "Welcome Back, ${staff['username']}! 👋",
            "We're restoring your session...",
                () => _redirectToHome(),
          );
        }
      }
    } catch (e) {
      debugPrint('SharedPreferences init error: $e');
      showErrorDialog(
        "Session Trouble",
        "We couldn't restore your session automatically. Please login again.",
      );
    }
  }

  Future<void> _redirectToHome() async {
    try {
      final staffJson = prefs.getString('staff');
      final userProfileJson = prefs.getString('userProfile'); // Changed from user_profile

      if (staffJson != null) {
        Get.offAllNamed(
          AppRoute.home,
          arguments: {
            'staff': jsonDecode(staffJson),
            'userProfile': userProfileJson != null ? jsonDecode(userProfileJson) : {},
          },
        );
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      showErrorDialog(
          "Navigation Trouble",
          "We're having trouble taking you to the news. Please try again."
      );
    }
  }

  Future<void> login() async {
    if (isLoading.value) return;

    // Validate inputs with fun messages
    if (email.text.isEmpty || password.text.isEmpty) {
      showErrorDialog("Hold on!🔒", _getRandomMessage('emptyFields'));
      return;
    }

    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email.text.trim())) {
      showErrorDialog("Email Alert!😕", _getRandomMessage('invalidEmail'));
      return;
    }

    isLoading(true);

    try {
      final response = await DioClient().getInstance().post(
        "/login",
        data: {
          'email': email.text.trim(),
          'password': password.text.trim(),
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        await _handleLoginResponse(response.data);
      } else {
        final errorMessage = response.data?['message'] ??
            response.data?['error'] ??
            _getRandomMessage('loginFailed');
        showErrorDialog("Oops!", errorMessage);
      }
    } on SocketException {
      showErrorDialog("Connection Issue", _getRandomMessage('networkError'));
    } on TimeoutException {
      showErrorDialog("Too Slow!", _getRandomMessage('timeout'));
    } on DioException catch (e) {
      debugPrint('Dio error: ${e.response?.data}');
      final errorMessage = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          _getRandomMessage('loginFailed');
      showErrorDialog("Whoops!", errorMessage);
    } catch (e, stackTrace) {
      debugPrint('Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      showErrorDialog("Hmm...", _getRandomMessage('unexpectedError'));
    } finally {
      isLoading(false);
    }
  }

  Future<void> _handleLoginResponse(Map<String, dynamic> responseData) async {
    try {
      final staff = responseData['staff'] as Map<String, dynamic>?;
      final token = responseData['token'] as String?;
      final userId = responseData['user_id']?.toString(); // Get user_id from response

      if (staff == null || token == null || token.isEmpty) {
        throw Exception('Invalid response data');
      }

      // Create complete user profile including user_id
      final userProfile = {
        'user_id': userId ?? staff['staff_id']?.toString(), // Fallback to staff_id if needed
        'username': staff['username'],
        'email': staff['email'],
        'profile_picture': responseData['profile_picture'] // Add if available
      };

      // Check if user has logged in before
      final bool isReturningUser = prefs.getString('token') != null;
      final String welcomeTitle = isReturningUser
          ? "Welcome Back, ${staff['username']}! 👋"
          : "Welcome, ${staff['username']}! 🎉";
      final String welcomeMessage = isReturningUser
          ? "We missed you! Ready to catch up on the latest news?"
          : "Thanks for joining us! Let's explore the news together!";

      final saveResults = await Future.wait([
        prefs.setString('token', token),
        prefs.setString('staff', jsonEncode(staff)),
        prefs.setString('userProfile', jsonEncode(userProfile)), // Changed to userProfile
      ]);

      if (saveResults.any((result) => result == false)) {
        throw Exception('Failed to save login data');
      }

      showSuccessDialog(
        welcomeTitle,
        "Email: ${staff['email']}\n\n$welcomeMessage",
            () {
          Get.offAllNamed(
            AppRoute.home,
            arguments: {
              'staff': staff,
              'userProfile': userProfile,
            },
          );
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error processing login response: $e');
      debugPrint('Stack trace: $stackTrace');

      await Future.wait([
        prefs.remove('token'),
        prefs.remove('staff'),
        prefs.remove('userProfile'), // Changed to userProfile
      ]);

      showErrorDialog(
        "Oopsie!",
        "We got confused and dropped your login. Try again?",
      );
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
    showSuccessDialog(
      "Password Visibility Changed 👀",
      isPasswordVisible.value
          ? "Your password is now visible. Be careful around prying eyes!"
          : "Your password is now hidden. Safety first!",
      null,
    );
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}