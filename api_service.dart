import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../models/customer.dart';
import '../models/transaction_model.dart';

class ApiService {
  /// =====================================================
  /// ⚠️  ናይ ኮምፒዩተርካ IP Address ኣብዚ ቐይሮ!
  ///    (ipconfig ኣብ cmd ጸሓፍ ኣብ IPv4 Address ርኣዮ)
  /// =====================================================
  static const String _localIp = "172.31.232.19"; // ናይ ኮምፒዩተርካ IP

  /// Automatically selects the correct backend URL:
  /// - Web (Chrome/Edge):   http://localhost:3000
  /// - Android Emulator:    http://10.0.2.2:3000
  /// - Real Android Device: http://<your-pc-ip>:3000
  String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000";
    }
    // Android Emulator uses special alias 10.0.2.2
    // Real physical device needs the PC's actual LAN IP
    final bool isEmulator = defaultTargetPlatform == TargetPlatform.android &&
        const bool.fromEnvironment('dart.vm.product') == false &&
        _isEmulatorEnvironment();
    if (isEmulator) {
      return "http://10.0.2.2:3000";
    }
    return "http://$_localIp:3000";
  }

  /// Returns true when running inside an Android emulator.
  /// In release/APK builds this always returns false (real device).
  bool _isEmulatorEnvironment() {
    // Flutter debug mode on Android emulator sets ANDROID_EMULATOR env.
    // For a simple split: debug → emulator assumed, release → real device.
    return !const bool.fromEnvironment('dart.vm.product');
  }

  /* ==========================
      1. ADD CUSTOMER
  ========================== */
  Future<void> addCustomer(Customer customer) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-customer'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(customer.toJson()),
      );

      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");

      if (response.statusCode != 201) {
        throw Exception("Failed to add customer: ${response.body}");
      }
    } catch (e) {
      debugPrint("API ERROR: $e");
      rethrow;
    }
  }

  /* ==========================
      2. FETCH CUSTOMERS
  ========================== */
  Future<List<Customer>> fetchCustomers() async {
    final response = await http.get(Uri.parse('$baseUrl/customers'));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      return data.map((e) => Customer.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load customers");
    }
  }

  /* ==========================
      3. UPDATE CUSTOMER
  ========================== */
  Future<void> updateCustomer(Customer customer) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/update-customer/${customer.id}'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": customer.name,
        "phone": customer.phone,
        "telegramChatId": customer.telegramChatId,
        "maxCreditLimit": customer.maxCreditLimit,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update customer");
    }
  }

  /* ==========================
      4. DELETE CUSTOMER
  ========================== */
  Future<void> deleteCustomer(String customerId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete-customer/$customerId'),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete customer");
    }
  }

  /* ==========================
      5. ADD ITEM (DEBT)
  ========================== */
  Future<void> addItem({
    required String customerId,
    required TransactionModel tx,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-item/$customerId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(tx.toJson()),
    );

    debugPrint("STATUS CODE: ${response.statusCode}");
    debugPrint("BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to add item: ${response.body}");
    }
  }

  /* ==========================
      6. PAYMENT
  ========================== */
  Future<void> makePayment({
    required String customerId,
    required TransactionModel tx,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payment/$customerId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(tx.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to make payment");
    }
  }

  /* ==========================
      7. DELETE TRANSACTION
  ========================== */
  Future<void> deleteTransaction({
    required String customerId,
    required String transactionId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete-transaction/$customerId/$transactionId'),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete transaction");
    }
  }
}
