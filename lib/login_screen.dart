import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard.dart';
import 'student_dashboard.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscured = true;
  bool _isLoading = false;
  bool _isLogin = true;
  String _selectedRole = 'Student';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    try {
      if (_isLogin) {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();

        if (userDoc.exists) {
          String actualRole = userDoc['role'];
          if (actualRole.toLowerCase() == _selectedRole.toLowerCase()) {
            _navigateToDashboard(actualRole);
          } else {
            _showError(
              "Access Denied: You are not registered as an $_selectedRole",
            );
            await FirebaseAuth.instance.signOut();
          }
        }
      } else {
        final existingUser =
            await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: email)
                .get();

        if (existingUser.docs.isNotEmpty) {
          _showError("This email is already registered to another student.");
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'uid': userCredential.user!.uid,
              'email': email,
              'name': name,
              'role': 'Student',
              'createdAt': FieldValue.serverTimestamp(),
            });

        _navigateToDashboard('Student');
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Authentication failed");
    } catch (e) {
      _showError("An unexpected error occurred");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard(String role) {
    Widget target =
        (role == 'Admin') ? const AdminDashboard() : const StudentDashboard();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => target),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: Colors.blueGrey),
      suffixIcon:
          isPassword
              ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              )
              : null,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF3B82F6),
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                "Smart Attendance",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                "University Portal Access",
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 30),
              if (_isLogin) ...[
                _buildLabel("SELECT YOUR ROLE"),
                ToggleButtons(
                  borderRadius: BorderRadius.circular(12),
                  fillColor: const Color(0xFF3B82F6),
                  selectedColor: Colors.white,
                  constraints: BoxConstraints(
                    minWidth: (MediaQuery.of(context).size.width - 60) / 2,
                    minHeight: 45,
                  ),
                  isSelected: [
                    _selectedRole == 'Student',
                    _selectedRole == 'Admin',
                  ],
                  onPressed:
                      (index) => setState(
                        () => _selectedRole = index == 0 ? 'Student' : 'Admin',
                      ),
                  children: const [Text("Student"), Text("Admin")],
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "Registering as a Student",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (!_isLogin) ...[
                _buildLabel("FULL NAME"),
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    hint: "John Doe",
                    icon: Icons.person_outline,
                  ),
                ),
              ],
              _buildLabel("EMAIL ADDRESS"),
              TextField(
                controller: _emailController,
                decoration: _inputDecoration(
                  hint: "name@university.edu",
                  icon: Icons.alternate_email,
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("PASSWORD"),
                  if (_isLogin)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              TextField(
                controller: _passwordController,
                obscureText: _isObscured,
                decoration: _inputDecoration(
                  hint: "••••••••",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleAuth,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isLogin ? "Sign In" : "Register Now"),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed:
                    () => setState(() {
                      _isLogin = !_isLogin;
                      if (!_isLogin) _selectedRole = 'Student';
                    }),
                child: Text(
                  _isLogin
                      ? "New user? Create an account"
                      : "Already have an account? Sign In",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
