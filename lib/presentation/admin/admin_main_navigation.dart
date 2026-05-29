import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_menu_settings_screen.dart';
import 'admin_news_screen.dart';

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({super.key});

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int _currentIndex = 0;

    final List<Widget> _pages = [
    const AdminDashboardScreen(),
    const AdminMenuSettingsScreen(),
    const AdminNewsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.surfaceDark,
        selectedItemColor: AppTheme.accentGold,
        unselectedItemColor: AppTheme.textSecondary,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Cassa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign),
            label: 'Novità',
          ),
        ],
      ),
    );
  }
}
