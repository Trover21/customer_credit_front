import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_text_field.dart';
import '../../services/auth_service.dart';
import '../../utils/error_handler.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isSent = false;

  Future<void> _handleSendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await _authService.forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _isSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset code sent to your email!'), backgroundColor: kPrimaryGreen),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    if (code.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the reset code and new password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await _authService.resetPassword(email, code, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful! Please login.'), backgroundColor: kPrimaryGreen),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
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
          onPressed: () => Navigator.pop(context),
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
                Icon(
                  Icons.lock_reset_rounded,
                  size: 100,
                  color: kPrimaryGreen.withAlpha(204),
                ),
                const SizedBox(height: 24),
                Text(
                  'Reset Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : kSlate900,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isSent 
                    ? 'Enter the 6-digit code we sent to your email, and choose a new password.'
                    : 'Enter the email associated with your account and we\'ll send an email with instructions to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? kSlate400 : kSlate500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                
                if (!_isSent) ...[
                  AuthTextField(
                    label: 'Email Address',
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendEmail,
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
                            'Send Reset Link',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ] else ...[
                  AuthTextField(
                    label: 'Reset Code',
                    hint: 'Enter 6-digit code',
                    icon: Icons.pin_outlined,
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'New Password',
                    hint: 'Enter your new password',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    isPassword: true,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
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
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 16,
                        color: kPrimaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
