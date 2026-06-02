import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_theme.dart';
import '../data/services/auth_service.dart';
import '../data/models/user_model.dart';
import 'main_navigation.dart';
import 'register_screen.dart';
import 'admin/admin_main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'claude.monet@bar.it');
  final _passwordController = TextEditingController(text: 'monet123');
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String input = _emailController.text.trim();
      String emailToLogin = input;
      
      // Se non contiene '@', assumiamo sia uno Username
      if (!input.contains('@')) {
        final resolvedEmail = await AuthService().resolveEmailFromUsername(input);
        if (resolvedEmail == null) {
          throw 'Nome utente non trovato.';
        }
        emailToLogin = resolvedEmail;
      }

      final user = await AuthService().login(
        emailToLogin,
        _passwordController.text,
      );

      if (user != null && mounted) {
        _navigateToHome(user);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
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

  void _navigateToHome(UserModel user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Benvenuto, ${user.name}!',
          style: GoogleFonts.outfit(color: AppTheme.backgroundDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.accentGold,
        duration: const Duration(seconds: 2),
      ),
    );

    if (user.role == 'admin') {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AdminMainNavigation(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainNavigation(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
        (route) => false,
      );
    }
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _showPasswordRecoveryDialog() {
    final recoveryEmailController = TextEditingController();
    bool isRecovering = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.accentGold, width: 1),
              ),
              title: Text(
                'Recupero Password',
                style: GoogleFonts.playfairDisplay(color: AppTheme.accentGold, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Inserisci il tuo indirizzo email. Ti invieremo un link per reimpostare la tua password.',
                    style: GoogleFonts.outfit(color: AppTheme.textCream, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: recoveryEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.outfit(color: AppTheme.textCream),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.accentGold),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.accentGold.withAlpha(128)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.accentGold),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isRecovering ? null : () => Navigator.pop(context),
                  child: Text('ANNULLA', style: GoogleFonts.outfit(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isRecovering
                      ? null
                      : () async {
                          final email = recoveryEmailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Inserisci un indirizzo email valido.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => isRecovering = true);

                          try {
                            await AuthService().resetPassword(email);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Email di recupero inviata! Controlla la tua casella di posta.',
                                    style: GoogleFonts.outfit(color: AppTheme.backgroundDark, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: AppTheme.accentGold,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString(), style: GoogleFonts.outfit(color: Colors.white)),
                                  backgroundColor: Colors.redAccent,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setStateDialog(() => isRecovering = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.backgroundDark),
                  child: isRecovering
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.backgroundDark),
                        )
                      : Text('INVIA', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAlternativeLoginOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.accentGold, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Come vuoi accedere?',
              style: GoogleFonts.playfairDisplay(
                color: AppTheme.textCream,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSocialButton(
              title: 'Accedi con Google',
              iconData: Icons.g_mobiledata, // Fallback, consider custom icon for Google
              onPressed: () async {
                Navigator.pop(context); // Chiudi il bottom sheet
                setState(() => _isLoading = true);
                try {
                  final user = await AuthService().signInWithGoogle();
                  if (user != null && mounted) {
                    if (user.isAutoLinked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Bentornato! I tuoi account sono stati uniti in modo sicuro.', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: AppTheme.accentGold,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                    _navigateToHome(user);
                  }
                } on NeedsPasswordForLinkingException catch (e) {
                  if (mounted) {
                    _showLinkAccountDialog(e.credential, e.email);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildSocialButton(
              title: 'Accedi con Apple',
              iconData: Icons.apple,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Accesso con Apple non ancora disponibile', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSocialButton(
              title: 'Accedi con Facebook',
              iconData: Icons.facebook,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Accesso con Facebook non ancora disponibile', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String title,
    required IconData iconData,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        side: const BorderSide(color: AppTheme.accentGold),
        minimumSize: const Size(double.infinity, 50),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      child: Row(
        children: [
          Icon(iconData, color: AppTheme.accentGold, size: 28),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              color: AppTheme.textCream,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.vertical),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo and branding
                Column(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.local_bar,
                        size: 70,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Monet Bar',
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Esperienze d\'Arte da Gustare',
                      style: GoogleFonts.outfit(
                        color: AppTheme.accentGold,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                // Login Form
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ACCESSO FIDELITY',
                          style: GoogleFonts.playfairDisplay(
                            color: AppTheme.textCream,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.outfit(color: AppTheme.textCream),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inserisci la tua email o nome utente';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Email o Nome Utente',
                            hintText: 'Inserisci la tua Email o il tuo Nome Utente',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: Icon(Icons.person_outline, color: AppTheme.accentGold),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.outfit(color: AppTheme.textCream),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci la password';
                            }
                            if (value.length < 6) {
                              return 'La password deve avere almeno 6 caratteri';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Inserisci la tua password',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.accentGold),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppTheme.accentGold.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundDark),
                                  ),
                                )
                              : const Text('ACCEDI'),
                        ),
                        const SizedBox(height: 12),
                        // Register Option Button
                        OutlinedButton(
                          onPressed: _isLoading ? null : _showAlternativeLoginOptions,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: Colors.white24),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('ACCEDI CON UN ALTRO METODO'),
                        ),
                        const SizedBox(height: 12),
                        // Direct register button
                        OutlinedButton(
                          onPressed: _isLoading ? null : _navigateToRegister,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: const BorderSide(color: AppTheme.accentGold),
                            foregroundColor: AppTheme.accentGold,
                          ),
                          child: const Text('NON HAI UN ACCOUNT? REGISTRATI'),
                        ),
                        const SizedBox(height: 12),
                        // Password recovery button
                        TextButton(
                          onPressed: _isLoading ? null : _showPasswordRecoveryDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textMuted,
                          ),
                          child: Text(
                            'Hai dimenticato la password? Recuperala qui',
                            style: GoogleFonts.outfit(decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Mock login tips
                Text(
                  'Usa le credenziali precompilate per provare l\'applicazione.',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLinkAccountDialog(AuthCredential credential, String email) {
    final passwordController = TextEditingController();
    bool isLinking = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.backgroundDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.accentGold, width: 2),
              ),
              title: Text(
                'Account Esistente',
                style: GoogleFonts.playfairDisplay(
                  color: AppTheme.accentGold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'L\'email $email è già associata a un account. Inserisci la tua password per collegare Google a questo account.',
                    style: GoogleFonts.outfit(color: AppTheme.textCream, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    style: GoogleFonts.outfit(color: AppTheme.textCream),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock, color: AppTheme.accentGold),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.accentGold.withAlpha(128)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.accentGold),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLinking ? null : () => Navigator.pop(context),
                  child: Text(
                    'ANNULLA',
                    style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLinking ? null : () async {
                    if (passwordController.text.trim().isEmpty) return;
                    setStateDialog(() => isLinking = true);
                    try {
                      final user = await AuthService().linkGoogleAccount(
                        email,
                        passwordController.text.trim(),
                        credential,
                      );
                      if (context.mounted && user != null) {
                        Navigator.pop(context); // Chiudi dialog
                        _navigateToHome(user);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    } finally {
                      if (context.mounted) {
                        setStateDialog(() => isLinking = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.backgroundDark,
                  ),
                  child: isLinking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundDark),
                          ),
                        )
                      : Text(
                          'COLLEGA',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
