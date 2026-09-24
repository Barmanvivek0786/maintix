import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme tokens.
///
/// The neutral tokens (background, surfaceWhite, textPrimary, ...) are
/// getters that resolve to the light or the dark palette depending on
/// [isDark]. [isDark] is updated by [applySystemUI], which the root
/// Consumer<AppState> calls on every theme-mode change; at that point the
/// whole widget tree is force-rebuilt so every screen picks up the new
/// palette (including widgets that never call Theme.of(context)).
///
/// Brand / status colours (tealAccent, success, warning, error) are
/// identical in both themes and stay `const`.
class AppTheme {
  AppTheme._();

  /// Current brightness. Do not set directly; call [applySystemUI].
  static bool isDark = false;

  // -- Brand / status (same in both themes) --
  static const Color tealAccent = Color(0xFF00A8CC);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);

  // -- Light palette --
  static const Color lightNavy = Color(0xFF0F2942);
  static const Color lightNavy2 = Color(0xFF1A3F5C);
  static const Color lightBackground = Color(0xFFF4F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF0F4F8);
  static const Color lightTextPrimary = Color(0xFF1A2B3C);
  static const Color lightTextSecondary = Color(0xFF6B7A8D);
  static const Color lightTextMuted = Color(0xFF9EAAB8);
  static const Color lightDivider = Color(0xFFE8EDF3);
  static const Color lightTealTint = Color(0xFFE0F6FB);
  static const Color lightShadow = Color(0x1A0F2942);
  static const Color lightInputFill = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFFCDD5E0);

  // -- Dark palette (charcoal screen, near-black cards, white text) --
  static const Color darkNavy = Color(0xFF1B1B1B); // headers, nav bar, app bar
  static const Color darkNavy2 = Color(0xFF2A2A2A);
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF0B0B0B);
  static const Color darkSurfaceAlt = Color(0xFF171717);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFA9A9A9);
  static const Color darkTextMuted = Color(0xFF7C7C7C);
  static const Color darkDivider = Color(0xFF2C2C2C);
  static const Color darkTealTint = Color(0xFF10343D);
  static const Color darkShadow = Color(0x40000000);
  static const Color darkInputFill = Color(0xFF181818);
  static const Color darkOutline = Color(0xFF3A3A3A);

  // -- Theme-aware tokens (use these in screens) --
  static Color get primaryNavy => isDark ? darkNavy : lightNavy;
  static Color get headerAlt => isDark ? darkNavy2 : lightNavy2;
  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get surfaceWhite => isDark ? darkSurface : lightSurface;
  static Color get surfaceAlt => isDark ? darkSurfaceAlt : lightSurfaceAlt;
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textMuted => isDark ? darkTextMuted : lightTextMuted;
  static Color get divider => isDark ? darkDivider : lightDivider;
  static Color get tealLight => isDark ? darkTealTint : lightTealTint;
  static Color get cardShadow => isDark ? darkShadow : lightShadow;

  /// Strong text / icon colour for content sitting on a card or background
  /// (navy in light mode, near-white in dark mode).
  static Color get onSurfaceStrong => isDark ? darkTextPrimary : lightNavy;

  /// Brand gradients for cards, buttons and highlights.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF00A8CC), Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF00A8CC), Color(0xFF0088A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color inputTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkTextPrimary
      : lightTextPrimary;

  static Color inputFillColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkInputFill
      : lightInputFill;

  /// Call whenever the theme mode changes. Updates [isDark], keeps the status
  /// bar / navigation bar icons readable and forces a full rebuild so that
  /// every widget re-reads the palette.
  static void applySystemUI(ThemeMode mode) {
    final dark = mode == ThemeMode.dark;
    final changed = dark != isDark;
    isDark = dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    if (changed) _rebuildEverything();
  }

  static void _rebuildEverything() {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }

      binding.rootElement?.visitChildren(rebuild);
    });
    binding.ensureVisualUpdate();
  }

  static ThemeData get lightTheme => _buildTheme(dark: false);
  static ThemeData get darkTheme => _buildTheme(dark: true);

  static TextTheme _textTheme(Color p, Color s, Color m) {
    TextStyle t(double size, FontWeight w, Color c) =>
        TextStyle(fontSize: size, fontWeight: w, color: c);
    return GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        displayLarge: t(32, FontWeight.w700, p),
        displayMedium: t(28, FontWeight.w700, p),
        displaySmall: t(24, FontWeight.w700, p),
        headlineLarge: t(22, FontWeight.w700, p),
        headlineMedium: t(20, FontWeight.w600, p),
        headlineSmall: t(18, FontWeight.w600, p),
        titleLarge: t(16, FontWeight.w600, p),
        titleMedium: t(15, FontWeight.w600, p),
        titleSmall: t(14, FontWeight.w500, p),
        bodyLarge: t(15, FontWeight.w400, p),
        bodyMedium: t(14, FontWeight.w400, p),
        bodySmall: t(12, FontWeight.w400, s),
        labelLarge: t(14, FontWeight.w600, p),
        labelMedium: t(12, FontWeight.w600, s),
        labelSmall: t(11, FontWeight.w500, m),
      ),
    );
  }

  static ThemeData _buildTheme({required bool dark}) {
    final navy = dark ? darkNavy : lightNavy;
    final bg = dark ? darkBackground : lightBackground;
    final surface = dark ? darkSurface : lightSurface;
    final textP = dark ? darkTextPrimary : lightTextPrimary;
    final textS = dark ? darkTextSecondary : lightTextSecondary;
    final textM = dark ? darkTextMuted : lightTextMuted;
    final dividerColor = dark ? darkDivider : lightDivider;
    final outline = dark ? darkOutline : lightOutline;
    final fill = dark ? darkInputFill : lightInputFill;

    final ColorScheme scheme = dark
        ? ColorScheme.dark(
            primary: tealAccent,
            onPrimary: Colors.white,
            primaryContainer: darkTealTint,
            onPrimaryContainer: lightTealTint,
            secondary: tealAccent,
            onSecondary: Colors.white,
            secondaryContainer: darkTealTint,
            onSecondaryContainer: lightTealTint,
            surface: surface,
            onSurface: textP,
            surfaceContainerLowest: bg,
            surfaceContainerLow: surface,
            surfaceContainer: surface,
            surfaceContainerHigh: surface,
            surfaceContainerHighest: darkInputFill,
            onSurfaceVariant: textS,
            error: Color(0xFFCF6679),
            onError: Colors.white,
            outline: darkOutline,
            outlineVariant: darkDivider,
          )
        : ColorScheme.light(
            primary: lightNavy,
            onPrimary: Colors.white,
            primaryContainer: lightTealTint,
            onPrimaryContainer: lightNavy,
            secondary: tealAccent,
            onSecondary: Colors.white,
            secondaryContainer: lightTealTint,
            onSecondaryContainer: lightNavy,
            surface: lightSurface,
            onSurface: lightTextPrimary,
            surfaceContainerHighest: lightBackground,
            onSurfaceVariant: lightTextSecondary,
            error: error,
            onError: Colors.white,
            outline: lightOutline,
            outlineVariant: lightDivider,
            inverseSurface: lightNavy,
            onInverseSurface: Colors.white,
          );

    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: surface,
      // Tap / hover / focus feedback everywhere (buttons, list tiles, InkWells)
      splashFactory: InkRipple.splashFactory,
      splashColor: tealAccent.withAlpha(48),
      highlightColor: tealAccent.withAlpha(22),
      hoverColor: tealAccent.withAlpha(20),
      focusColor: tealAccent.withAlpha(26),
      // Smooth animated screen transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: _textTheme(textP, textS, textM),
      appBarTheme: AppBarThemeData(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tealAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          animationDuration: const Duration(milliseconds: 250),
          overlayColor: Colors.white.withAlpha(38),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: fill,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(outline),
        enabledBorder: border(outline),
        focusedBorder: border(tealAccent, 2),
        errorBorder: border(dark ? Color(0xFFCF6679) : error),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: textS),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: dark ? textS : textM,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: tealAccent,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: dark ? textP : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        side: BorderSide(color: outline),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: DividerThemeData(color: dividerColor, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
