import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_bar_logo.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onGoToRewards;
  const HomeScreen({super.key, this.onGoToRewards});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _promoController = PageController();
  int _currentPromoPage = 0;
  int _promoLength = 0;
  Timer? _promoTimer;
  late final Stream<dynamic> _userStream;
  late final Stream<QuerySnapshot> _newsStream;

  void _startPromoTimer() {
    _promoTimer?.cancel();
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _promoLength <= 1) return;
      setState(() {
        _currentPromoPage++;
        if (_promoController.hasClients) {
          _promoController.animateToPage(
            _currentPromoPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _userStream = AuthService().userStateChanges;
    _newsStream = FirebaseFirestore.instance
        .collection('news')
        .where('is_active', isEqualTo: true)
        .snapshots();

    _startPromoTimer();
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

  Future<void> _launchInstagram() async {
    final Uri url = Uri.parse('https://www.instagram.com/pasticceriamonet?igsh=MXhlcXJ5c3kwbGhu');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aprire Instagram')),
        );
      }
    }
  }

  Future<void> _launchFacebook() async {
    final Uri url = Uri.parse('https://www.facebook.com/monetpasticceria/?locale=it_IT');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aprire Facebook')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _userStream,
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
                        const AppBarLogo(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick fidelity overview
                    GestureDetector(
                      onTap: widget.onGoToRewards,
                      child: Container(
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
                    ),
                    const SizedBox(height: 28),

                    // Featured Promos Title
                    Text(
                      'Promozioni del Giorno',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 12),

                    // Promos Carousel Card
                    StreamBuilder<QuerySnapshot>(
                      stream: _newsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(child: Text('Errore nel caricamento novità.'));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs.toList() ?? [];
                        docs.sort((a, b) {
                          final dataA = a.data() as Map<String, dynamic>;
                          final dataB = b.data() as Map<String, dynamic>;
                          final timeA = dataA['timestamp_creazione'] as Timestamp?;
                          final timeB = dataB['timestamp_creazione'] as Timestamp?;
                          if (timeA == null && timeB == null) return 0;
                          if (timeA == null) return 1;
                          if (timeB == null) return -1;
                          return timeB.compareTo(timeA);
                        });
                        
                        if (docs.isEmpty) {
                          return const SizedBox(); // Nessuna news
                        }

                        // Aggiorniamo _promoLength in modo asincrono per non bloccare il build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _promoLength != docs.length) {
                            setState(() {
                              _promoLength = docs.length;
                            });
                          }
                        });

                        return Column(
                          children: [
                            SizedBox(
                              height: 160,
                              child: PageView.builder(
                                controller: _promoController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPromoPage = index;
                                  });
                                  _startPromoTimer();
                                },
                                itemBuilder: (context, index) {
                                  final realIndex = index % docs.length;
                                  final data = docs[realIndex].data() as Map<String, dynamic>;
                                  final title = data['titolo'] ?? 'Novità';
                                  final desc = data['contenuto'] ?? '';
                                  final timestamp = data['timestamp_creazione'] as Timestamp?;
                                  final dateStr = timestamp != null
                                      ? DateFormat('dd MMM yyyy').format(timestamp.toDate())
                                      : 'Oggi';

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
                                              title,
                                              style: GoogleFonts.playfairDisplay(
                                                color: AppTheme.textCream,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              desc,
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
                                              'NEWS',
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
                                docs.length,
                                (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (_currentPromoPage % docs.length) == index
                                        ? AppTheme.accentGold
                                        : AppTheme.textMuted.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
                            icon: const FaIcon(FontAwesomeIcons.facebook, color: AppTheme.accentGold),
                            tooltip: 'Facebook',
                            onPressed: _launchFacebook,
                          ),
                          const VerticalDivider(color: Colors.white24, width: 2),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.instagram, color: AppTheme.accentGold),
                            tooltip: 'Instagram',
                            onPressed: _launchInstagram,
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
