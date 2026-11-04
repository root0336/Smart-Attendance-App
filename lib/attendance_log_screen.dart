import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceLogScreen extends StatefulWidget {
  const AttendanceLogScreen({super.key});

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Attendance Log",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month,
              color:
                  _selectedDate != null
                      ? const Color(0xFF3B82F6)
                      : Colors.black,
            ),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.red),
              onPressed: () => setState(() => _selectedDate = null),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          return StreamBuilder<QuerySnapshot>(
            stream: _getAttendanceStream(),
            builder: (context, attendanceSnapshot) {
              if (attendanceSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allStudents = userSnapshot.data!.docs;
              final attendanceDocs = attendanceSnapshot.data!.docs;

              List<Map<String, dynamic>> combinedList = _processAttendance(
                allStudents,
                attendanceDocs,
              );

              if (combinedList.isEmpty) return _buildEmptyState();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: combinedList.length,
                itemBuilder: (context, index) {
                  final data = combinedList[index];
                  final DateTime time = data['timestamp'];
                  final String email = data['studentEmail'] ?? 'Unknown Email';
                  final bool isPresent = data['isPresent'] ?? true;

                  bool showHeader = false;
                  String headerText = _getDateHeader(time);
                  if (index == 0) {
                    showHeader = true;
                  } else {
                    String prevHeader = _getDateHeader(
                      combinedList[index - 1]['timestamp'],
                    );
                    if (headerText != prevHeader) showHeader = true;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader) _buildDateHeader(headerText),
                      FutureBuilder<QuerySnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('users')
                                .where('email', isEqualTo: email)
                                .limit(1)
                                .get(),
                        builder: (context, nameSnapshot) {
                          String displayName = "Loading...";
                          if (nameSnapshot.hasData &&
                              nameSnapshot.data!.docs.isNotEmpty) {
                            displayName =
                                nameSnapshot.data!.docs.first['name'] ??
                                'Unknown';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: (isPresent
                                        ? const Color(0xFF3B82F6)
                                        : Colors.grey)
                                    .withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color:
                                      isPresent
                                          ? const Color(0xFF3B82F6)
                                          : Colors.grey,
                                ),
                              ),
                              title: Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        isPresent
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 14,
                                        color:
                                            isPresent
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isPresent
                                            ? (data['status'] ?? 'Present')
                                            : 'Absent',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              isPresent
                                                  ? Colors.green
                                                  : Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isPresent
                                        ? DateFormat('hh:mm a').format(time)
                                        : "--:--",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM').format(time),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getAttendanceStream() {
    var q = FirebaseFirestore.instance
        .collection('attendance')
        .orderBy('timestamp', descending: true);
    if (_selectedDate != null) {
      DateTime start = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      DateTime end = start.add(const Duration(days: 1));
      return q
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThan: end)
          .snapshots();
    }
    return q.snapshots();
  }

  List<Map<String, dynamic>> _processAttendance(
    List<QueryDocumentSnapshot> allStudents,
    List<QueryDocumentSnapshot> attendanceDocs,
  ) {
    List<Map<String, dynamic>> finalResult = [];

    Map<String, List<Map<String, dynamic>>> groupedAttendance = {};
    for (var doc in attendanceDocs) {
      var d = doc.data() as Map<String, dynamic>;
      DateTime date = (d['timestamp'] as Timestamp).toDate();
      String dateKey = DateFormat('yyyy-MM-dd').format(date);

      groupedAttendance.putIfAbsent(dateKey, () => []).add({
        ...d,
        'isPresent': true,
        'timestamp': date,
      });
    }

    if (_selectedDate != null) {
      String selectedKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      groupedAttendance.putIfAbsent(selectedKey, () => []);
    }

    groupedAttendance.forEach((dateKey, presentDocs) {
      DateTime dayDate = DateFormat('yyyy-MM-dd').parse(dateKey);
      Set<String> presentEmails =
          presentDocs
              .map((e) => e['studentEmail'].toString().toLowerCase())
              .toSet();

      finalResult.addAll(presentDocs);

      for (var student in allStudents) {
        var sData = student.data() as Map<String, dynamic>;
        String sEmail = sData['email'].toString().toLowerCase();
        if (!presentEmails.contains(sEmail)) {
          finalResult.add({
            'studentEmail': sData['email'],
            'isPresent': false,
            'timestamp': dayDate,
          });
        }
      }
    });

    finalResult.sort((a, b) {
      int dateCompare = b['timestamp'].compareTo(a['timestamp']);
      if (dateCompare != 0) return dateCompare;
      return (a['isPresent'] ? 0 : 1).compareTo(b['isPresent'] ? 0 : 1);
    });

    return finalResult;
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    if (d == DateTime(now.year, now.month, now.day)) return "Today";
    if (d ==
        DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 1)))
      return "Yesterday";
    return DateFormat('EEEE, dd MMM').format(date);
  }

  Widget _buildDateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "No records found",
        style: TextStyle(color: Colors.grey.shade400),
      ),
    );
  }
}
