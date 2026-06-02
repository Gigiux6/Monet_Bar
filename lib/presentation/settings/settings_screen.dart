import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // SEZIONE ACCOUNT
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.delete_forever,
            title: 'Elimina Account',
            subtitle: 'Richiede la rimozione definitiva dei dati',
            iconColor: Colors.redAccent,
            titleColor: Colors.redAccent,
            onTap: () => _handleDeleteAccount(context),
          ),
          const SizedBox(height: 24),

          // SEZIONE INFORMAZIONI E LEGALE
          _buildSectionHeader('Informazioni e Legale'),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Privacy Policy',
            onTap: () {
              // TODO: Aprire url policy
            },
          ),
          _buildSettingsTile(
            icon: Icons.gavel,
            title: 'Note Legali e Licenze Open Source',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Monet Bar',
                applicationVersion: '1.0.0',
                applicationIcon: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                applicationLegalese: '© 2024 Monet Bar.\nTutti i diritti riservati.\n\nSviluppata da Gigiux6.\n\nFont "Playfair Display" e "Outfit" concessi in licenza tramite Google Fonts (SIL Open Font License).\nIcone Material e Cupertino concesse in licenza da Google LLC e Apple Inc.',
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Versione App 1.0.0',
              style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          color: AppTheme.accentGold,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.glassCard(),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppTheme.textCream),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: titleColor ?? AppTheme.textCream,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          title: Text(
            'Elimina Account',
            style: GoogleFonts.playfairDisplay(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Sei sicuro di voler eliminare definitivamente il tuo account? Tutti i tuoi punti e premi verranno persi irrimediabilmente.\n\nQuesta azione è irreversibile.',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('ANNULLA', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text('ELIMINA', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await AuthService().deleteAccount();
      
      if (context.mounted) {
        Navigator.pop(context); // chiude loading dialog
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // chiude loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
