import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Login.dart';
import 'homescreen.dart';
import 'RegisterPage.dart';

class Logosplashscreen extends StatefulWidget {
  const Logosplashscreen({super.key});

  @override
  State<Logosplashscreen> createState() => _LogosplashscreenState();
}

class _LogosplashscreenState extends State<Logosplashscreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final bool isRegistered = prefs.getBool('isRegistered') ?? false;
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Small delay for splash animation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 1️⃣ If user NEVER registered → Go to Register page
    if (!isRegistered) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterPage()),
      );
    }

    // 2️⃣ If registered AND logged in → Go to Home
    else if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }

    // 3️⃣ If registered BUT not logged in → Go to Login
    else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Start checking login status
    checkLoginStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // App Logo
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping,
                  size: 50,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 20),

              // App Name
              const Text(
                'Van Go',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              // Tagline
              Text(
                'Smart Van Sale System',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
