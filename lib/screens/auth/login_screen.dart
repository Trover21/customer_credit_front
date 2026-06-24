import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_text_field.dart';
import '../../services/auth_service.dart';
import '../../utils/error_handler.dart';
import '../main_dashboard_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'waiting_approval_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final data = await _authService.login(username, password);
      
      if (!mounted) return;

      if (data['role'] == 'pending') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WaitingApprovalScreen()));
      } else {
        // Admin or Approved
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo or Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 80,
                    color: kPrimaryGreen,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Welcome Text
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : kSlate900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to access your customer data',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? kSlate400 : kSlate500,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Inputs
                AuthTextField(
                  label: 'Username',
                  hint: 'Enter your username',
                  icon: Icons.person_outline,
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  controller: _passwordController,
                ),
                
                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: kPrimaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 32),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: isDark ? kSlate400 : kSlate500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                      },
                      child: const Text(
                        'Sign Up',
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
