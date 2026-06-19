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
  int _selectedTab = 0;

  int _daysUntilNext(String dateStr, int validityDays) {
    try {
      final parts = dateStr.split('-');
      int month = 1;
      int day = 1;

      if (parts.length == 3) {
        if (parts[0].length == 4) {
          // Format YYYY-MM-DD
          month = int.tryParse(parts[1]) ?? 1;
          day = int.tryParse(parts[2]) ?? 1;
        } else if (parts[2].length == 4) {
          // Format DD-MM-YYYY
          day = int.tryParse(parts[0]) ?? 1;
          month = int.tryParse(parts[1]) ?? 1;
        } else {
          month = int.tryParse(parts[1]) ?? 1;
          day = int.tryParse(parts[2]) ?? 1;
        }
      } else if (parts.length == 2) {
        // Format DD-MM (Italian format)
        day = int.tryParse(parts[0]) ?? 1;
        month = int.tryParse(parts[1]) ?? 1;
      } else {
        return -1;
      }

      // Fix mistakenly swapped Month-Day
      if (month > 12 && day <= 12) {
        final temp = day;
        day = month;
        month = temp;
      }

      // Clamp values to avoid massive DateTime overflow bugs
      month = month.clamp(1, 12);
      day = day.clamp(1, 31);

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

  void _showEmailVerificationPopup() {
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
            'Verifica Richiesta',
            style: GoogleFonts.playfairDisplay(color: AppTheme.textCream, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Per poter riscattare i premi devi prima verificare il tuo indirizzo email. Controlla la tua casella di posta elettronica (anche nello Spam) o ricarica il profilo se lo hai già fatto.',
            style: GoogleFonts.outfit(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CHIUDI',
                style: GoogleFonts.outfit(color: AppTheme.accentGold, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: AuthService().userStateChanges,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data ?? AuthService().currentUser;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return StreamBuilder<List<Reward>>(
          stream: FirestoreService().rewardsStream,
          builder: (context, rewardsSnapshot) {
            return StreamBuilder<List<Coupon>>(
              stream: FirestoreService().couponsStream,
              builder: (context, couponsSnapshot) {
                final fetchedRewards = rewardsSnapshot.data ?? [];
                final baseRewards = fetchedRewards.where((r) => !r.isSpecial).toList();
                final specialRewards = fetchedRewards.where((r) => r.isSpecial).toList();
                final coupons = couponsSnapshot.data ?? [];
                final importantDates = user.importantDates;

                if (importantDates.containsKey('birthday')) {
                  final date = importantDates['birthday']!;
                  specialRewards.add(Reward(
                    id: 'special_birthday',
                    title: 'Regalo di Compleanno',
                    description: 'Tantissimi auguri da Monet! Mostra in cassa questo regalo per ritirare il tuo premio gratuito.',
                    pointsCost: 0,
                    iconName: 'cake',
                    terms: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  ));
                }
                if (importantDates.containsKey('nameDay')) {
                  final date = importantDates['nameDay']!;
                  specialRewards.add(Reward(
                    id: 'special_nameDay',
                    title: 'Regalo di Onomastico',
                    description: 'Buon Onomastico! Abbiamo un regalo speciale riservato per te.',
                    pointsCost: 0,
                    iconName: 'celebration',
                    terms: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  ));
                }
                if (importantDates.containsKey('anniversary')) {
                  final date = importantDates['anniversary']!;
                  specialRewards.add(Reward(
                    id: 'special_anniversary',
                    title: 'Data Speciale',
                    description: 'Festeggia con noi! Goditi un regalo offerto da Monet.',
                    pointsCost: 0,
                    iconName: 'favorite',
                    terms: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  ));
                }

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
                      Column(
                        children: [
                          // Points summary card - fixed at top
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
                                      '${user.points}',
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
                          // Custom Category Pills
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: Text(
                                  'Classici',
                                  style: GoogleFonts.outfit(
                                    fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                                    color: _selectedTab == 0 ? AppTheme.backgroundDark : AppTheme.textSecondary,
                                  ),
                                ),
                                selected: _selectedTab == 0,
                                selectedColor: AppTheme.accentGold,
                                backgroundColor: AppTheme.cardDark,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedTab = 0;
                                    });
                                  }
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _selectedTab == 0 ? AppTheme.accentGold : AppTheme.accentGold.withOpacity(0.15),
                                  ),
                                ),
                                showCheckmark: false,
                              ),
                              const SizedBox(width: 16),
                              ChoiceChip(
                                label: Text(
                                  'Speciali',
                                  style: GoogleFonts.outfit(
                                    fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                                    color: _selectedTab == 1 ? AppTheme.backgroundDark : AppTheme.textSecondary,
                                  ),
                                ),
                                selected: _selectedTab == 1,
                                selectedColor: AppTheme.accentGold,
                                backgroundColor: AppTheme.cardDark,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedTab = 1;
                                    });
                                  }
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _selectedTab == 1 ? AppTheme.accentGold : AppTheme.accentGold.withOpacity(0.15),
                                  ),
                                ),
                                showCheckmark: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Expanded fills remaining screen height - lists scroll freely inside
                          Expanded(
                            child: _selectedTab == 0
                                ? _buildRewardsList(baseRewards, user, coupons)
                                : _buildRewardsList(specialRewards, user, coupons),
                          ),
                        ],
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
              },
            );
          },
        );
      },
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
      padding: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
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

        final userPoints = user.points;
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
          decoration: AppTheme.glassCard(
            borderColor: canRedeem
                ? AppTheme.accentGold.withOpacity(0.5)
                : AppTheme.accentGold.withOpacity(0.15),
          ),
          child: InkWell(
            onTap: () => _showRewardDetails(
              context,
              reward,
              user,
              coupons,
              canRedeem,
              progress,
              buttonText,
              isSpecialReward,
              isSpecialActive,
              daysToWait,
              pointsNeeded,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Leading image or icon
                      if (reward.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: reward.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 50,
                              height: 50,
                              color: AppTheme.cardDark,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: canRedeem ? AppTheme.accentGold.withOpacity(0.1) : AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: canRedeem ? AppTheme.accentGold.withOpacity(0.4) : Colors.white10),
                              ),
                              child: Icon(_getIconForReward(reward.iconName), color: canRedeem ? AppTheme.accentAmber : AppTheme.accentGold, size: 24),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: canRedeem ? AppTheme.accentGold.withOpacity(0.1) : AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: canRedeem ? AppTheme.accentGold.withOpacity(0.4) : Colors.white10),
                          ),
                          child: Icon(_getIconForReward(reward.iconName), color: canRedeem ? AppTheme.accentAmber : AppTheme.accentGold, size: 24),
                        ),
                      const SizedBox(width: 16),

                      // Middle title and short description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reward.title,
                                    style: GoogleFonts.playfairDisplay(
                                      color: AppTheme.textCream,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSpecialReward) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.star,
                                    color: AppTheme.accentAmber,
                                    size: 14,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reward.description,
                              style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Price tag and trailing indicator (chevron)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (reward.pointsCost > 0) ...[
                                const Icon(Icons.stars, size: 16, color: AppTheme.accentGold),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                reward.pointsCost == 0 ? 'Gratis' : '${reward.pointsCost} pt',
                                style: GoogleFonts.playfairDisplay(
                                  color: AppTheme.accentGold,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            Icons.chevron_right,
                            color: canRedeem ? AppTheme.accentGold : AppTheme.textMuted,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (reward.pointsCost > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          canRedeem ? 'Sbloccato!' : 'Progresso',
                          style: GoogleFonts.outfit(
                            color: canRedeem ? Colors.greenAccent : AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.outfit(
                            color: canRedeem ? Colors.greenAccent : AppTheme.accentGold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.cardDark,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          canRedeem ? Colors.greenAccent : AppTheme.accentGold,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Action Button on Card
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canRedeem
                          ? () {
                              if (!AuthService().isEmailVerified) {
                                _showEmailVerificationPopup();
                              } else {
                                _handleRedeem(reward);
                              }
                            }
                          : null,
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
            ),
          ),
        );
      },
    );
  }

  void _showRewardDetails(
    BuildContext context,
    Reward reward,
    UserModel user,
    List<Coupon> coupons,
    bool canRedeem,
    double progress,
    String buttonText,
    bool isSpecialReward,
    bool isSpecialActive,
    int daysToWait,
    int pointsNeeded,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(color: AppTheme.accentGold, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bottomsheet Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (reward.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(height: 20),
                ],

                // Title and Points Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        reward.title,
                        style: GoogleFonts.playfairDisplay(
                          color: AppTheme.textCream,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      reward.pointsCost == 0 ? 'Gratis' : '${reward.pointsCost} Pt',
                      style: GoogleFonts.playfairDisplay(
                        color: AppTheme.accentGold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Subtitle/Badge (if special)
                if (isSpecialReward) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentAmber, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForReward(reward.iconName),
                          color: AppTheme.accentAmber,
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Premio Speciale',
                          style: GoogleFonts.outfit(
                            color: AppTheme.accentAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  'Descrizione',
                  style: GoogleFonts.playfairDisplay(
                    color: AppTheme.textCream,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reward.description,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Progress bar (only for rewards that cost points)
                if (reward.pointsCost > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        canRedeem ? 'Disponibile!' : 'Progresso riscatto',
                        style: GoogleFonts.outfit(
                          color: canRedeem ? Colors.greenAccent : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.outfit(
                          color: canRedeem ? Colors.greenAccent : AppTheme.accentGold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 24),
                ],

                // Action Button inside Sheet
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canRedeem
                        ? () {
                            Navigator.pop(context);
                            if (!AuthService().isEmailVerified) {
                              _showEmailVerificationPopup();
                            } else {
                              _handleRedeem(reward);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canRedeem ? AppTheme.accentGold : AppTheme.cardDark,
                      foregroundColor: canRedeem ? AppTheme.backgroundDark : AppTheme.textMuted,
                      elevation: canRedeem ? 4 : 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
