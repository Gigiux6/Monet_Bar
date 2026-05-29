import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/reward_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/user_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/app_bar_logo.dart';


class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _isProcessing = false;

  IconData _getIconForReward(String iconName) {
    switch (iconName) {
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      case 'bakery_dining':
        return Icons.bakery_dining_outlined;
      case 'local_bar':
        return Icons.local_bar_outlined;
      case 'dinner_dining':
        return Icons.dinner_dining_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  void _handleRedeem(Reward reward) {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;
    
    final qrData = 'REDEEM:$userId:${reward.id}';

    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.accentGold, width: 1),
            ),
            title: Text(
              'Mostra in Cassa',
              style: GoogleFonts.playfairDisplay(color: AppTheme.textCream, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fai scansionare questo codice al barista per ritirare il tuo premio "${reward.title}".\n\nSaranno scalati ${reward.pointsCost} punti.',
                  style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: 232,
                  height: 232,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CHIUDI',
                  style: GoogleFonts.outfit(color: AppTheme.textMuted),
                ),
              ),
            ],
          );
        },
      );
    });
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CATALOGO PREMI',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textCream,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: const [AppBarLogo()],
      ),
      body: Stack(
        children: [
          StreamBuilder<UserModel?>(
            stream: AuthService().userStateChanges,
            builder: (context, authSnapshot) {
              final user = authSnapshot.data ?? AuthService().currentUser;
              if (user == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<List<Reward>>(
                stream: FirestoreService().rewardsStream,
                builder: (context, rewardsSnapshot) {
                  if (rewardsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (rewardsSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Errore nel caricamento del catalogo premi',
                        style: GoogleFonts.outfit(color: AppTheme.textCream),
                      ),
                    );
                  }

                  final rewards = rewardsSnapshot.data ?? [];

                  return Column(
                    children: [
                      // Upper Points summary
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassCard(borderColor: AppTheme.accentGold.withOpacity(0.3)),
                        child: Column(
                          children: [
                            Text(
                              'IL TUO BILANCIO PUNTI',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.stars, color: AppTheme.accentGold, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  '${user.pointsBalance}',
                                  style: GoogleFonts.playfairDisplay(
                                    color: AppTheme.textCream,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'punti',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.accentGold,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Rewards catalog grid
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: rewards.length,
                          itemBuilder: (context, index) {
                            final reward = rewards[index];
                            final userPoints = user.pointsBalance;
                            final double progress = (userPoints / reward.pointsCost).clamp(0.0, 1.0);
                            final bool canRedeem = userPoints >= reward.pointsCost;
                            final pointsNeeded = reward.pointsCost - userPoints;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(18),
                              decoration: AppTheme.glassCard(
                                borderColor: canRedeem
                                    ? AppTheme.accentGold.withOpacity(0.5)
                                    : AppTheme.accentGold.withOpacity(0.15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon & Points header row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: canRedeem
                                              ? AppTheme.accentGold.withOpacity(0.15)
                                              : AppTheme.cardDark,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: canRedeem ? AppTheme.accentGold : Colors.transparent,
                                          ),
                                        ),
                                        child: Icon(
                                          _getIconForReward(reward.iconName),
                                          color: canRedeem ? AppTheme.accentAmber : AppTheme.accentGold,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reward.title,
                                              style: GoogleFonts.playfairDisplay(
                                                color: AppTheme.textCream,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${reward.pointsCost} Punti',
                                              style: GoogleFonts.outfit(
                                                color: AppTheme.accentGold,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Description
                                  Text(
                                    reward.description,
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Progress bar representation
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            canRedeem ? 'Disponibile!' : 'Progresso riscatto',
                                            style: GoogleFonts.outfit(
                                              color: canRedeem ? Colors.greenAccent : AppTheme.textMuted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${(progress * 100).toInt()}%',
                                            style: GoogleFonts.outfit(
                                              color: canRedeem ? Colors.greenAccent : AppTheme.accentGold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: AppTheme.cardDark,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            canRedeem ? Colors.greenAccent : AppTheme.accentGold,
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Action Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: canRedeem ? () => _handleRedeem(reward) : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: canRedeem ? AppTheme.accentGold : AppTheme.cardDark,
                                        foregroundColor: canRedeem ? AppTheme.backgroundDark : AppTheme.textMuted,
                                        elevation: canRedeem ? 4 : 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(
                                            color: canRedeem ? Colors.transparent : Colors.white10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        canRedeem ? 'RISCATTA PREMIO' : 'MANCANO $pointsNeeded PUNTI',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
