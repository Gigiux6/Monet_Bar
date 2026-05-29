import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_bar_logo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'IMPOSTAZIONI',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textCream,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: const [
          AppBarLogo(),
        ],
      ),
      body: Center(
        child: Text(
          'Sezione Impostazioni in arrivo...',
          style: GoogleFonts.outfit(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
