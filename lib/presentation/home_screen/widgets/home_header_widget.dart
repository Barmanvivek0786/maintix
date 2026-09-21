import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  void _showLocationBottomSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LocationBottomSheet(appState: appState),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final coins = appState.coinBalance;
    final liveLocation = appState.liveLocation;
    final locationLoading = appState.locationLoading;
    final locationDenied = appState.locationPermissionDenied;
    final isDark = appState.themeMode == ThemeMode.dark;

    // Determine display text for location chip
    String locationText;
    if (locationLoading) {
      locationText = 'Fetching location...';
    } else if (liveLocation.isNotEmpty) {
      final parts = liveLocation.split(',');
      locationText = parts.take(2).map((s) => s.trim()).join(', ');
    } else {
      locationText = 'Set Location';
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.light,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryNavy, Color(0xFF1A3F5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // Use SafeArea padding to avoid status bar overlap
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/maintix_full_logo.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        // Full-resolution decode + high quality scaling so the
                        // logo stays sharp on high-density (FHD+) screens.
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.tealAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'M',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Day 👋',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white.withAlpha(179),
                            ),
                          ),
                          Text(
                            'Welcome Back!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Coin chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(31),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(51)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '$coins',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Location row — tappable: opens bottom sheet
                InkWell(
                  onTap: locationDenied
                      ? () => appState.fetchAndSaveLocation()
                      : () => _showLocationBottomSheet(context, appState),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: locationDenied
                            ? Colors.orange.withAlpha(150)
                            : Colors.white.withAlpha(38),
                      ),
                    ),
                    child: Row(
                      children: [
                        locationLoading
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.tealAccent,
                                ),
                              )
                            : Icon(
                                locationDenied
                                    ? Icons.location_off_rounded
                                    : Icons.location_on_rounded,
                                color: locationDenied
                                    ? Colors.orange
                                    : AppTheme.tealAccent,
                                size: 16,
                              ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            locationDenied
                                ? 'Enable GPS / Retry'
                                : locationText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: locationDenied
                                  ? Colors.orange
                                  : Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (!locationLoading) ...[
                          const SizedBox(width: 4),
                          Icon(
                            locationDenied
                                ? Icons.refresh_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: locationDenied
                                ? Colors.orange
                                : Colors.white.withAlpha(179),
                            size: 18,
                          ),
                        ],
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

class _LocationBottomSheet extends StatefulWidget {
  final AppState appState;
  const _LocationBottomSheet({required this.appState});

  @override
  State<_LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<_LocationBottomSheet> {
  bool _refreshing = false;

  Future<void> _refreshLocation() async {
    setState(() => _refreshing = true);
    await widget.appState.fetchAndSaveLocation();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final location = widget.appState.liveLocation;
        final lat = widget.appState.locationLatitude;
        final lon = widget.appState.locationLongitude;
        final denied = widget.appState.locationPermissionDenied;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: AppTheme.tealAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live Location',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Full address (reverse geocoded — human readable)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT ADDRESS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      denied
                          ? 'Location permission denied. Tap Refresh to retry.'
                          : (location.isNotEmpty
                                ? location
                                : 'Location not yet fetched'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: denied ? Colors.orange : AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Refresh button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _refreshing ? null : _refreshLocation,
                  icon: _refreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    _refreshing ? 'Refreshing...' : 'Refresh Live Location',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
