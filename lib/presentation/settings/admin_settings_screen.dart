import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_bar_logo.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Impostazioni',
          style: GoogleFonts.playfairDisplay(color: AppTheme.textCream, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.surfaceDark,
        centerTitle: true,
        actions: const [
          AppBarLogo(),
        ],
      ),
      body: Center(
        child: Text(
          'Impostazioni Admin in arrivo...',
          style: GoogleFonts.outfit(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
