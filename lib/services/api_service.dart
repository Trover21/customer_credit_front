import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/customer.dart';
import '../models/transaction_model.dart';

class ApiService {
  static const String _dartDefineUrl =String.fromEnvironment('BACKEND_URL');

  static const String _productionUrl ="https://customer-credit-front-3.onrender.com";
 String get baseUrl {
  if (_dartDefineUrl.isNotEmpty) {
    return _dartDefineUrl;
  }

  return _productionUrl;
}

  /// Helper method to construct headers with JWT
  Future<Map<String, String>> _getHeaders() async {
    String? token;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');
    } else {
      const storage = FlutterSecureStorage();
      token = await storage.read(key: 'auth_token');
    }
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  /* ==========================
      1. ADD CUSTOMER
  ========================== */
  Future<void> addCustomer(Customer customer) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-customer'),
        headers: await _getHeaders(),
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
    final response = await http.get(
      Uri.parse('$baseUrl/customers'),
      headers: await _getHeaders(),
    );

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
      headers: await _getHeaders(),
      body: jsonEncode({
        "name": customer.name,
        "phone": customer.phone,
        "telegramChatId": customer.telegramChatId,
        "maxCreditLimit": customer.maxCreditLimit,
        "isDeleted": customer.isDeleted,
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
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete customer");
    }
  }

  /* ==========================
      4.1 PERMANENT DELETE CUSTOMER
  ========================== */
  Future<void> permanentDeleteCustomer(String customerId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/permanent-delete-customer/$customerId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to permanently delete customer");
    }
  }

  /* ==========================
      5. ADD ITEM (DEBT)
  ========================== */
  Future<TransactionModel> addItem({
    required String customerId,
    required TransactionModel tx,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-item/$customerId'),
      headers: await _getHeaders(),
      body: jsonEncode(tx.toJson()),
    );

    debugPrint("STATUS CODE: ${response.statusCode}");
    debugPrint("BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to add item: ${response.body}");
    }

    // Server returns the full customer — pick the first transaction (most recent)
    final data = jsonDecode(response.body);
    final txList = data['transactions'] as List;
    return TransactionModel.fromJson(txList.first);
  }

  /* ==========================
      6. PAYMENT
  ========================== */
  Future<TransactionModel> makePayment({
    required String customerId,
    required TransactionModel tx,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payment/$customerId'),
      headers: await _getHeaders(),
      body: jsonEncode(tx.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to make payment");
    }

    // Server returns the full customer — pick the first transaction (most recent)
    final data = jsonDecode(response.body);
    final txList = data['transactions'] as List;
    return TransactionModel.fromJson(txList.first);
  }

  /* ==========================
      7. DELETE TRANSACTION (SOFT DELETE)
  ========================== */
  Future<void> deleteTransaction({
    required String customerId,
    required String transactionId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete-transaction/$customerId/$transactionId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete transaction");
    }
  }

  /* ==========================
      7.1 RESTORE TRANSACTION
  ========================== */
  Future<void> restoreTransaction({
    required String customerId,
    required String transactionId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/restore-transaction/$customerId/$transactionId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to restore transaction");
    }
  }

  /* ==========================
      7.2 PERMANENT DELETE TRANSACTION
  ========================== */
  Future<void> permanentDeleteTransaction({
    required String customerId,
    required String transactionId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/permanent-delete-transaction/$customerId/$transactionId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to permanently delete transaction");
    }
  }
}
