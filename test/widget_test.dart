import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance_app/main.dart';

void main() {
  testWidgets('App should load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartAttendanceApp());

    // Verify that our app starts (looking for the Login title or a button)
    expect(find.text('Login'), findsWidgets);
  });
}
