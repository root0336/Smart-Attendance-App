import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';

class StudentOTPScreen extends StatefulWidget {
  const StudentOTPScreen({super.key});

  @override
  State<StudentOTPScreen> createState() => _StudentOTPScreenState();
}

class _StudentOTPScreenState extends State<StudentOTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _verifyAndMarkAttendance() async {
    String inputOtp = _otpController.text.trim();
    if (inputOtp.length < 4) {
      _showMessage("Please enter the full 4-digit code", Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      var attendanceDocs =
          await FirebaseFirestore.instance
              .collection('attendance')
              .where('studentId', isEqualTo: user.uid)
              .get();
      DateTime now = DateTime.now();
      bool alreadyMarked = false;

      for (var doc in attendanceDocs.docs) {
        var data = doc.data();
        if (data['timestamp'] != null) {
          DateTime recordDate = (data['timestamp'] as Timestamp).toDate();
          if (recordDate.year == now.year &&
              recordDate.month == now.month &&
              recordDate.day == now.day) {
            alreadyMarked = true;
            break;
          }
        }
      }

      if (alreadyMarked) {
        _showMessage(
          "You have already marked attendance for today!",
          Colors.red,
        );
        setState(() => _isSubmitting = false);
        return;
      }

      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String? currentDeviceId;
      if (Platform.isAndroid) {
        var androidInfo = await deviceInfo.androidInfo;
        currentDeviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        var iosInfo = await deviceInfo.iosInfo;
        currentDeviceId = iosInfo.identifierForVendor;
      }

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      DocumentSnapshot sessionDoc =
          await FirebaseFirestore.instance
              .collection('sessions')
              .doc('active_session')
              .get();

      if (!sessionDoc.exists || !userDoc.exists) {
        _showMessage("Session or User record not found.", Colors.red);
        return;
      }

      var sessionData = sessionDoc.data() as Map<String, dynamic>;
      var userData = userDoc.data() as Map<String, dynamic>;

      String serverOtp = sessionData['otp'] ?? "";
      String status = sessionData['status'] ?? "expired";
      Timestamp? expiry = sessionData['expiresAt'];
      String? registeredDeviceId = userData['deviceId'];

      bool isCodeCorrect = (inputOtp == serverOtp);
      bool isStatusActive = (status == 'active');
      bool isNotExpired =
          expiry != null && DateTime.now().isBefore(expiry.toDate());

      bool isDeviceVerified =
          (registeredDeviceId == null || registeredDeviceId == currentDeviceId);

      if (isCodeCorrect && isStatusActive && isNotExpired) {
        if (!isDeviceVerified) {
          _showMessage(
            "Security Alert: Unauthorized device detected.",
            Colors.red,
          );
          return;
        }

        await FirebaseFirestore.instance.collection('attendance').add({
          'studentId': user.uid,
          'studentEmail': user.email,
          'studentName': userData['name'] ?? 'Unknown',
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Present',
          'sessionId': sessionDoc.id,
          'deviceIdUsed': currentDeviceId,
        });

        if (mounted) _showSuccessDialog();
      } else {
        String errorReason = "Invalid Code";
        if (!isStatusActive || !isNotExpired) errorReason = "Session Expired";
        _showMessage(errorReason, Colors.red);
      }
    } catch (e) {
      _showMessage("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            content: const Text(
              "Success! Your attendance has been marked for today.",
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Return Home",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Enter OTP"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 40),
              const Text(
                "Enter the 4-digit code provided by your teacher",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.blueGrey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 20,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "0000",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade300,
                    letterSpacing: 20,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue.shade200,
                      width: 2,
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3B82F6), width: 3),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isSubmitting ? null : _verifyAndMarkAttendance,
                  child:
                      _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            "Confirm Attendance",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
