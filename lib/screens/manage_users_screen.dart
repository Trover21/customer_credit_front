import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _authService = AuthService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _authService.fetchUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      await _authService.updateUserRole(userId, newRole);
      _fetchUsers(); // Refresh the list
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User updated to $newRole successfully!'), backgroundColor: kPrimaryGreen),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: kCoral500),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Manage Users",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Approve or revoke access for new users.",
            style: TextStyle(
              color: isDark ? kSlate400 : kSlate500,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _users.isEmpty
                ? Center(
                    child: Text(
                      "No users found.",
                      style: TextStyle(color: isDark ? kSlate400 : kSlate500),
                    ),
                  )
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isPending = user['role'] == 'pending';
                      final isAdmin = user['role'] == 'admin';

                      return Card(
                        color: theme.cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.dividerColor, width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: isPending ? kCoral500.withAlpha(51) : kPrimaryGreen.withAlpha(51),
                            child: Icon(
                              isPending ? Icons.hourglass_empty : (isAdmin ? Icons.admin_panel_settings : Icons.check),
                              color: isPending ? kCoral500 : kPrimaryGreen,
                            ),
                          ),
                          title: Text(
                            user['username'] ?? 'No Username',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['email'] ?? 'No Email', style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Role: ${user['role']}'),
                            ],
                          ),
                          trailing: isAdmin
                              ? const Text("Admin", style: TextStyle(fontWeight: FontWeight.bold, color: kSlate400))
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPending)
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimaryGreen,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () => _updateRole(user['_id'], 'approved'),
                                        child: const Text('Approve'),
                                      ),
                                    if (!isPending)
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: kCoral500,
                                          side: const BorderSide(color: kCoral500),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () => _updateRole(user['_id'], 'pending'),
                                        child: const Text('Revoke'),
                                      ),
                                  ],
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
