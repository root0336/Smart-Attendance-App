import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'otp_generator_screen.dart';
import 'settings_screen.dart';
import 'attendance_log_screen.dart';
import 'login_screen.dart';
import 'view_students.dart';
import 'report_screen.dart';
import 'admin_qr.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _getTimeRemaining(Timestamp? createdAt) {
    if (createdAt == null) return "No active session";
    final now = DateTime.now();
    final expiryTime = createdAt.toDate().add(const Duration(minutes: 5));
    final difference = expiryTime.difference(now);
    if (difference.isNegative) return "Session Expired";
    return "${difference.inMinutes}:${(difference.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Admin Panel",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Admin",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),

            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('sessions')
                      .doc('active_session')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text(
                    "No active sessions currently",
                    style: TextStyle(color: Colors.blueGrey),
                  );
                }
                var data = snapshot.data!.data() as Map<String, dynamic>;
                if (data['status'] != 'active') {
                  return const Text(
                    "All sessions are closed",
                    style: TextStyle(color: Colors.redAccent),
                  );
                }
                return StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, _) {
                    return Text(
                      "Active OTP: ${data['otp']} (Expires in: ${_getTimeRemaining(data['createdAt'] as Timestamp?)})",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(Icons.pin, "Generate OTP", Colors.blue, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OtpGeneratorScreen(),
                      ),
                    );
                  }),
                  _buildMenuCard(
                    Icons.qr_code_2,
                    "Generate QR Code",
                    const Color(0xFF3B82F6),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminQRGeneratorScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    Icons.people,
                    "View Students",
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ViewStudentsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    Icons.bar_chart,
                    "Attendance Log",
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceLogScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    Icons.settings,
                    "Settings",
                    Colors.blueGrey,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildMenuCard(
                    Icons.analytics,
                    "Final Report",
                    Colors.deepPurple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const AttendanceReportScreen(
                                userRole: 'admin',
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
