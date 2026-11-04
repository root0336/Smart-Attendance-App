import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpGeneratorScreen extends StatefulWidget {
  const OtpGeneratorScreen({super.key});
  @override
  State<OtpGeneratorScreen> createState() => _OtpGeneratorScreenState();
}

class _OtpGeneratorScreenState extends State<OtpGeneratorScreen> {
  String _currentOtp = "----";
  bool _isGenerating = false;

  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 300);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _expireOtp();
      }
    });
  }

  Future<void> _expireOtp() async {
    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc('active_session')
          .update({'status': 'expired'});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("OTP has expired")));
      }
    } catch (e) {
      debugPrint("Error expiring OTP: $e");
    }
  }

  Future<void> _generateAndSaveOtp() async {
    setState(() => _isGenerating = true);
    String newOtp = (1000 + Random().nextInt(9000)).toString();

    DateTime now = DateTime.now();
    DateTime expiry = now.add(const Duration(minutes: 5));
    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc('active_session')
          .set({
            'otp': newOtp,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(expiry),
            'status': 'active',
          });
      setState(() {
        _currentOtp = newOtp;
        _isGenerating = false;
      });
      _startCountdown();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
      setState(() => _isGenerating = false);
    }
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Class Session"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "TIME REMAINING: ${_formatTime(_secondsRemaining)}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _secondsRemaining < 30 ? Colors.red : Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Student Entrance Code",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              _currentOtp,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 60),
            if (_isGenerating)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _generateAndSaveOtp,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Generate New OTP"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      _timer?.cancel();
                      _expireOtp();
                      setState(() {
                        _currentOtp = "----";
                        _secondsRemaining = 0;
                      });
                    },
                    child: const Text(
                      "End Session Now",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
