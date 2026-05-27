import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _promoController = PageController();
  int _currentPromoPage = 0;
  Timer? _promoTimer;

  final List<Map<String, String>> _promos = [
    {
      'title': 'L\'Ora dell\'Aperitivo',
      'subtitle': 'Tutti i giorni 18:00 - 20:00',
      'desc': 'Ordina 2 cocktail signature e ricevi un tagliere Antigravity in omaggio!',
      'badge': 'PROMO TOP',
    },
    {
      'title': 'Brunch d\'Autore',
      'subtitle': 'Domenica dalle 11:30',
      'desc': 'Pancake freschi alla crema e spremute d\'arancia bio con sconto fidelity del 10%.',
      'badge': 'DOMENICA',
    },
    {
      'title': 'Caffè & Cornetto Art',
      'subtitle': 'Colazione dalle 07:00 alle 10:00',
      'desc': 'Espresso Monet + Cornetto Monna Lisa a soli 3.00€ per tutti i soci fidelity.',
      'badge': 'COLAZIONE',
    },
  ];

  @override
  void initState() {
    super.initState();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _currentPromoPage = (_currentPromoPage + 1) % _promos.length;
        _promoController.animateToPage(
          _currentPromoPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      });
    });
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  void _showMockAction(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(color: AppTheme.backgroundDark, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.accentGold,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: AuthService().userStateChanges,
        builder: (context, snapshot) {
          final user = snapshot.data ?? AuthService().currentUser;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Benvenuto,',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              user.name,
                              style: GoogleFonts.playfairDisplay(
                                color: AppTheme.textCream,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Top Right Logo Asset
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 1.5),
                          ),
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
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick fidelity overview
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.goldGradientCard(),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TESSERA MONET CLUB',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.backgroundDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Accumula punti e riscatta premi esclusivi ad ogni consumazione.',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.backgroundDark.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            children: [
                              Text(
                                '${user.pointsBalance}',
                                style: GoogleFonts.playfairDisplay(
                                  color: AppTheme.backgroundDark,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'PUNTI',
                                style: GoogleFonts.outfit(
                                  color: AppTheme.backgroundDark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Featured Promos Title
                    Text(
                      'Promozioni del Giorno',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 12),

                    // Promos Carousel Card
                    SizedBox(
                      height: 160,
                      child: PageView.builder(
                        controller: _promoController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPromoPage = index;
                          });
                        },
                        itemCount: _promos.length,
                        itemBuilder: (context, index) {
                          final promo = _promos[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 6, left: 6, bottom: 4),
                            padding: const EdgeInsets.all(20),
                            decoration: AppTheme.glassCard(borderColor: AppTheme.accentGold.withOpacity(0.2)),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      promo['title']!,
                                      style: GoogleFonts.playfairDisplay(
                                        color: AppTheme.textCream,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      promo['subtitle']!,
                                      style: GoogleFonts.outfit(
                                        color: AppTheme.accentAmber,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      promo['desc']!,
                                      style: GoogleFonts.outfit(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.accentGold, width: 1),
                                    ),
                                    child: Text(
                                      promo['badge']!,
                                      style: GoogleFonts.outfit(
                                        color: AppTheme.accentGold,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
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

                    // Dot Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _promos.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPromoPage == index
                                ? AppTheme.accentGold
                                : AppTheme.textMuted.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Local Info & Story Card
                    Text(
                      'Chi Siamo',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.glassCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arte & Ospitalità',
                            style: GoogleFonts.playfairDisplay(
                              color: AppTheme.textCream,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Situato nel cuore pulsante della città, il Monet Bar è il luogo ideale dove concedersi una pausa d\'eccellenza. Dai nostri specialty coffee della mattina, passando per i deliziosi cornetti artigianali, fino all\'aperitivo serale con i cocktail preparati con liquori e ingredienti ricercati. Ogni dettaglio è pensato come una pennellata su tela.',
                            style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Hours & Location Details Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Opening Hours Box
                        Expanded(
                          flex: 11,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.glassCard(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, color: AppTheme.accentGold, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Orari',
                                      style: GoogleFonts.playfairDisplay(
                                        color: AppTheme.textCream,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: AppTheme.accentGold, height: 16, thickness: 0.5),
                                _buildHourRow('Lun - Ven', '07:00 - 22:00'),
                                _buildHourRow('Sabato', '07:30 - 23:00'),
                                _buildHourRow('Domenica', '08:00 - 21:00'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Contact & Address Box
                        Expanded(
                          flex: 9,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.glassCard(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: AppTheme.accentGold, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Dove Siamo',
                                      style: GoogleFonts.playfairDisplay(
                                        color: AppTheme.textCream,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: AppTheme.accentGold, height: 16, thickness: 0.5),
                                Text(
                                  'Via dell\'Impressionismo, 42\nFirenze (FI)',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _showMockAction('Apertura navigatore per Via dell\'Impressionismo...'),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.directions, color: AppTheme.accentAmber, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Indicazioni',
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.accentAmber,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Action Contact
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: AppTheme.glassCard(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone, color: AppTheme.accentGold),
                            tooltip: 'Chiamaci',
                            onPressed: () => _showMockAction('Avvio chiamata telefonica al +39 055 1234567...'),
                          ),
                          const VerticalDivider(color: Colors.white24, width: 2),
                          IconButton(
                            icon: const Icon(Icons.email, color: AppTheme.accentGold),
                            tooltip: 'Invia Email',
                            onPressed: () => _showMockAction('Apertura client mail per info@monetbar.it...'),
                          ),
                          const VerticalDivider(color: Colors.white24, width: 2),
                          IconButton(
                            icon: const Icon(Icons.language, color: AppTheme.accentGold),
                            tooltip: 'Sito Web',
                            onPressed: () => _showMockAction('Apertura browser su www.monetbar.it...'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHourRow(String days, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            days,
            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
          ),
          Text(
            time,
            style: GoogleFonts.outfit(color: AppTheme.textCream, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
