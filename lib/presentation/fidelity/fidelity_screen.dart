import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../widgets/app_bar_logo.dart';

class FidelityScreen extends StatefulWidget {
  const FidelityScreen({super.key});

  @override
  State<FidelityScreen> createState() => _FidelityScreenState();
}

class _FidelityScreenState extends State<FidelityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PROFILO FEDELTÀ',
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
      body: StreamBuilder(
        stream: AuthService().userStateChanges,
        builder: (context, authSnapshot) {
          final user = authSnapshot.data ?? AuthService().currentUser;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header with Logout
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: AppTheme.glassCard(
                      borderColor: AppTheme.accentGold.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        // User Avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentGold,
                                AppTheme.accentAmber,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: GoogleFonts.playfairDisplay(
                                color: AppTheme.backgroundDark,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name and Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.name,
                                      style: GoogleFonts.playfairDisplay(
                                        color: AppTheme.textCream,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _showEditUsernameDialog(context, user.name),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: AppTheme.accentGold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: GoogleFonts.outfit(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                  // Membership barcode / QR Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassCard(
                      borderColor: AppTheme.accentGold.withOpacity(0.4),
                    ),
                    child: Column(
                      children: [
                        Text(
                          user.name.toUpperCase(),
                          style: GoogleFonts.playfairDisplay(
                            color: AppTheme.textCream,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Username: ${user.name}',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // QR Code Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: user.name,
                            version: QrVersions.auto,
                            size: 160.0,
                            gapless: false,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppTheme.backgroundDark,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppTheme.backgroundDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Points Balance Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Saldo Punti: ',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${user.points}',
                              style: GoogleFonts.playfairDisplay(
                                color: AppTheme.accentGold,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),



                  // Point Transactions Logs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cronologia Punti',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20),
                      ),
                      const Icon(Icons.history, color: AppTheme.accentGold, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<List<TransactionModel>>(
                    stream: FirestoreService().transactionsStream,
                    builder: (context, txSnapshot) {
                      final txList = txSnapshot.data ?? [];

                      if (txList.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: AppTheme.glassCard(),
                          child: Center(
                            child: Text(
                              'Nessuna transazione registrata.',
                              style: GoogleFonts.outfit(color: AppTheme.textMuted),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: txList.length > 10 ? 10 : txList.length, // Show up to 10 transactions
                        itemBuilder: (context, index) {
                          final tx = txList[index];
                          final isAdd = tx.type == 'add';

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.glassCard(),
                            child: Row(
                              children: [
                                // Icon status indicator
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isAdd ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                    color: isAdd ? Colors.greenAccent : Colors.redAccent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title and Date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.description,
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.textCream,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${tx.date.day}/${tx.date.month}/${tx.date.year} - ${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Point Value
                                Text(
                                  '${isAdd ? '+' : '-'}${tx.points}',
                                  style: GoogleFonts.outfit(
                                    color: isAdd ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Future<void> _showEditUsernameDialog(BuildContext context, String currentUsername) async {
    final TextEditingController controller = TextEditingController(text: currentUsername);
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: Text(
                'Modifica Username',
                style: GoogleFonts.playfairDisplay(color: AppTheme.textCream, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: GoogleFonts.outfit(color: AppTheme.textCream),
                    decoration: const InputDecoration(
                      hintText: 'Nuovo Username',
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentGold)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentGold)),
                    ),
                  ),
                  if (isSaving)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(color: AppTheme.accentGold),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text('Annulla', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                ),
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newUsername = controller.text.trim();
                          if (newUsername.isEmpty || newUsername == currentUsername) {
                            Navigator.pop(context);
                            return;
                          }

                          setState(() {
                            isSaving = true;
                          });

                          try {
                            await AuthService().updateUsername(newUsername, currentUsername);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Username aggiornato con successo!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isSaving = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  child: Text('Salva', style: GoogleFonts.outfit(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
