import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'home/home_screen.dart';
import 'menu/menu_screen.dart';
import 'fidelity/fidelity_screen.dart';
import 'rewards/rewards_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    HomeScreen(onGoToRewards: () => _onItemTapped(3)),
    const MenuScreen(),
    const FidelityScreen(),
    const RewardsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.accentGold.withOpacity(0.15),
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: AppTheme.surfaceDark,
          selectedItemColor: AppTheme.accentGold,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, color: AppTheme.accentGold),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu, color: AppTheme.accentGold),
              label: 'Menù',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_pin_outlined),
              activeIcon: Icon(Icons.person_pin, color: AppTheme.accentGold),
              label: 'Profilo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events, color: AppTheme.accentGold),
              label: 'Premi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings, color: AppTheme.accentGold),
              label: 'Impostazioni',
            ),
          ],
        ),
      ),
    );
  }
}
