import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import './widgets/booking_progress_widget.dart';
import './widgets/booking_step1_widget.dart';
import './widgets/booking_step2_widget.dart';
import './widgets/booking_step3_widget.dart';
import './widgets/booking_step4_widget.dart';
import './widgets/booking_step5_widget.dart';
import '../../widgets/gps_enforcement_wrapper.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  bool _wasCartReset = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If cart was reset externally (e.g. tab tap), jump back to step 1
    final cart = context.watch<AppState>().cartState;
    final allEmpty =
        cart.tankQuantities.values.every((q) => q == 0) &&
        cart.selectedDate == null &&
        cart.selectedTimeSlot == null &&
        cart.address.isEmpty;
    if (allEmpty && _currentStep > 0 && !_wasCartReset) {
      _wasCartReset = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentStep = 0);
          _pageController.jumpToPage(0);
        }
      });
    } else if (!allEmpty) {
      _wasCartReset = false;
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _resetToStep1() {
    setState(() => _currentStep = 0);
    _pageController.jumpToPage(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: GpsEnforcementWrapper(
        child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _currentStep < 4
            ? AppBar(
                backgroundColor: AppTheme.primaryNavy,
                elevation: 0,
                leading: _currentStep > 0
                    ? IconButton(
                        onPressed: _prevStep,
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/images/maintix_full_logo.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.water_drop_rounded,
                              color: AppTheme.tealAccent,
                            ),
                          ),
                        ),
                      ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOOKING',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Water Tank Cleaning',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white.withAlpha(179),
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.tealAccent.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Step ${_currentStep + 1}/5',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.tealAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : null,
        body: Column(
          children: [
            if (_currentStep < 4)
              BookingProgressWidget(currentStep: _currentStep),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  BookingStep1Widget(onNext: _nextStep),
                  BookingStep2Widget(onNext: _nextStep),
                  BookingStep3Widget(onNext: _nextStep),
                  BookingStep4Widget(onNext: _nextStep),
                  BookingStep5Widget(onBookAnother: _resetToStep1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
