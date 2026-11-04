import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'login_screen.dart';
import 'student_otp_screen.dart';
import 'studentscanqr_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool isWifiVerified = false;
  bool isRadiusVerified = false;
  bool isTimeVerified = false;
  bool isOtpActive = false;
  bool isQrActive = false;
  bool isLoading = false;

  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _runFullVerification();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * (math.pi / 180);

  Future<void> _runFullVerification() async {
    setState(() => isLoading = true);
    try {
      DocumentSnapshot requirementsDoc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc('requirements')
              .get();

      DocumentSnapshot sessionDoc =
          await FirebaseFirestore.instance
              .collection('sessions')
              .doc('active_session')
              .get();

      if (requirementsDoc.exists && sessionDoc.exists) {
        var reqData = requirementsDoc.data() as Map<String, dynamic>;
        var sessionData = sessionDoc.data() as Map<String, dynamic>;

        DateTime now = DateTime.now();
        int currentTotalMins = (now.hour * 60) + now.minute;
        int startMins =
            (reqData['start_hour'] ?? 0) * 60 + (reqData['start_minute'] ?? 0);
        int endMins =
            (reqData['end_hour'] ?? 0) * 60 + (reqData['end_minute'] ?? 0);
        bool isInsideCollegeHours =
            currentTotalMins >= startMins && currentTotalMins <= endMins;

        bool otpValid = false;
        bool qrValid = false;

        if (sessionData['status'] == 'active' &&
            sessionData['expiresAt'] != null) {
          Timestamp expiry = sessionData['expiresAt'];
          bool notExpired = now.isBefore(expiry.toDate());

          if (notExpired) {
            if (sessionData['type'] == 'QR') {
              qrValid = true;
            } else {
              otpValid = true;
            }
          }
        }

        String? currentSsid = await _networkInfo.getWifiName();
        String targetSsid = reqData['wifi_ssid'] ?? "";
        bool wifiCheck = false;
        if (currentSsid != null) {
          wifiCheck = (currentSsid.replaceAll('"', '') == targetSsid);
        }

        bool radiusCheck = false;
        double adminLat = (reqData['lat'] ?? 0.0).toDouble();
        double adminLng = (reqData['lng'] ?? 0.0).toDouble();
        double adminRad = (reqData['radius'] ?? 0.0).toDouble();

        if (adminLat != 0.0 && adminLng != 0.0) {
          LocationPermission p = await Geolocator.checkPermission();
          if (p == LocationPermission.denied)
            p = await Geolocator.requestPermission();
          if (p == LocationPermission.whileInUse ||
              p == LocationPermission.always) {
            Position pos = await Geolocator.getCurrentPosition();
            radiusCheck =
                _calculateDistance(
                  pos.latitude,
                  pos.longitude,
                  adminLat,
                  adminLng,
                ) <=
                adminRad;
          }
        }

        setState(() {
          isTimeVerified = isInsideCollegeHours;
          isOtpActive = otpValid;
          isQrActive = qrValid;
          isWifiVerified = wifiCheck;
          isRadiusVerified = radiusCheck;
        });
      }
    } catch (e) {
      debugPrint("Verification failed: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool allChecksPassed = isWifiVerified && isRadiusVerified && isTimeVerified;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Student Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _runFullVerification,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Mark Attendance",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Ensure all checks are green to proceed",
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 32),
              if (isLoading) const LinearProgressIndicator(),
              const SizedBox(height: 10),
              _buildCheckItem("College WiFi Connection", isWifiVerified),
              _buildCheckItem("Inside College Radius", isRadiusVerified),
              _buildCheckItem("Correct Time Window", isTimeVerified),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed:
                      (allChecksPassed && isOtpActive)
                          ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StudentOTPScreen(),
                            ),
                          )
                          : null,
                  child: const Text(
                    "Enter OTP",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed:
                      (allChecksPassed && isQrActive)
                          ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const StudentQRScannerScreen(),
                            ),
                          )
                          : null,
                  label: const Text(
                    "Scan QR Code",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: _runFullVerification,
                  icon: const Icon(Icons.sync),
                  label: const Text("Re-Verify Status"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
  }

  Widget _buildCheckItem(String title, bool isPassed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isPassed ? Colors.green.shade100 : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isPassed ? Colors.green : Colors.grey.shade300,
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isPassed ? Colors.green.shade700 : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
