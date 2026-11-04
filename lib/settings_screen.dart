import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _wifiController = TextEditingController();
  final _radiusController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 30);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    var doc =
        await FirebaseFirestore.instance
            .collection('settings')
            .doc('requirements')
            .get();
    if (doc.exists) {
      setState(() {
        _wifiController.text = doc['wifi_ssid'] ?? "";
        _radiusController.text = doc['radius'].toString();
        _latController.text = doc['lat'].toString();
        _lngController.text = doc['lng'].toString();

        if (doc['start_hour'] != null) {
          _startTime = TimeOfDay(
            hour: doc['start_hour'],
            minute: doc['start_minute'],
          );
          _endTime = TimeOfDay(
            hour: doc['end_hour'],
            minute: doc['end_minute'],
          );
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('requirements')
          .set({
            'wifi_ssid': _wifiController.text.trim(),
            'radius': double.parse(_radiusController.text),
            'lat': double.parse(_latController.text),
            'lng': double.parse(_lngController.text),

            'start_hour': _startTime.hour,
            'start_minute': _startTime.minute,
            'end_hour': _endTime.hour,
            'end_minute': _endTime.minute,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Settings Updated!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "System Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Schedule Constraints"),
            Row(
              children: [
                Expanded(
                  child: _buildTimeTile(
                    "Starts",
                    _startTime,
                    () => _selectTime(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeTile(
                    "Ends",
                    _endTime,
                    () => _selectTime(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle("Network Verification"),
            _buildTextField(
              "Required WiFi SSID",
              _wifiController,
              Icons.wifi,
              "e.g. College_WiFi",
            ),
            const SizedBox(height: 24),
            _buildSectionTitle("Location Verification"),
            _buildTextField(
              "Latitude",
              _latController,
              Icons.location_on,
              "e.g. 33.6844",
            ),
            _buildTextField(
              "Longitude",
              _lngController,
              Icons.location_on,
              "e.g. 73.0479",
            ),
            _buildTextField(
              "Radius (meters)",
              _radiusController,
              Icons.explore,
              "e.g. 50",
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          "Save Configuration",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
