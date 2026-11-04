import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AttendanceReportScreen extends StatelessWidget {
  final String userRole;

  const AttendanceReportScreen({super.key, required this.userRole});

  Future<void> _downloadReport(
    List<QueryDocumentSnapshot> attendanceDocs,
    List<QueryDocumentSnapshot> studentDocs,
  ) async {
    final pdf = pw.Document();
    final String todayDate = DateFormat('dd-MMM-yyyy').format(DateTime.now());

    Map<String, Timestamp?> attendanceMap = {
      for (var doc in attendanceDocs)
        (doc.data() as Map<String, dynamic>)['studentEmail']:
            (doc.data() as Map<String, dynamic>)['timestamp'] as Timestamp?,
    };

    List<List<String>> tableRows = [];
    for (var studentDoc in studentDocs) {
      var studentData = studentDoc.data() as Map<String, dynamic>;
      String email = studentData['email'] ?? 'N/A';
      String name = studentData['name'] ?? 'Unknown';

      bool isPresent = attendanceMap.containsKey(email);
      Timestamp? ts = attendanceMap[email];

      String timeStr = "-";
      if (isPresent && ts != null) {
        timeStr = DateFormat('hh:mm a').format(ts.toDate());
      }

      tableRows.add([name, email, isPresent ? "Present" : "Absent", timeStr]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Attendance Report",
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "BSCS VIII 2022 Batch",
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(todayDate),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Student Name', 'Email', 'Status', 'Time'],
                data: tableRows,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                cellHeight: 25,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                },

                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200),
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 20),
                child: pw.Text(
                  "End of Report",
                  style: const pw.TextStyle(color: PdfColors.grey),
                ),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Attendance_Report_$todayDate',
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = userRole.toLowerCase() == 'admin';

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Attendance Analytics",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'Student')
                .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> studentSnapshot) {
          return StreamBuilder(
            stream:
                FirebaseFirestore.instance
                    .collection('attendance')
                    .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
                    .where('timestamp', isLessThanOrEqualTo: endOfDay)
                    .snapshots(),
            builder: (
              context,
              AsyncSnapshot<QuerySnapshot> attendanceSnapshot,
            ) {
              if (studentSnapshot.connectionState == ConnectionState.waiting ||
                  attendanceSnapshot.connectionState ==
                      ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              int totalStudents = studentSnapshot.data?.docs.length ?? 0;
              int presentCount = attendanceSnapshot.data?.docs.length ?? 0;
              int absentCount = (totalStudents - presentCount).clamp(
                0,
                totalStudents,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Report for ${DateFormat('dd MMMM yyyy').format(DateTime.now())}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      height: 280,
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child:
                          totalStudents == 0
                              ? const Center(
                                child: Text("No students registered"),
                              )
                              : (presentCount == 0 && absentCount == 0)
                              ? const Center(child: Text("No data for today"))
                              : PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40,
                                  sections: [
                                    if (presentCount > 0)
                                      PieChartSectionData(
                                        value: presentCount.toDouble(),
                                        title: '$presentCount',
                                        color: const Color(0xFF10B981),
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    if (absentCount > 0)
                                      PieChartSectionData(
                                        value: absentCount.toDouble(),
                                        title: '$absentCount',
                                        color: const Color(0xFFEF4444),
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                    ),
                    const SizedBox(height: 25),

                    Row(
                      children: [
                        _statCard(
                          "Total",
                          totalStudents.toString(),
                          const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          "Present",
                          presentCount.toString(),
                          const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 12),
                        _statCard(
                          "Absent",
                          absentCount.toString(),
                          const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    if (isAdmin) ...[
                      const Text(
                        "Administrative Actions",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          onPressed:
                              (studentSnapshot.data?.docs.isEmpty ?? true)
                                  ? null
                                  : () => _downloadReport(
                                    attendanceSnapshot.data!.docs,
                                    studentSnapshot.data!.docs,
                                  ),
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            "Share PDF Report",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Center(
                        child: Text(
                          "This data is real-time and subject to faculty review.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
