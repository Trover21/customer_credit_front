class TransactionModel {
  final String? id;
  final String item;
  final int qty;
  final double price;
  final double total;
  final bool isPayment;
  final DateTime date;

  TransactionModel({
    this.id,
    required this.item,
    required this.qty,
    required this.price,
    required this.total,
    required this.isPayment,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'],
      item: json['item'] ?? '',
      qty: json['qty'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      isPayment: json['isPayment'] ?? false,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) "_id": id,
      "item": item,
      "qty": qty,
      "price": price,
      "total": total,
      "isPayment": isPayment,
      "date": date.toIso8601String(),
    };
  }
}
