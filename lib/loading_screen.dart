import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'Routes/AppRoute.dart';

class LuxuryLoadingScreen extends StatefulWidget {
  const LuxuryLoadingScreen({super.key});

  @override
  State<LuxuryLoadingScreen> createState() => _LuxuryLoadingScreenState();
}

class _LuxuryLoadingScreenState extends State<LuxuryLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 26));
    Get.offAllNamed(AppRoute.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie animation (centered and larger)
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: Lottie.asset(
                      'assets/animations/news_loading.json',
                      controller: _controller,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 30),
                  const AnimatedTextWidget(),
                  const SizedBox(height: 30),

                  // Gold progress indicator
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFD4AF37),
                      ),
                      minHeight: 4,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'NewsFlow v1.0.0',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedTextWidget extends StatefulWidget {
  const AnimatedTextWidget({super.key});

  @override
  State<AnimatedTextWidget> createState() => _AnimatedTextWidgetState();
}

class _AnimatedTextWidgetState extends State<AnimatedTextWidget> {
  final List<String> _loadingMessages = [
    "Curating premium content...",
    "Preparing your experience...",
    "Almost there...",
    "Ready to inspire!"
  ];
  int _currentIndex = 0;
  String _displayText = "";
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
  }

  void _startTypingAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_displayText.length < _loadingMessages[_currentIndex].length) {
        setState(() {
          _displayText = _loadingMessages[_currentIndex]
              .substring(0, _displayText.length + 1);
        });
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _loadingMessages.length;
            _displayText = "";
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w300,
        letterSpacing: 1.1,
      ),
    );
  }
}