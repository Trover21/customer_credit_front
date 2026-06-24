// Global store for soft-deleted customers
import '../models/customer.dart';

class DeletedCustomers {
  static final List<Customer> list = [];

  static void add(Customer customer) => list.add(customer);
  static void remove(Customer customer) => list.remove(customer);
}
