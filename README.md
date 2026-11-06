# smart_attendance_app

A new Flutter project.

![Screen 1](assets/Screenshot_2026-03-09-15-50-52-622_com.example.smart_attendance_app.jpg)
![Screen 2](assets/loginscreen2.jpg)
![Screen 3](assets/createnewaccount.jpg)
![Screen 4](assets/forgotpassword.jpg)
![Screen 5](assets/admindashboard.jpg)
![Screen 6](assets/otpgenerator1.jpg)
![Screen 7](assets/otpgenerator2.jpg)
![Screen 8](assets/qrcodegenerator1.jpg)
![Screen 9](assets/qrcodegenerator2.jpg)
![Screen 10](assets/qrcodegenerator3.jpg)
![Screen 11](assets/viewstudents.jpg)
![Screen 12](assets/attendancelog1.jpg)
![Screen 13](assets/attendancelog2.jpg)
![Screen 14](assets/settingscreen.jpg)
![Screen 15](assets/finalreport1.jpg)
![Screen 16](assets/finalreport2.jpg)
![Screen 17](assets/finalreport3.jpg)
![Screen 18](assets/finalreport4.jpg)
![Screen 19](assets/studentdashboard1.jpg)
![Screen 20](assets/studentdashboard2.jpg)
![Screen 21](assets/studentdashboard3.jpg)
![Screen 22](assets/studentdashboard4.jpg)
![Screen 23](assets/studentotpentrance1.jpg)
![Screen 24](assets/studentotpentrance2.jpg)
![Screen 25](assets/studentotpentrance3.jpg)
![Screen 26](assets/studentotpentrance4.jpg)
![Screen 27](assets/markedsuccessfullywithotp.jpg)
![Screen 28](assets/qrcodescanner1.jpg)
![Screen 29](assets/qrcodescanner2.jpg)
![Screen 30](assets/qrcodescanner3.jpg)
![Screen 31](assets/attendancemarkedsuccessfullywithqrcode.jpg)
![Screen 32](assets/screenshot2.jpg)
![Screen 33](assets/screenshot2.jpg)


## Getting Started

The Smart Attendance App developed by Muhammad Ahmed Khan is a secure, cross-platform mobile solution built with Flutter and Firebase designed to automate and streamline academic attendance tracking. The application features dual-portal access equipped with role-based authentication (Student and Admin), secure password recovery, and strict validation protocols. To eliminate proxy attendance and ensure physical presence, the app enforces rigorous multi-factor checks—verifying that students are connected to the designated college Wi-Fi SSID, located within a precise GPS radius, and attempting check-ins strictly within scheduled college time windows. Device Binding is also done to ensure elimination of proxy attendance. QR Code Scan and OTP entrance features are  core features to address real world problems and eliminate proxy attendance.

Key Features

Dual-Role Authentication & Portal Access: Secure sign-up, login, and password reset functionalities via Firebase Auth, supporting distinct dashboards for Students and Admins.

Advanced Location & Network Security: Automated student validations that check current GPS coordinates against defined administrative latitude, longitude, and radius boundaries, alongside mandatory college Wi-Fi SSID verification.

Dynamic Session & Code Generation (Admin): Admins can generate time-sensitive 4-digit OTPs or active QR code attendance sessions with live countdown timers. 

QR Code: To make sure that the student is physically present inside the classroom.

OTP: To ensure smooth attendance when the students cannot physically walk to the admin to scan QR.

Instant Attendance Marking (Student): Students can check-in securely either by entering active OTP codes or utilizing an integrated in-app QR code scanner (mobile_scanner), backed by hardware-level device binding to prevent unauthorized proxy logins.

Real-Time Attendance Logs & Analytics: Comprehensive attendance monitoring logs that automatically track present and absent students dynamically by date, complete with visual breakdown charts (fl_chart).

Professional PDF Reporting: Admins can export, preview, and share official daily attendance reports compiled directly into formatted PDF documents.

Customizable System Settings: Dedicated configuration panels enabling administrators to adjust schedule constraints, required network SSIDs, location coordinates, and geofencing radiuses in real time.


# dependencies:
    flutter: sdk
    intl: ^0.19.0
    network_info_plus: ^6.0.0
    geolocator: ^13.0.1
    fl_chart: ^0.70.2
    csv: ^6.0.0
    share_plus: ^10.1.4
    device_info_plus: ^10.1.0
    pdf: ^3.10.8
    printing: ^5.11.1
    path_provider: ^2.1.2
    qr_flutter: ^4.1.0
    mobile_scanner: ^5.2.1
    permission_handler: ^11.3.1
    cupertino_icons: ^1.0.6
    firebase_core: ^3.10.1
    firebase_auth: ^5.4.1
    cloud_firestore: ^5.6.2


# 📁 Project Architecture
lib/
├── main.dart                       # Entry point & app initialization
├── firebase_options.dart           # Auto-generated Firebase configurations
├── welcome_screen.dart             # Onboarding & logo landing page
├── login_screen.dart               # Role-based portal access & sign-in
├── signup_screen.dart              # Student registration interface
├── forgot_password_screen.dart     # Password recovery interface
├── admin_dashboard.dart            # Admin control panel
├── otp_generator_screen.dart       # Class session OTP & countdown timer
├── admin_qr.dart                   # Dynamic session QR code generation
├── view_students.dart              # Registered students list view
├── attendance_log_screen.dart      # Real-time and date-filtered attendance logs
├── settings_screen.dart            # Schedule, Wi-Fi SSID, and geofence radius settings
├── report_screen.dart              # Analytics pie charts & PDF report exporter
├── student_dashboard.dart          # Student check-in hub & multi-check validator
├── student_otp_screen.dart         # OTP entrance screen & device binding
└── studentscanqr_screen.dart       # In-app camera QR scanner for check-ins
