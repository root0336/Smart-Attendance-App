import 'package:flutter/material.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color themeBlue = Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              const Icon(
                Icons.calendar_today_rounded,
                size: 90,
                color: themeBlue,
              ),
              const SizedBox(height: 20),
              const Text(
                "Smart Attendance",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "By Muhammad Ahmed Khan",
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              const Spacer(flex: 4),

              Material(
                color: themeBlue,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),

                  splashColor: Colors.white.withOpacity(0.7),
                  highlightColor: Colors.white.withOpacity(0.4),
                  onTap: () async {
                    await Future.delayed(const Duration(milliseconds: 25));

                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    alignment: Alignment.center,
                    child: const Text(
                      "Get Started",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
