import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_text_field.dart';
import '../../services/auth_service.dart';
import '../../utils/error_handler.dart';
import '../main_dashboard_screen.dart';
import 'login_screen.dart';
import 'waiting_approval_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final data = await _authService.signUp(username, email, password);
      
      if (!mounted) return;

      if (data['role'] == 'pending') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()));
      } else {
        // Admin
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainDashboardScreen()));
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? kSlate900 : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : kSlate900),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : kSlate900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? kSlate400 : kSlate500,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Inputs
                AuthTextField(
                  label: 'Username',
                  hint: 'Choose a username',
                  icon: Icons.person_outline,
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  label: 'Email Address',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  label: 'Password',
                  hint: 'Create a password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_reset,
                  isPassword: true,
                  controller: _confirmPasswordController,
                ),
                
                const SizedBox(height: 40),
                
                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: kPrimaryGreen.withAlpha(128),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 32),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
                      style: TextStyle(
                        color: isDark ? kSlate400 : kSlate500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: kPrimaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
