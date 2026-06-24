import 'transaction_model.dart';

class Customer {
  final String id;
  String name;
  String phone;
  final String telegramChatId;
  double maxCreditLimit;
  double totalCredit;
  List<TransactionModel> transactions;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.telegramChatId,
    required this.maxCreditLimit,
    this.totalCredit = 0.0,
    List<TransactionModel>? transactions,
  }) : transactions = transactions ?? [];

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      telegramChatId: json['telegramChatId'] ?? '0',
      maxCreditLimit: (json['maxCreditLimit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['totalCredit'] as num?)?.toDouble() ?? 0.0,
      transactions: (json['transactions'] ?? [])
          .map<TransactionModel>((e) => TransactionModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "phone": phone,
      "telegramChatId": telegramChatId,
      "maxCreditLimit": maxCreditLimit,
      "totalCredit": totalCredit,
      "transactions": transactions.map((e) => e.toJson()).toList(),
    };
  }

  void removeTransaction(TransactionModel tx) {
    if (tx.isPayment) {
      totalCredit += tx.total;
    } else {
      totalCredit -= tx.total;
    }

    transactions.remove(tx);
  }
}
