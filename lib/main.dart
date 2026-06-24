import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/waiting_approval_screen.dart';
import 'services/auth_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kidu Credit',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  Widget _initialScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _authService.getToken();
    final role = await _authService.getRole();

    if (token != null && role != null) {
      if (role == 'pending') {
        _initialScreen = const WaitingApprovalScreen();
      } else {
        _initialScreen = const MainDashboardScreen();
      }
    } else {
      _initialScreen = const LoginScreen();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _initialScreen;
  }
}
