import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/reward_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/coupon_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/app_bar_logo.dart';


class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _isProcessing = false;

  int _daysUntilNext(String dateStr, int validityDays) {
    try {
      final parts = dateStr.split('-');
      int month = 1;
      int day = 1;

      if (parts.length == 3) {
        // Format YYYY-MM-DD
        month = int.tryParse(parts[1]) ?? 1;
        day = int.tryParse(parts[2]) ?? 1;
      } else if (parts.length == 2) {
        // Format DD-MM (Italian format)
        day = int.tryParse(parts[0]) ?? 1;
        month = int.tryParse(parts[1]) ?? 1;
      } else {
        return -1;
      }

      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime eventThisYear = DateTime(now.year, month, day);
      DateTime eventNextYear = DateTime(now.year + 1, month, day);

      final diffToThisYear = eventThisYear.difference(today).inDays;
      
      if (diffToThisYear >= -validityDays && diffToThisYear <= validityDays) {
        return diffToThisYear; // returns 0, or +/- days if within the window
      }

      if (eventThisYear.isBefore(today)) {
        return eventNextYear.difference(today).inDays;
      } else {
        return diffToThisYear;
      }
    } catch (_) {
      return -1;
    }
  }

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
      case 'cake':
        return Icons.cake_outlined;
      case 'celebration':
        return Icons.celebration_outlined;
      case 'favorite':
        return Icons.favorite_border;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  void _handleRedeem(Reward reward) {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;
    
    final qrData = 'REDEEM:$userId:${reward.id}';
    final DateTime openTime = DateTime.now();

    // Listen to coupons to auto-close dialog when scanned remotely
    StreamSubscription<List<Coupon>>? subscription;
    subscription = FirestoreService().couponsStream.listen((coupons) {
      final newlyRedeemed = coupons.any((coupon) =>
          coupon.rewardId == reward.id &&
          coupon.claimDate.isAfter(openTime.subtract(const Duration(seconds: 10))) &&
          coupon.status == 'used');

      if (newlyRedeemed) {
        subscription?.cancel();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Premio "${reward.title}" riscattato con successo!',
              style: GoogleFonts.outfit(color: AppTheme.backgroundDark, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.greenAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    Future.delayed(Duration.zero, () {
      if (!mounted) {
        subscription?.cancel();
        return;
      }
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
                  reward.pointsCost == 0
                      ? 'Fai scansionare questo codice al barista per ritirare il tuo premio gratuito "${reward.title}".'
                      : 'Fai scansionare questo codice al barista per ritirare il tuo premio "${reward.title}".\n\nSaranno scalati ${reward.pointsCost} punti.',
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
      ).then((_) {
        subscription?.cancel();
      });
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

                  final fetchedRewards = rewardsSnapshot.data ?? [];
                  final baseRewards = fetchedRewards.where((r) => !r.isSpecial).toList();
                  final specialRewards = fetchedRewards.where((r) => r.isSpecial).toList();
                  final importantDates = user.importantDates;

                  if (importantDates.containsKey('birthday') && importantDates['birthday'] is String) {
                    specialRewards.add(Reward(
                      id: 'special_birthday',
                      title: 'Regalo di Compleanno',
                      description: 'Tantissimi auguri da Monet! Mostra in cassa questo regalo per ritirare il tuo premio gratuito.',
                      pointsCost: 0,
                      iconName: 'cake',
                      terms: importantDates['birthday'],
                    ));
                  }
                  if (importantDates.containsKey('nameDay') && importantDates['nameDay'] is String) {
                    specialRewards.add(Reward(
                      id: 'special_nameDay',
                      title: 'Regalo di Onomastico',
                      description: 'Buon Onomastico! Abbiamo un regalo speciale riservato per te.',
                      pointsCost: 0,
                      iconName: 'celebration',
                      terms: importantDates['nameDay'],
                    ));
                  }
                  if (importantDates.containsKey('anniversary') && importantDates['anniversary'] is String) {
                    specialRewards.add(Reward(
                      id: 'special_anniversary',
                      title: 'Data Speciale',
                      description: 'Festeggia con noi! Goditi un regalo offerto da Monet.',
                      pointsCost: 0,
                      iconName: 'favorite',
                      terms: importantDates['anniversary'],
                    ));
                  }

                  return StreamBuilder<List<Coupon>>(
                    stream: FirestoreService().couponsStream,
                    builder: (context, couponsSnapshot) {
                      final coupons = couponsSnapshot.data ?? [];
                      
                      return DefaultTabController(
                        length: 2,
                        child: Column(
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

                      // TabBar
                      TabBar(
                        indicatorColor: AppTheme.accentGold,
                        labelColor: AppTheme.accentGold,
                        unselectedLabelColor: AppTheme.textMuted,
                        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'Classici'),
                          Tab(text: 'Speciali'),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // TabBar Views
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildRewardsList(baseRewards, user, coupons),
                            _buildRewardsList(specialRewards, user, coupons),
                          ],
                        ),
                      ),
                    ],
                  ),
                  );
                },
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

  Widget _buildRewardsList(List<Reward> rewards, UserModel user, List<Coupon> coupons) {
    if (rewards.isEmpty) {
      return Center(
        child: Text(
          'Nessun premio disponibile in questa sezione',
          style: GoogleFonts.outfit(color: AppTheme.textMuted),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 8),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final isSpecialReward = reward.isSpecial || reward.id.startsWith('special_');
        int daysToWait = -1;
        bool isSpecialActive = false;
        
        if (isSpecialReward) {
          daysToWait = _daysUntilNext(reward.terms, reward.validityDays);
          
          // Check if already redeemed this year
          final currentYear = DateTime.now().year;
          final alreadyRedeemedThisYear = coupons.any((c) => 
            c.rewardId == reward.id && 
            c.claimDate.year == currentYear &&
            c.status == 'used'
          );

          if (alreadyRedeemedThisYear) {
            isSpecialActive = false;
            daysToWait = 999; // Force non-availability
          } else {
            isSpecialActive = daysToWait >= -reward.validityDays && daysToWait <= reward.validityDays;
          }
        }

        final userPoints = user.pointsBalance;
        final double progress = (reward.pointsCost > 0) ? (userPoints / reward.pointsCost).clamp(0.0, 1.0) : (isSpecialActive ? 1.0 : 0.0);
        final bool hasEnoughPoints = userPoints >= reward.pointsCost;
        final bool canRedeem = isSpecialReward ? (isSpecialActive && hasEnoughPoints) : hasEnoughPoints;
        final int pointsNeeded = reward.pointsCost - userPoints;

        String buttonText;
        if (isSpecialReward) {
          final currentYear = DateTime.now().year;
          final alreadyRedeemedThisYear = coupons.any((c) => 
            c.rewardId == reward.id && 
            c.claimDate.year == currentYear &&
            c.status == 'used'
          );
          
          if (alreadyRedeemedThisYear) {
            buttonText = 'GIÀ RISCATTATO';
          } else {
            int daysUntilUnlock = daysToWait - reward.validityDays;
            if (isSpecialActive) {
              buttonText = hasEnoughPoints 
                  ? (reward.pointsCost == 0 ? 'RISCATTA REGALO' : 'RISCATTA PREMIO') 
                  : 'MANCANO $pointsNeeded PUNTI';
            } else if (daysUntilUnlock > 0) {
              buttonText = 'DISPONIBILE TRA $daysUntilUnlock GIORNI';
            } else {
              buttonText = 'NON DISPONIBILE';
            }
          }
        } else {
          buttonText = canRedeem ? 'RISCATTA PREMIO' : 'MANCANO $pointsNeeded PUNTI';
        }

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
              // Image (if present)
              if (reward.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: CachedNetworkImage(
                      imageUrl: reward.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(height: 180, color: AppTheme.cardDark, child: const Center(child: CircularProgressIndicator())),
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                          reward.pointsCost == 0 ? 'Regalo Gratuito' : '${reward.pointsCost} Punti',
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
              if (reward.pointsCost > 0)
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
              if (!isSpecialReward)
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
                    buttonText,
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
    );
  }
}
