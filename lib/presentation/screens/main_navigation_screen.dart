import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app_config.dart';
import '../../data/datasources/local_store.dart';
import 'dashboard_screen.dart';
import 'anak_screen.dart';
import 'program_screen.dart';
import 'riwayat_screen.dart';
import 'staf_screen.dart';
import 'settings_dialog.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocalStore.instance,
      builder: (context, _) {
        final store = LocalStore.instance;
        final currentUser = store.currentUser;
        final isAdmin = currentUser?.role == 'admin';

        final List<Widget> screens = [
          const DashboardScreen(),
          const AnakScreen(),
          const ProgramScreen(),
          const RiwayatScreen(),
          if (isAdmin) const StafScreen(),
        ];

        final List<BottomNavigationBarItem> navItems = [
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            activeIcon: Icon(LucideIcons.layoutDashboard),
            label: 'Beranda',
          ),
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            activeIcon: Icon(LucideIcons.user),
            label: 'Anak',
          ),
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.clipboardList),
            activeIcon: Icon(LucideIcons.clipboardList),
            label: 'Program',
          ),
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.history),
            activeIcon: Icon(LucideIcons.history),
            label: 'Riwayat',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(LucideIcons.users),
              activeIcon: Icon(LucideIcons.users),
              label: 'Staf',
            ),
        ];

        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 16,
                  child: Image.asset('assets/icon.png', width: 32, height: 32),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            AppConfig.appName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFBE123C),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (store.pendingSyncCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'Pending (${store.pendingSyncCount})',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        currentUser?.role == 'admin'
                            ? 'Admin: ${currentUser?.name}'
                            : 'Terapis: ${currentUser?.name}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.settings, color: Color(0xFFBE123C)),
                onPressed: () => SettingsDialog.show(context),
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (idx) => setState(() => _currentIndex = idx),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFF43F5E),
            unselectedItemColor: Colors.grey,
            items: navItems,
          ),
        );
      },
    );
  }
}
