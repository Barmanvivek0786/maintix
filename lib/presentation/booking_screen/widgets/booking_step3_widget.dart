import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';

class BookingStep3Widget extends StatefulWidget {
  final VoidCallback onNext;
  const BookingStep3Widget({required this.onNext, super.key});

  @override
  State<BookingStep3Widget> createState() => _BookingStep3WidgetState();
}

class _BookingStep3WidgetState extends State<BookingStep3Widget> {
  // TODO: Replace with Riverpod/Bloc for production
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill from whatever is already on this booking (if the user went
    // back a step) or, failing that, from the user's fetched GPS location /
    // saved profile phone — so the user only has to review & tweak instead
    // of retyping their address and number from scratch every booking.
    final appState = context.read<AppState>();
    final cart = appState.cartState;

    _addressController.text = cart.address.isNotEmpty
        ? cart.address
        : appState.liveLocation;
    _landmarkController.text = cart.landmark;

    final prefillPhone = cart.phone.isNotEmpty
        ? cart.phone
        : appState.userPhone;
    final digitsOnly = prefillPhone.replaceAll(RegExp(r'[^0-9]'), '');
    // Drop a leading country code (91) if present, keep the last 10 digits.
    _phoneController.text = digitsOnly.length > 10
        ? digitsOnly.substring(digitsOnly.length - 10)
        : digitsOnly;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AppState>().updateCartAddress(
        address: _addressController.text.trim(),
        landmark: _landmarkController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Address Details',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.inputTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Our technician will arrive at this address',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Full Address
            _fieldLabel('Full Address *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.inputTextColor(context),
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 12, Gandhi Nagar, Near Bus Stand, Satna',
                helperText: appState.liveLocation.isNotEmpty
                    ? 'Auto-filled from your current location — edit if needed'
                    : 'Include house number, street, colony name',
                helperStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.tealAccent,
                    size: 20,
                  ),
                ),
                suffixIcon: appState.locationLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Refresh current location',
                        icon: Icon(
                          Icons.my_location_rounded,
                          color: AppTheme.tealAccent,
                          size: 20,
                        ),
                        onPressed: () async {
                          await appState.fetchAndSaveLocation();
                          if (mounted && appState.liveLocation.isNotEmpty) {
                            _addressController.text = appState.liveLocation;
                          }
                        },
                      ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your full address';
                }
                if (v.trim().length < 10) {
                  return 'Please enter a more complete address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Landmark
            _fieldLabel('Landmark (Optional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _landmarkController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.inputTextColor(context),
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Near Birla Temple, Opposite SBI Bank',
                helperText: 'Helps our technician find you faster',
                helperStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
                prefixIcon: Icon(
                  Icons.place_outlined,
                  color: AppTheme.tealAccent,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Phone
            _fieldLabel('Contact Phone *'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppTheme.inputTextColor(context),
              ),
              decoration: InputDecoration(
                hintText: '10-digit mobile number',
                helperText: '10-digit mobile number for technician to contact',
                helperStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
                counterText: '',
                prefixIcon: Icon(
                  Icons.phone_rounded,
                  color: AppTheme.tealAccent,
                  size: 20,
                ),
                prefix: Text(
                  '+91 ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inputTextColor(context),
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your mobile number';
                }
                if (v.trim().length != 10) {
                  return 'Please enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.tealLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.tealAccent.withAlpha(77)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.tealAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We currently service all areas in Satna, MP. Our technician will call 30 minutes before arrival.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.onSurfaceStrong,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tealAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue to Billing',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
