import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hover_widget.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});
  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final itemController = TextEditingController();
  final qtyController = TextEditingController();
  final priceController = TextEditingController();
  final paymentController = TextEditingController();
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  bool _showDeletedTransactions = false;

  // ሓዱሽ ዕዳ ምውሳኽ
  void _addItem() async {
    String item = itemController.text.trim();
    int qty = int.tryParse(qtyController.text) ?? 0;
    double price = double.tryParse(priceController.text) ?? 0.0;
    double totalCost = qty * price;

    if (item.isEmpty || qty <= 0 || price <= 0) return;

    if (widget.customer.totalCredit + totalCost >
        widget.customer.maxCreditLimit) {
      _showLimitAlert(totalCost);
      return;
    }

    try {
      final tx = TransactionModel(
        item: item,
        qty: qty,
        price: price,
        total: totalCost,
        isPayment: false,
        date: DateTime.now(),
      );

      // Server returns saved transaction with MongoDB _id
      final savedTx = await _apiService.addItem(customerId: widget.customer.id, tx: tx);

      setState(() {
        widget.customer.totalCredit += totalCost;
        widget.customer.transactions.insert(0, savedTx);
      });

      itemController.clear();
      qtyController.clear();
      priceController.clear();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ዕዳ ብትኽክል ተወሲኹ ኣሎ።"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ዕዳ ንምውሳኽ ጌጋ ኣጋጢሙ: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ክፍሊት ምቕባል
  void _makePayment() async {
    double amount = double.tryParse(paymentController.text) ?? 0.0;

    if (amount <= 0 || amount > widget.customer.totalCredit) {
      return;
    }

    // 1. Transaction object create
    final tx = TransactionModel(
      item: "ክፍሊት ተፈጺሙ",
      qty: 1,
      price: amount,
      total: amount,
      isPayment: true,
      date: DateTime.now(),
    );

    try {
      // 2. Save to database — returns saved transaction with _id
      final savedTx = await _apiService.makePayment(customerId: widget.customer.id, tx: tx);

      // 3. Update UI
      setState(() {
        widget.customer.totalCredit -= amount;
        widget.customer.transactions.insert(0, savedTx);
      });

      // 4. Notification message
      String message =
          "✅ **ናይ ክፍሊት መረጋገጺ**\n\n"
          "ክቡር/ቲ *${widget.customer.name}*፡\n"
          "ዝገበርካዮ ክፍሊት *${amount.toStringAsFixed(2)} ብር* "
          "ብሰላም ተቐቢልና ኣለና。\n"
          "📉 ዝተረፈካ ጠቕላላ ዕዳ: "
          "*${widget.customer.totalCredit.toStringAsFixed(2)} ብር* እዩ።\n"
          "የቐንየልና!";

      _notificationService.send(
        message: message,
        phone: widget.customer.phone,
        chatId: widget.customer.telegramChatId,
      );

      paymentController.clear();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ክፍሊት ብትኽክል ተፈጺሙ ኣሎ።"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Payment failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ክፍሊት ንምፍጻም ጌጋ ኣጋጢሙ: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLimitAlert(double attemptedCost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ዕዳ ሓሊፉ!',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'እዚ ዓሚል ዝሓተቶ መጠን (${attemptedCost.toStringAsFixed(2)} ብር) ካብ ናቱ ፍሉይ ናይ ዕዳ ደረት (${widget.customer.maxCreditLimit.toStringAsFixed(0)} ብር) ይበልጽ ኣሎ። ❌ ቅድም ዕዳኡ ክኸፈል ኣለዎ!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ተረዲኡኒ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double remainingLimit =
        widget.customer.maxCreditLimit - widget.customer.totalCredit;
    double percentage = widget.customer.maxCreditLimit > 0
        ? (widget.customer.totalCredit / widget.customer.maxCreditLimit)
        : 0.0;
    bool isWarning = percentage >= 0.85;
    
    Color statusColor = isWarning
        ? kCoral500
        : (percentage >= 0.5 
            ? kAmber500
            : kEmerald500);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customer.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // 1. Credit Status Card
            Card(
              elevation: 4,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isWarning ? kCoral500.withAlpha(77) : theme.dividerColor,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ጠቕላላ ዕዳ",
                              style: TextStyle(color: kSlate500, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${widget.customer.totalCredit.toStringAsFixed(2)} ብር",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "ናቱ ደረት",
                              style: TextStyle(color: kSlate500, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${widget.customer.maxCreditLimit.toStringAsFixed(0)} ብር",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percentage.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: theme.scaffoldBackgroundColor,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isWarning ? Icons.warning : Icons.check_circle,
                              color: statusColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isWarning ? "ደረት ዕዳ ሓሊፉ ኣሎ!" : "ኩነታት ዕዳ ደሓን እዩ",
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "ዝተረፈ ዕድል: ${remainingLimit.toStringAsFixed(2)} ብር",
                          style: TextStyle(
                            color: remainingLimit <= 0 ? kCoral500 : (theme.textTheme.bodyMedium?.color ?? kSlate400),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Styled Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddItemDialog(),
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                    label: const Text("ዕዳ ወስኽ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPaymentDialog(),
                    icon: const Icon(Icons.price_check, color: Colors.white),
                    label: const Text("ክፍሊት ኣጉድል", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kEmerald500,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Transactions List Header with Tab Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ናይ ሒሳብ ምንቅስቓስ ታሪክ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                // Tab toggle buttons
                Container(
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showDeletedTransactions = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: !_showDeletedTransactions ? kPrimaryGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ንጡፍ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: !_showDeletedTransactions ? Colors.white : (theme.textTheme.bodyMedium?.color ?? kSlate400),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showDeletedTransactions = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _showDeletedTransactions ? kCoral500 : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'ዝተሰረዙ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _showDeletedTransactions ? Colors.white : (theme.textTheme.bodyMedium?.color ?? kSlate400),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _showDeletedTransactions ? Colors.white.withAlpha(60) : theme.scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${widget.customer.transactions.where((tx) => tx.isDeleted).length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _showDeletedTransactions ? Colors.white : kCoral500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: theme.dividerColor),

            // 4. Expanded Transactions List (Active or Deleted)
            Expanded(
              child: _showDeletedTransactions
                  ? _buildDeletedTransactionsList(theme)
                  : _buildActiveTransactionsList(theme),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Active Transactions ----
  Widget _buildActiveTransactionsList(ThemeData theme) {
    final activeTransactions =
        widget.customer.transactions.where((tx) => !tx.isDeleted).toList();
    if (activeTransactions.isEmpty) {
      return const Center(
        child: Text(
          "ናይ ሒሳብ ምንቅስቓስ ታሪክ ባዶ እዩ።",
          style: TextStyle(color: kSlate500, fontSize: 15),
        ),
      );
    }
    return ListView.builder(
      itemCount: activeTransactions.length,
      itemBuilder: (context, index) {
        final tx = activeTransactions[index];
        final time = DateFormat('MMM dd, hh:mm a').format(tx.date);
        return HoverWidget(
          child: Card(
            color: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.dividerColor, width: 0.8),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: tx.isPayment
                    ? kEmerald500.withAlpha(38)
                    : kCoral500.withAlpha(38),
                child: Icon(
                  tx.isPayment ? Icons.arrow_downward : Icons.shopping_cart,
                  color: tx.isPayment ? kEmerald500 : kCoral500,
                ),
              ),
              title: Text(
                tx.item,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              subtitle: Text(
                '$time${tx.qty > 0 ? " | ብዝሒ: ${tx.qty}" : ""}',
                style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color ?? kSlate400,
                    fontSize: 13),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tx.isPayment ? "-" : "+"}${tx.total.toStringAsFixed(2)} ብር',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: tx.isPayment ? kEmerald500 : kCoral500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFEF4444), size: 20),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('መረጋገጺ'),
                          content: Text(
                            'እዚ ሒሳብ ምንቅስቓስ ብሓቂ ክትሰርዞ ትደሊ ዲኻ?\n\n'
                            'ንጥፈት: ${tx.item}\n'
                            'መጠን: ${tx.total.toStringAsFixed(2)} ብር',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('ኣይፋል',
                                  style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: kCoral500),
                              onPressed: () async {
                                if (tx.id == null) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "ጌጋ፡ ናይ ሒሳብ ምንቅስቓስ ID ኣይተረኽበን።"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  await _apiService.deleteTransaction(
                                    customerId: widget.customer.id,
                                    transactionId: tx.id!,
                                  );
                                  setState(() {
                                    if (tx.isPayment) {
                                      widget.customer.totalCredit += tx.total;
                                    } else {
                                      widget.customer.totalCredit -= tx.total;
                                    }
                                    final idx = widget.customer.transactions
                                        .indexWhere((t) => t.id == tx.id);
                                    if (idx != -1) {
                                      widget.customer.transactions[idx] =
                                          TransactionModel(
                                        id: tx.id,
                                        item: tx.item,
                                        qty: tx.qty,
                                        price: tx.price,
                                        total: tx.total,
                                        isPayment: tx.isPayment,
                                        date: tx.date,
                                        isDeleted: true,
                                      );
                                    }
                                  });
                                  Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "ሒሳብ ምንቅስቓስ ብትኽክል ተሰሪዙ ኣሎ።"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "ሒሳብ ምንቅስቓስ ንምስራዝ ጌጋ ኣጋጢሙ: $e"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('እወ፣ ሰርዞ',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- Deleted Transactions ----
  Widget _buildDeletedTransactionsList(ThemeData theme) {
    final deletedTxList =
        widget.customer.transactions.where((tx) => tx.isDeleted).toList();
    if (deletedTxList.isEmpty) {
      return const Center(
        child: Text(
          "ዝተሰረዙ ምንቅስቓሳት የለዉን።",
          style: TextStyle(color: kSlate500, fontSize: 15),
        ),
      );
    }
    return ListView.builder(
      itemCount: deletedTxList.length,
      itemBuilder: (context, index) {
        final tx = deletedTxList[index];
        final time = DateFormat('MMM dd, hh:mm a').format(tx.date);
        return HoverWidget(
          child: Card(
            color: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: kCoral500.withAlpha(60), width: 0.8),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: tx.isPayment
                    ? kEmerald500.withAlpha(20)
                    : kCoral500.withAlpha(20),
                child: Icon(
                  tx.isPayment ? Icons.arrow_downward : Icons.shopping_cart,
                  color: tx.isPayment
                      ? kEmerald500.withAlpha(120)
                      : kCoral500.withAlpha(120),
                  size: 18,
                ),
              ),
              title: Text(
                tx.item,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color?.withAlpha(160),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: kCoral500.withAlpha(140),
                ),
              ),
              subtitle: Text(
                time,
                style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color ?? kSlate400,
                    fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tx.isPayment ? "-" : "+"}${tx.total.toStringAsFixed(2)} ብር',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: (tx.isPayment ? kEmerald500 : kCoral500)
                          .withAlpha(160),
                    ),
                  ),
                  // Restore button
                  IconButton(
                    tooltip: 'መልስ (Restore)',
                    icon: const Icon(Icons.restore_from_trash,
                        color: Color(0xFF60A5FA), size: 20),
                    onPressed: () async {
                      if (tx.id == null) return;
                      try {
                        await _apiService.restoreTransaction(
                          customerId: widget.customer.id,
                          transactionId: tx.id!,
                        );
                        setState(() {
                          if (tx.isPayment) {
                            widget.customer.totalCredit -= tx.total;
                          } else {
                            widget.customer.totalCredit += tx.total;
                          }
                          final idx = widget.customer.transactions
                              .indexWhere((t) => t.id == tx.id);
                          if (idx != -1) {
                            widget.customer.transactions[idx] =
                                TransactionModel(
                              id: tx.id,
                              item: tx.item,
                              qty: tx.qty,
                              price: tx.price,
                              total: tx.total,
                              isPayment: tx.isPayment,
                              date: tx.date,
                              isDeleted: false,
                            );
                          }
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("ሒሳብ ምንቅስቓስ ብትኽክል ተመሊሱ ኣሎ።"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("ጌጋ ክንመልስ ከለና: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  // Permanent delete button
                  IconButton(
                    tooltip: 'ንሓዋሩ ሰርዝ',
                    icon: const Icon(Icons.delete_forever,
                        color: Color(0xFFF87171), size: 20),
                    onPressed: () async {
                      if (tx.id == null) return;
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('መረጋገጺ'),
                          content: const Text(
                              'እዚ ሒሳብ ምንቅስቓስ ንሓዋሩ ክድምሰስ እዩ!\nእዚ ስጉምቲ ንድሕሪት ክምለስ ኣይክእልን እዩ።'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('ኣይፋል'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('እወ',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                      try {
                        await _apiService.permanentDeleteTransaction(
                          customerId: widget.customer.id,
                          transactionId: tx.id!,
                        );
                        setState(() {
                          widget.customer.transactions
                              .removeWhere((t) => t.id == tx.id);
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("ሒሳብ ምንቅስቓስ ንሓዋሩ ተሰሪዙ እዩ።"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "ጌጋ ንሓዋሩ ክንድምስስ ከለና: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  void _showAddItemDialog() {
    itemController.clear();
    qtyController.clear();
    priceController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.add_shopping_cart, color: kPrimaryGreen),
            SizedBox(width: 10),
            Text(
              'ዕዳ ምውሳኽ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: itemController,
              decoration: const InputDecoration(
                labelText: 'ስም ፍርያት',
                prefixIcon: Icon(Icons.shopping_bag, color: kSlate500),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ብዝሒ',
                prefixIcon: Icon(Icons.numbers, color: kSlate500),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ዋጋ (ነፍሲ-ወከፍ)',
                prefixIcon: Icon(Icons.attach_money, color: kSlate500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ሰርዝ', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: _addItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('ኣጽድቕ'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    paymentController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.payment, color: kEmerald500),
            SizedBox(width: 10),
            Text(
              'ክፍሊ ምቕባል',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: paymentController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'ገንዘብ መጠን',
            prefixIcon: Icon(Icons.attach_money, color: kSlate500),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ሰርዝ', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: _makePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: kEmerald500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('ክፍሊት ኣጉድል'),
          ),
        ],
      ),
    );
  }
}
