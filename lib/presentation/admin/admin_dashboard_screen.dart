import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/coupon_model.dart';
import '../widgets/app_bar_logo.dart';
import '../login_screen.dart';
import 'qr_scanner_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _descController = TextEditingController(text: 'Consumazione al banco');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentUser = AuthService().currentUser;
    if (currentUser != null) {
      _usernameController.text = currentUser.name;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _openQrScannerForPoints() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );
    
    if (scannedCode != null && scannedCode.isNotEmpty) {
      if (scannedCode.startsWith('REDEEM:')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questo è un QR di Riscatto Premio. Usa la sezione apposita sotto.'), backgroundColor: Colors.redAccent),
        );
        return;
      }
      setState(() {
        _usernameController.text = scannedCode;
      });
      if (mounted) {
        FocusScope.of(context).requestFocus(_amountFocusNode);
      }
    }
  }

  Future<void> _openQrScannerForRedeem() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );
    
    if (scannedCode != null && scannedCode.isNotEmpty) {
      if (!scannedCode.startsWith('REDEEM:')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Codice non valido per il riscatto premio.'), backgroundColor: Colors.redAccent),
        );
        return;
      }
      
      final parts = scannedCode.split(':');
      if (parts.length != 3) return;
      
      final userId = parts[1];
      final rewardId = parts[2];
      
      setState(() => _isSaving = true);
      
      final result = await FirestoreService().adminRedeemReward(userId, rewardId);
      
      if (!mounted) return;
      setState(() => _isSaving = false);
      
      if (result['success'] == true) {
        final title = result['rewardTitle'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Premio "$title" consegnato con successo!', style: GoogleFonts.outfit(color: AppTheme.backgroundDark, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.greenAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Errore nel riscatto'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'LOGOUT',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textCream,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Sei sicuro di voler uscire dal profilo?',
          style: GoogleFonts.outfit(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'ANNULLA',
              style: GoogleFonts.outfit(color: AppTheme.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'LOGOUT',
              style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _handleAwardPoints() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final username = _usernameController.text.trim();
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText) ?? 0.0;
    final description = _descController.text.trim();

    bool success = false;
    String? errorMessage;

    try {
      await FirestoreService().addPointsByUsername(username, amount, description);
      success = true;
    } catch (e) {
      errorMessage = e.toString();
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        final pts = amount.floor();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aggiunti +$pts punti con successo a $username!',
              style: GoogleFonts.outfit(color: AppTheme.backgroundDark, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.accentGold,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Impossibile aggiungere punti.', style: GoogleFonts.outfit()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PANNELLO DI CONTROLLO',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textCream,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const AppBarLogo(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassCard(borderColor: AppTheme.accentAmber),
                child: Column(
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 50, color: AppTheme.accentAmber),
                    const SizedBox(height: 12),
                    Text(
                      'Area Gestione',
                      style: GoogleFonts.playfairDisplay(
                        color: AppTheme.textCream,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Questa schermata è riservata agli amministratori. Da qui puoi assegnare punti, gestire il menu e i premi.',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'ASSEGNA PUNTI',
                        style: GoogleFonts.playfairDisplay(
                          color: AppTheme.textCream,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _usernameController,
                        style: GoogleFonts.outfit(color: AppTheme.textCream),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Inserisci lo Username';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Username Cliente',
                          prefixIcon: const Icon(Icons.person, color: AppTheme.accentGold),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: AppTheme.accentGold),
                            onPressed: _openQrScannerForPoints,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.outfit(color: AppTheme.textCream),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Inserisci l\'importo speso';
                          final amountText = value.trim().replaceAll(',', '.');
                          final amount = double.tryParse(amountText);
                          if (amount == null || amount < 1.0) return 'Importo valido (min. 1€)';
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Importo Speso (€)',
                          prefixIcon: Icon(Icons.euro, color: AppTheme.accentGold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        style: GoogleFonts.outfit(color: AppTheme.textCream),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Inserisci una descrizione';
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Motivo / Descrizione',
                          prefixIcon: Icon(Icons.description, color: AppTheme.accentGold),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleAwardPoints,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: AppTheme.backgroundDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundDark)),
                              )
                            : const Text('ASSEGNA PUNTI'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassCard(borderColor: Colors.greenAccent.withOpacity(0.5)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'RISCATTA PREMIO',
                      style: GoogleFonts.playfairDisplay(
                        color: AppTheme.textCream,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Scansiona il codice a barre dal dispositivo del cliente per confermare il riscatto del premio.',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _openQrScannerForRedeem,
                      icon: const Icon(Icons.qr_code_scanner, color: AppTheme.backgroundDark),
                      label: Text(
                        'SCANSIONA CODICE PREMIO',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.backgroundDark),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
