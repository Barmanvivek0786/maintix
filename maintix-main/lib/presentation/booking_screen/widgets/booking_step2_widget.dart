import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';

class BookingStep2Widget extends StatefulWidget {
  final VoidCallback onNext;
  const BookingStep2Widget({required this.onNext, super.key});

  @override
  State<BookingStep2Widget> createState() => _BookingStep2WidgetState();
}

class _BookingStep2WidgetState extends State<BookingStep2Widget> {
  // TODO: Replace with Riverpod/Bloc for production
  int _selectedDateIndex = 0;
  String? _selectedTimeSlot;

  late final List<DateTime> _nextSevenDays;

  static const List<String> _timeSlots = [
    '8:00 AM – 10:00 AM',
    '10:00 AM – 12:00 PM',
    '12:00 PM – 2:00 PM',
    '2:00 PM – 4:00 PM',
    '4:00 PM – 6:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _nextSevenDays = List.generate(7, (i) => today.add(Duration(days: i)));
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE d MMM').format(date);
  }

  String _formatFullDate(DateTime date) {
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _nextSevenDays[_selectedDateIndex];
    final monthName = DateFormat('MMMM yyyy').format(selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Date',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose your preferred service date',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Month label
          Text(
            monthName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Date chips
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _nextSevenDays.length,
              itemBuilder: (context, index) {
                final date = _nextSevenDays[index];
                final isSelected = _selectedDateIndex == index;
                final isToday = index == 0;
                final parts = _formatDate(date).split(' ');

                return Padding(
                  padding: EdgeInsets.only(right: index < 6 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedDateIndex = index);
                      context.read<AppState>().updateCartDate(
                        _formatFullDate(date),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryNavy
                            : AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryNavy
                              : AppTheme.divider,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppTheme.primaryNavy.withAlpha(51)
                                : AppTheme.cardShadow,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            parts[0],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white.withAlpha(179)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            parts[1],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          if (isToday)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.tealAccent
                                    : AppTheme.tealLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Today',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.tealAccent,
                                ),
                              ),
                            )
                          else
                            Text(
                              parts.length > 2 ? parts[2] : '',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: isSelected
                                    ? Colors.white.withAlpha(153)
                                    : AppTheme.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Select Time Slot',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'All slots available for your selected date',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Time slots grid
          Column(
            children: _timeSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedTimeSlot = slot);
                    context.read<AppState>().updateCartTime(slot);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.tealAccent
                          : AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.tealAccent
                            : AppTheme.divider,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppTheme.tealAccent.withAlpha(51)
                              : AppTheme.cardShadow,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.tealAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            slot,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withAlpha(51)
                                : AppTheme.success.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Available',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.success,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedTimeSlot != null ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealAccent,
                disabledBackgroundColor: AppTheme.divider,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue to Address',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _selectedTimeSlot != null
                          ? Colors.white
                          : AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: _selectedTimeSlot != null
                        ? Colors.white
                        : AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
