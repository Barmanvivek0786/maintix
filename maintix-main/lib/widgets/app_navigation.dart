import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';
import 'package:provider/provider.dart';

// V2 Floating Pill BottomNav — Bold/Premium family
class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  final List<_TabSpec> _tabs = [
    _TabSpec(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Book',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today_rounded,
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'Reviews',
      icon: Icons.star_outline_rounded,
      selectedIcon: Icons.star_rounded,
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      branchIndex: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.primaryNavy,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryNavy.withAlpha(89),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final tab = _tabs[index];
            final isActive = tab.branchIndex == currentIndex;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (tab.branchIndex == null) return;
                  // When tapping the Booking tab, reset cart so it always shows fresh flow
                  if (tab.branchIndex == 1) {
                    context.read<AppState>().resetCart();
                  }
                  widget.navigationShell.goBranch(
                    tab.branchIndex!,
                    initialLocation: tab.branchIndex == currentIndex,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.tealAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? tab.selectedIcon : tab.icon,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withAlpha(140),
                        size: isActive ? 22 : 20,
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive
                              ? Colors.white
                              : Colors.white.withAlpha(140),
                        ),
                        child: Text(tab.label),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int? branchIndex;

  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.branchIndex,
  });
}
