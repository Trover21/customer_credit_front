import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'customer_list_screen.dart';
import 'recycle_bin_screen.dart';

class RecycleBinOverviewScreen extends StatelessWidget {
  const RecycleBinOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Recycle Bin Overview'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Row(
        children: [
          // Left side: active customers list
          Expanded(
            child: const CustomerListScreen(),
          ),
          // Right side: deleted customers
          Expanded(
            child: const RecycleBinScreen(),
          ),
        ],
      ),
    );
  }
}
