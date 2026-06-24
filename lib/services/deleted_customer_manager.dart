import '../models/customer.dart';

class DeletedCustomerManager {
  // Singleton pattern
  DeletedCustomerManager._privateConstructor();
  static final DeletedCustomerManager _instance = DeletedCustomerManager._privateConstructor();
  factory DeletedCustomerManager() => _instance;

  final List<Customer> _deletedCustomers = [];

  // Soft delete a customer: mark as deleted and store in manager
  void softDelete(Customer customer) {
    // Ensure we don't duplicate
    if (!_deletedCustomers.any((c) => c.id == customer.id)) {
      customer.isDeleted = true;
      _deletedCustomers.add(customer);
    }
  }

  // Restore a previously deleted customer
  void restore(Customer customer) {
    _deletedCustomers.removeWhere((c) => c.id == customer.id);
    customer.isDeleted = false;
  }

  // Permanently delete a customer from the recycle bin
  void permanentDelete(Customer customer) {
    _deletedCustomers.removeWhere((c) => c.id == customer.id);
  }

  List<Customer> getDeletedCustomers() => List.unmodifiable(_deletedCustomers);
}
