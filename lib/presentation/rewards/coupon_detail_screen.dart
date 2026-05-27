import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/coupon_model.dart';
import '../../data/services/firestore_service.dart';

class CouponDetailScreen extends StatefulWidget {
  final Coupon coupon;

  const CouponDetailScreen({super.key, required this.coupon});

  @override
  State<CouponDetailScreen> createState() => _CouponDetailScreenState();
}

class _CouponDetailScreenState extends State<CouponDetailScreen> {
  late Coupon _currentCoupon;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _currentCoupon = widget.coupon;
  }

  Future<void> _handleValidateCoupon() async {
    // Show verification dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.accentGold, width: 1),
          ),
          title: Text(
            'Azione Barista',
            style: GoogleFonts.playfairDisplay(color: AppTheme.textCream, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Stai per convalidare ed utilizzare il coupon "${_currentCoupon.rewardTitle}". Questa azione è irreversibile.',
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
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
              child: Text(
                'CONVALIDA',
                style: GoogleFonts.outfit(color: AppTheme.backgroundDark, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isValidating = true;
    });

    final success = await FirestoreService().validateCoupon(_currentCoupon.id);

    if (mounted) {
      setState(() {
        _isValidating = false;
        if (success) {
          _currentCoupon = _currentCoupon.copyWith(status: 'used');
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon convalidato con successo!',
              style: GoogleFonts.outfit(color: AppTheme.backgroundDark, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUsed = _currentCoupon.status == 'used';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DETTAGLIO COUPON',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textCream,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassCard(
                  borderColor: isUsed ? Colors.white10 : AppTheme.accentGold,
                ),
                child: Column(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isUsed ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isUsed ? Colors.redAccent : Colors.greenAccent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isUsed ? Icons.cancel_outlined : Icons.check_circle_outline,
                            color: isUsed ? Colors.redAccent : Colors.greenAccent,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isUsed ? 'UTILIZZATO' : 'ATTIVO / DA UTILIZZARE',
                            style: GoogleFonts.outfit(
                              color: isUsed ? Colors.redAccent : Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reward Title
                    Text(
                      _currentCoupon.rewardTitle,
                      style: GoogleFonts.playfairDisplay(
                        color: AppTheme.textCream,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Coupon Details info table
                    const Divider(color: Colors.white10, height: 24),
                    _buildDetailRow('Codice Coupon', _currentCoupon.id),
                    _buildDetailRow('Costo Punti', '${_currentCoupon.pointsSpent} pt'),
                    _buildDetailRow('Data Riscatto', '${_currentCoupon.claimDate.day}/${_currentCoupon.claimDate.month}/${_currentCoupon.claimDate.year}'),
                    _buildDetailRow('Data Scadenza', '${_currentCoupon.expiryDate.day}/${_currentCoupon.expiryDate.month}/${_currentCoupon.expiryDate.year}'),
                    const Divider(color: Colors.white10, height: 24),
                    const SizedBox(height: 12),

                    // Barcode / QR display area
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Opacity(
                            opacity: isUsed ? 0.15 : 1.0,
                            child: QrImageView(
                              data: _currentCoupon.id,
                              version: QrVersions.auto,
                              size: 180.0,
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
                        ),
                        // Watermark if used
                        if (isUsed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              'UTILIZZATO',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      isUsed
                          ? 'Questo coupon è stato utilizzato al banco.'
                          : 'Mostra questo codice QR al barista per convalidare il tuo premio.',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Barista Action Button
              if (!isUsed)
                ElevatedButton(
                  onPressed: _isValidating ? null : _handleValidateCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isValidating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundDark),
                          ),
                        )
                      : Text(
                          'VALIDA COUPON (AZIONE BARISTA)',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Center(
                    child: Text(
                      'COUPON GIÀ UTILIZZATO',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: AppTheme.textCream,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
