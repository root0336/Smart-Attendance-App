import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:math';

class AdminQRGeneratorScreen extends StatefulWidget {
  const AdminQRGeneratorScreen({super.key});
  @override
  State<AdminQRGeneratorScreen> createState() => _AdminQRGeneratorScreenState();
}

class _AdminQRGeneratorScreenState extends State<AdminQRGeneratorScreen> {
  bool _isProcessing = false;

  Future<void> _handleSessionGeneration() async {
    setState(() => _isProcessing = true);
    try {
      String newOtp = (Random().nextInt(9000) + 1000).toString();
      DateTime now = DateTime.now();
      DateTime expiry = now.add(const Duration(minutes: 5));

      await FirebaseFirestore.instance
          .collection('sessions')
          .doc('active_session')
          .set({
            'otp': newOtp,
            'status': 'active',
            'type': 'QR',

            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(expiry),
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Attendance QR Generated!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Attendance QR Code",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('sessions')
                .doc('active_session')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var data = snapshot.data?.data() as Map<String, dynamic>?;
          bool hasDoc = snapshot.hasData && snapshot.data!.exists;

          String status = data?['status'] ?? "expired";
          Timestamp? expiry = data?['expiresAt'];
          bool isCurrentlyActive =
              hasDoc &&
              status == 'active' &&
              expiry != null &&
              expiry.toDate().isAfter(DateTime.now()) &&
              data?['type'] == 'QR';
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 50.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCurrentlyActive) ...[
                    _buildQRCodeCard(data!['otp']),
                    const SizedBox(height: 40),
                    _buildStatusHeader(true, data['otp']),
                    const SizedBox(height: 30),
                    _buildCountdownTimer(expiry!),
                    const SizedBox(height: 40),
                    _buildActionButtons(isReset: true),
                  ] else ...[
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 200,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "No Active QR Session",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Generate a new session to start receiving scans",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buildActionButtons(isReset: false),
                  ],
                  const SizedBox(height: 50),
                  const Text(
                    "Students must be connected to College WiFi and within range to scan successfully.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQRCodeCard(String otp) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: QrImageView(
        data: otp,
        version: QrVersions.auto,
        size: 260.0,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF1E293B),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: Color(0xFF3B82F6),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(bool active, String otp) {
    return Column(
      children: [
        Text(
          active ? "QR Active" : "Session Expired",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: active ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Secret Key: $otp",
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF64748B),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons({required bool isReset}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _handleSessionGeneration,
        icon:
            _isProcessing
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Icon(
                  isReset ? Icons.refresh : Icons.qr_code,
                  color: Colors.white,
                ),
        label: Text(
          isReset ? "Generate New QR" : "Start QR Attendance",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isReset ? Colors.orange : const Color(0xFF3B82F6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownTimer(Timestamp expiry) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        Duration diff = expiry.toDate().difference(DateTime.now());
        if (diff.isNegative) {
          return const Text(
            "Expired",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: Colors.orange),
              const SizedBox(width: 10),
              Text(
                "${diff.inMinutes}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
