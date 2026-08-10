import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/datasources/local_store.dart';

class StafScreen extends StatelessWidget {
  const StafScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocalStore.instance,
      builder: (context, _) {
        final store = LocalStore.instance;
        final isAdmin = store.currentUser?.role == 'admin';

        if (!isAdmin) {
          return const Center(
            child: Text(
              'Menu Staf hanya untuk Kepala Klinik (Admin)',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final users = store.users;

        return Scaffold(
          body: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (ctx, idx) {
              final u = users[idx];
              final isStaffAdmin = u.role == 'admin';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isStaffAdmin ? const Color(0xFFFFF1F2) : Colors.blue.shade50,
                    child: Icon(
                      isStaffAdmin ? LucideIcons.shieldCheck : LucideIcons.user,
                      color: isStaffAdmin ? const Color(0xFFF43F5E) : Colors.blue,
                    ),
                  ),
                  title: Text(
                    u.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Username: ${u.username} | Role: ${u.role.toUpperCase()}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
