import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';

class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _logoController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // If already logged in via Supabase session, go to home
      if (SupabaseService.instance.isLoggedIn && mounted) {
        context.go(AppRoutes.homeScreen);
        return;
      }
      // If OTP was sent before app was minimized, restore OTP screen
      await _checkPersistedOtpState();
    });
  }

  Future<void> _checkPersistedOtpState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final otpSent = prefs.getBool('otp_sent') ?? false;
      final otpEmail = prefs.getString('otp_email') ?? '';
      if (otpSent && otpEmail.isNotEmpty && mounted) {
        context.push(AppRoutes.otpVerifyScreen, extra: otpEmail);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.instance.sendOtp(_emailController.text.trim());
      if (mounted) {
        context.push(
          AppRoutes.otpVerifyScreen,
          extra: _emailController.text.trim(),
        );
      }
    } catch (e) {
  if (mounted) {
    setState(() {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    });
  }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.primaryNavy,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top brand section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(26),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppTheme.tealAccent.withAlpha(102),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                'assets/images/maintix-1787987681965.png',
                                width: 160,
                                height: 160,
                                fit: BoxFit.cover,
                                cacheWidth: 320,
                                cacheHeight: 320,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    'M',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 52,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.tealAccent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Maintix',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your All-in-One Home Maintenance Partner',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white.withAlpha(179),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Form card
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 500),
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign In / Register',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your email address to receive a one-time password',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.tealAccent.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.tealAccent.withAlpha(64),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: AppTheme.tealAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'A 6-digit OTP will be sent to your email. No password needed!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'you@example.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppTheme.tealAccent,
                              size: 20,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(v.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.error.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppTheme.error,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: AppTheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.tealAccent,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Send OTP →',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Text(
                            'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
