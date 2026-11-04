import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';

class StudentQRScannerScreen extends StatefulWidget {
  const StudentQRScannerScreen({super.key});

  @override
  State<StudentQRScannerScreen> createState() => _StudentQRScannerScreenState();
}

class _StudentQRScannerScreenState extends State<StudentQRScannerScreen> {
  bool _isProcessing = false;
  bool _isCameraStarted = false;
  MobileScannerController cameraController = MobileScannerController();

  Future<String?> _getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id;
    }
    return null;
  }

  Future<void> _markAttendance(String scannedCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      String? currentDeviceId = await _getDeviceId();

      DocumentSnapshot sessionDoc =
          await FirebaseFirestore.instance
              .collection('sessions')
              .doc('active_session')
              .get();

      if (!sessionDoc.exists || sessionDoc['status'] != 'active') {
        _showError("No active session found.");
        return;
      }

      if (scannedCode != sessionDoc['otp']) {
        _showError("Invalid QR Code. Please scan the teacher's screen.");
        return;
      }

      DocumentReference userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      DocumentSnapshot userDoc = await userRef.get();

      if (!userDoc.exists) {
        _showError("Student profile not found.");
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String studentName = userData['name'] ?? "Unknown Student";
      String studentEmail = userData['email'] ?? "No Email";
      String? savedDeviceId = userData['deviceId'];

      if (savedDeviceId == null) {
        await userRef.update({'deviceId': currentDeviceId});
      } else if (savedDeviceId != currentDeviceId) {
        _showError("Unauthorized device! Use your registered phone.");
        return;
      }

      QuerySnapshot existing =
          await FirebaseFirestore.instance
              .collection('attendance')
              .where('studentId', isEqualTo: user.uid)
              .where('date', isEqualTo: today)
              .get();

      if (existing.docs.isNotEmpty) {
        _showError("Attendance already marked for today!");
        return;
      }

      await FirebaseFirestore.instance.collection('attendance').add({
        'studentId': user.uid,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'deviceId': currentDeviceId,
        'date': today,
        'timestamp': FieldValue.serverTimestamp(),
        'method': 'QR_Scan',
        'status': 'Present',
      });

      _showSuccessDialog();
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
              "Attendance Marked Successfully!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    "OK",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "QR Scanner",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (!_isCameraStarted) ...[
              const SizedBox(height: 60),
              const Icon(
                Icons.qr_code_scanner_rounded,
                size: 100,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(height: 24),
              const Text(
                "Ready to Scan?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Scanning the teacher's QR code will instantly mark your attendance for today.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 80),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isCameraStarted = true),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    "OPEN CAMERA",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B82F6), width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && !_isProcessing) {
                      final String? code = barcodes.first.rawValue;
                      if (code != null) _markAttendance(code);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Align the QR Code in the frame",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _isCameraStarted = false),
                child: const Text("Cancel"),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
