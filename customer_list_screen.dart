import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/hover_widget.dart';
import 'customer_detail_screen.dart';

// --- CustomerListScreen (ምሉእ ብምሉእ ዝተመሓየሸ) ---
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});
  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final ApiService api = ApiService();
  List<Customer> _allCustomers = [];
  List<Customer> _foundCustomers = [];
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _runFilter(String keyword) {
    setState(() {
      _foundCustomers = _allCustomers
          .where((c) => c.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    });
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetched = await api.fetchCustomers();
      setState(() {
        _allCustomers = fetched;
        _foundCustomers = fetched;
      });
    } catch (e) {
      debugPrint("Error loading customers: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ዓማዊል ንምጽዓን ጌጋ ኣጋጢሙ: $e"),
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

  void _confirmDelete(Customer customer) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ዓሚል ክትሰርዝ ዲኻ?'),
        content: Text('${customer.name} ክትሰርዞ ኢኻ፣ እዚ ተግባር ድሕሪ ሕጂ ኣይተዐረን።'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ኣይፋል', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kCoral500),
            onPressed: () async {
              try {
                await api.deleteCustomer(customer.id);
                Navigator.pop(ctx);
                _loadCustomers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("ዓሚል ብትኽክል ተሰሪዙ ኣሎ።"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("ዓሚል ንምስራዝ ጌጋ ኣጋጢሙ: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('እወ፣ ሰርዞ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Customer customer) {
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _limitController.text = customer.maxCreditLimit.toString();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ሓበሬታ ዓሚል ኣመሓይሽ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'ስም'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'ስልኪ'),
            ),
            TextField(
              controller: _limitController,
              decoration: const InputDecoration(labelText: 'ደረት ዕዳ'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ሰርዝ', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = _nameController.text.trim();
              final newPhone = _phoneController.text.trim();
              final newLimit = double.tryParse(_limitController.text.trim()) ?? customer.maxCreditLimit;

              if (newName.isEmpty || newPhone.isEmpty) return;

              try {
                final updated = Customer(
                  id: customer.id,
                  name: newName,
                  phone: newPhone,
                  telegramChatId: customer.telegramChatId,
                  maxCreditLimit: newLimit,
                  totalCredit: customer.totalCredit,
                  transactions: customer.transactions,
                );
                await api.updateCustomer(updated);
                Navigator.pop(ctx);
                _loadCustomers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("ሓበሬታ ዓሚል ተመሓይሹ ኣሎ።"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("ሓበሬታ ንምምሕያሽ ጌጋ ኣጋጢሙ: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('ኣመሓይሽ'),
          ),
        ],
      ),
    );
  }

  double get _totalAllDebts {
    return _foundCustomers.fold(0.0, (sum, item) => sum + item.totalCredit);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate statistics
    final double totalDebt = _totalAllDebts;
    final int totalCount = _allCustomers.length;
    final int warnedCount = _allCustomers.where((c) => c.totalCredit >= c.maxCreditLimit * 0.9).length;
    final theme = Theme.of(context);

    // No Appbar here because it will sit inside the Dashboard Screen
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits container's scaffold background
      body: Column(
        children: [
          // 1. Dashboard Statistics Cards
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  StatCard(
                    title: "ዕዳ ኩሎም ዓማዊል",
                    value: "${totalDebt.toStringAsFixed(0)} ብር",
                    icon: Icons.account_balance_wallet,
                    accentColor: kCoral500,
                  ),
                  const SizedBox(width: 12),
                  StatCard(
                    title: "በዝሒ ዓማዊል",
                    value: "$totalCount",
                    icon: Icons.people_alt,
                    accentColor: kPrimaryGreen,
                  ),
                  const SizedBox(width: 12),
                  StatCard(
                    title: "ናብ ደረት ዕዳ ዝቀረቡ ",
                    value: "$warnedCount",
                    icon: Icons.warning_amber_rounded,
                    accentColor: kAmber500,
                  ),
                ],
              ),
            ),
          ),

          // 2. Premium Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'ዓሚል ብስም ድለ...',
                hintStyle: const TextStyle(color: kSlate500),
                prefixIcon: const Icon(Icons.search, color: kSlate500),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.dividerColor, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kPrimaryGreen, width: 1.5),
                ),
              ),
              onChanged: (value) {
                _runFilter(value);
              },
            ),
          ),

          // 3. Expanded Customer List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryGreen),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCustomers,
                    color: kPrimaryGreen,
                    backgroundColor: theme.cardColor,
                    child: _foundCustomers.isEmpty
                        ? const Center(
                            child: Text(
                              "ዝተረኽበ ዓሚል የለን።",
                              style: TextStyle(color: kSlate500, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12.0),
                            itemCount: _foundCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = _foundCustomers[index];
                              
                              // Calculate credit percentages for colors
                              double percentage = customer.maxCreditLimit > 0 
                                  ? (customer.totalCredit / customer.maxCreditLimit) 
                                  : 0.0;
                              Color progressColor = percentage >= 0.85
                                  ? kCoral500
                                  : (percentage >= 0.5 
                                      ? kAmber500
                                      : kEmerald500);
                              
                              return HoverWidget(
                                child: Card(
                                  elevation: 2,
                                  color: theme.cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: percentage >= 0.85 
                                          ? kCoral500.withOpacity(0.3) 
                                          : theme.dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
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
                                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF60A5FA)),
                                                  onPressed: () => _showEditDialog(customer),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFF87171)),
                                                  onPressed: () => _confirmDelete(customer),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "ዕዳ: ${customer.totalCredit.toStringAsFixed(2)} ብር",
                                              style: TextStyle(
                                                color: progressColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              "ደረት: ${customer.maxCreditLimit.toStringAsFixed(0)} ብር",
                                              style: TextStyle(
                                                color: theme.textTheme.bodyMedium?.color ?? kSlate400,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: percentage.clamp(0.0, 1.0),
                                            minHeight: 8,
                                            backgroundColor: theme.scaffoldBackgroundColor,
                                            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (ctx) =>
                                                      CustomerDetailScreen(customer: customer),
                                                ),
                                              );
                                              _loadCustomers();
                                            },
                                            icon: const Icon(Icons.receipt_long, size: 16, color: kPrimaryGreen),
                                            label: const Text(
                                              "ታሪኽ ሒሳብ ርአ",
                                              style: TextStyle(
                                                color: kPrimaryGreen,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterDialog(),
        label: const Text(
          'ሓዱሽ ዓሚል ወሰክ',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
        ),
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        foregroundColor: Colors.white,
        backgroundColor: kPrimaryGreen,
      ),
    );
  }

  // Register Dialog
  void _showRegisterDialog() {
    _nameController.clear();
    _phoneController.clear();
    _limitController.clear();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ሓዱሽ ዓሚል መዝግብ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'ስም ዓሚል'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'ቁጽሪ ስልኪ'),
            ),
            TextField(
              controller: _limitController,
              decoration: const InputDecoration(labelText: 'ናይ ዕዳ ደረት (ብር)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ሰርዝ', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final phone = _phoneController.text.trim();
              final limit = double.tryParse(_limitController.text.trim()) ?? 0.0;

              if (name.isEmpty || phone.isEmpty) return;

              try {
                final newCustomer = Customer(
                  id: '',
                  name: name,
                  phone: phone,
                  telegramChatId: "0",
                  maxCreditLimit: limit,
                );
                await api.addCustomer(newCustomer);
                Navigator.pop(ctx);
                _loadCustomers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("ሓዱሽ ዓሚል ብትኽክል ተመዝጊቡ ኣሎ።"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("ዓሚል ንምምዝጋብ ጌጋ ኣጋጢሙ: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('መዝግብ'),
          ),
        ],
      ),
    );
  }
}
