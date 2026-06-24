import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/deleted_customer_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/hover_widget.dart';

import '../services/api_service.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  final ApiService api = ApiService();
  List<Customer> _deletedCustomers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeleted();
  }

  Future<void> _loadDeleted() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetched = await api.fetchCustomers();
      final deleted = fetched.where((c) => c.isDeleted).toList();
      setState(() {
        _deletedCustomers = deleted;
      });
    } catch (e) {
      debugPrint("Error loading deleted customers: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ጌጋ ክንጽዕን ከለና: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _restoreCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: const Text('Are you sure you want to restore this customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      customer.isDeleted = false;
      await api.updateCustomer(customer);
      DeletedCustomerManager().restore(customer);
      _loadDeleted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ዓሚል ብትኽክል ተመሊሱ ኣሎ።"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error restoring customer: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _permanentDelete(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Permanent Deletion'),
        content: const Text('This action cannot be undone. Delete this customer permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await api.permanentDeleteCustomer(customer.id);
      DeletedCustomerManager().permanentDelete(customer);
      _loadDeleted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ዓሚል ንሓዋሩ ተሰሪዙ ኣሎ!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting customer: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text(
              'List Of Deleted Customers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _deletedCustomers.isEmpty
                    ? const Center(
                        child: Text(
                          "No deleted customers found.",
                          style: TextStyle(color: kSlate500, fontSize: 16),
                        ),
                      )
                : ListView.builder(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _deletedCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _deletedCustomers[index];
                      return HoverWidget(
                        hoverColor: kPrimaryGreen.withAlpha(20),
                        child: Card(
                          elevation: 2,
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: theme.dividerColor, width: 1),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      style: TextStyle(
                                        color: theme.textTheme.bodyLarge?.color,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 14, color: kSlate500),
                                        const SizedBox(width: 6),
                                        Text(
                                          customer.phone,
                                          style: TextStyle(
                                            color: theme.textTheme.bodyMedium?.color ?? kSlate400,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Restore',
                                      icon: const Icon(Icons.restore_from_trash, color: Color(0xFF60A5FA)),
                                      onPressed: () => _restoreCustomer(customer),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete Forever',
                                      icon: const Icon(Icons.delete_forever, color: Color(0xFFF87171)),
                                      onPressed: () => _permanentDelete(customer),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
