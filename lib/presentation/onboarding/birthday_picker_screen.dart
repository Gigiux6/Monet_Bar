import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../main_navigation.dart';

class BirthdayPickerScreen extends StatefulWidget {
  final bool isCancellable;

  const BirthdayPickerScreen({
    super.key,
    this.isCancellable = true,
  });

  @override
  State<BirthdayPickerScreen> createState() => _BirthdayPickerScreenState();
}

class _BirthdayPickerScreenState extends State<BirthdayPickerScreen> {
  DateTime? _birthday;
  DateTime? _nameDay;
  DateTime? _anniversary;

  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, {required Function(DateTime) onSelected, DateTime? initialDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentGold,
              onPrimary: AppTheme.backgroundDark,
              surface: AppTheme.surfaceDark,
              onSurface: AppTheme.textCream,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _saveDates() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final importantDates = <String, dynamic>{};
      final recurringDatesMmDd = <String>[];

      void processDate(String key, DateTime? date) {
        if (date != null) {
          importantDates[key] = DateFormat('yyyy-MM-dd').format(date);
          recurringDatesMmDd.add(DateFormat('MM-dd').format(date));
        }
      }

      processDate('birthday', _birthday);
      processDate('nameDay', _nameDay);
      processDate('anniversary', _anniversary);

      // Always save even if empty, to mark onboarding as completed
      importantDates['onboarding_completed'] = true;

      await FirestoreService().updateUser(user.id, {
        'importantDates': importantDates,
        'recurringDatesMmDd': recurringDatesMmDd,
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skip() {
    // Save empty to prevent asking again
    _saveDates();
  }

  Widget _buildDateSelector(String title, DateTime? selectedDate, Function(DateTime) onSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.glassCard(),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.outfit(color: AppTheme.textCream, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          selectedDate != null ? DateFormat('dd MMMM yyyy', 'it_IT').format(selectedDate) : 'Tocca per selezionare',
          style: GoogleFonts.outfit(
            color: selectedDate != null ? AppTheme.accentGold : AppTheme.textMuted,
          ),
        ),
        trailing: const Icon(Icons.calendar_today, color: AppTheme.accentGold),
        onTap: () => _selectDate(context, onSelected: onSelected, initialDate: selectedDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DATE SPECIALI',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textCream,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.isCancellable)
            TextButton(
              onPressed: _isLoading ? null : _skip,
              child: Text(
                'SALTA',
                style: GoogleFonts.outfit(color: AppTheme.textMuted, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Rendi uniche le tue feste!',
                    style: GoogleFonts.playfairDisplay(
                      color: AppTheme.accentGold,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Inserisci le tue date importanti. Ti riserveremo delle sorprese speciali per festeggiare insieme!',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  _buildDateSelector('Compleanno', _birthday, (d) => setState(() => _birthday = d)),
                  _buildDateSelector('Onomastico', _nameDay, (d) => setState(() => _nameDay = d)),
                  _buildDateSelector('Data Speciale / Anniversario', _anniversary, (d) => setState(() => _anniversary = d)),
                  
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: (_birthday == null && _nameDay == null && _anniversary == null) ? null : _saveDates,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: AppTheme.backgroundDark,
                      disabledBackgroundColor: AppTheme.surfaceDark,
                      disabledForegroundColor: AppTheme.textMuted,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'SALVA E CONTINUA',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
