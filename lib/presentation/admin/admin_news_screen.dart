import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_bar_logo.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _publishNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('news').add({
        'titolo': _titleController.text.trim(),
        'contenuto': _contentController.text.trim(),
        'timestamp_creazione': FieldValue.serverTimestamp(),
        'is_active': false, // La promozione nasce nascosta di default
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Novità creata con successo! Ricordati di attivarla dalla lista sottostante.',
              style: GoogleFonts.outfit(color: AppTheme.backgroundDark, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.accentGold,
          ),
        );
        _titleController.clear();
        _contentController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante la creazione: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Elimina Promozione', style: GoogleFonts.playfairDisplay(color: AppTheme.textCream)),
        content: Text('Sei sicuro di voler eliminare definitivamente questa promozione?', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annulla', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('news').doc(docId).delete();
              Navigator.pop(ctx);
            },
            child: Text('Elimina', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmSendNotification(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Invia Notifica', style: GoogleFonts.playfairDisplay(color: AppTheme.textCream)),
        content: Text('Vuoi davvero inviare una notifica push a tutti gli utenti per questa promozione?', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annulla', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('notification_requests').add({
                'titolo': title,
                'contenuto': content,
                'timestamp': FieldValue.serverTimestamp(),
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notifica in invio...', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.backgroundDark)),
                  backgroundColor: AppTheme.accentGold,
                )
              );
            },
            child: Text('Invia', style: GoogleFonts.outfit(color: AppTheme.accentAmber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Widget _buildPromotionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('news')
          .orderBy('timestamp_creazione', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accentGold));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('Nessuna promozione presente.', style: GoogleFonts.outfit(color: AppTheme.textSecondary));
        }

        final docs = snapshot.data!.docs;
        // Calcola quante sono attive al momento
        int activeCount = docs.where((d) => (d.data() as Map<String, dynamic>)['is_active'] == true).length;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isActive = data['is_active'] == true;
            final title = data['titolo'] ?? '';
            final content = data['contenuto'] ?? '';
            
            final timestamp = data['timestamp_creazione'] as Timestamp?;
            final dateStr = timestamp != null
                ? DateFormat('dd MMM yyyy').format(timestamp.toDate())
                : 'Oggi';

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: AppTheme.glassCard(),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title, 
                          style: GoogleFonts.playfairDisplay(color: AppTheme.textCream, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content, 
                          style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12), 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isActive,
                    activeColor: AppTheme.accentGold,
                    onChanged: (val) {
                      if (val && activeCount >= 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Puoi mostrare massimo 3 promozioni contemporaneamente. Spegnine una prima.',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Colors.redAccent,
                          )
                        );
                        return;
                      }
                      FirebaseFirestore.instance.collection('news').doc(doc.id).update({'is_active': val});
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_active, color: AppTheme.accentAmber),
                    onPressed: () => _confirmSendNotification(title, content),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(doc.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'GESTIONE NOVITÀ',
          style: GoogleFonts.playfairDisplay(color: AppTheme.textCream, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18),
        ),
        backgroundColor: AppTheme.surfaceDark,
        centerTitle: true,
        actions: const [AppBarLogo()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sezione Creazione
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crea una nuova comunicazione. Sarà salvata come nascosta.',
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.outfit(color: AppTheme.textCream),
                      decoration: InputDecoration(
                        labelText: 'Titolo Novità',
                        labelStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.accentGold.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.accentGold),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardDark,
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Inserisci un titolo' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      style: GoogleFonts.outfit(color: AppTheme.textCream),
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Testo della Notizia',
                        labelStyle: GoogleFonts.outfit(color: AppTheme.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.accentGold.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.accentGold),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardDark,
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Inserisci il contenuto' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _publishNews,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGold,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppTheme.backgroundDark,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Crea Promozione',
                              style: GoogleFonts.outfit(
                                color: AppTheme.backgroundDark,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              const Divider(color: AppTheme.accentGold),
              const SizedBox(height: 24),
              
              // Sezione Gestione (Lista)
              Text(
                'Promozioni Pubblicate',
                style: GoogleFonts.playfairDisplay(color: AppTheme.textCream, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Scegli quali promozioni mostrare nella Home (Massimo 3).',
                style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildPromotionsList(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
