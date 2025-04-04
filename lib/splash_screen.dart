import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import 'package:newsflow/Routes/AppRoute.dart';

class LuxuryLoadingScreen extends StatelessWidget {
  const LuxuryLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 10), () {
      // Replace with your navigation logic
      Get.offNamed(AppRoute.login);
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey[900]!], // Gradient from black to dark grey
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Lottie.asset(
            'assets/animations/news_loading.json', // Path to your Lottie file
            width: 200, // Set the size
            height: 300,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}