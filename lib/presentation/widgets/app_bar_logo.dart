import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppBarLogo extends StatelessWidget {
  const AppBarLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Image.asset(
          'assets/logo.png',
          width: 38,
          height: 38,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.local_bar,
            color: AppTheme.accentGold,
            size: 24,
          ),
        ),
      ),
    );
  }
}
