import 'dart:ui';
import 'package:flutter/material.dart';

/// Central place for the "premium" visual language used across
/// Home, Booking, Reviews and Profile: deep midnight-blue -> teal/cyan
/// gradients, glassmorphism, soft glows and consistent radii.
class AppGradients {
  AppGradients._();

  static const Color midnight = Color(0xFF0A1A33);
  static const Color midnight2 = Color(0xFF0F2A4A);
  static const Color teal = Color(0xFF14C8C8);
  static const Color cyan = Color(0xFF2EE6D6);

  /// Header / hero gradient (Profile header, Home hero card).
  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnight, midnight2, Color(0xFF0E3A52)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Card gradient with a subtle glowing overlay (Reviews cards, offer banners).
  static LinearGradient card({double glow = 0.12}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          midnight.withOpacity(0.95),
          midnight2.withOpacity(0.95),
          teal.withOpacity(glow),
        ],
      );

  /// Thin gradient border used to give containers a glassmorphism edge.
  static LinearGradient border = LinearGradient(
    colors: [teal.withOpacity(0.6), cyan.withOpacity(0.15)],
  );

  static List<BoxShadow> softShadow({Color? color}) => [
        BoxShadow(
          color: (color ?? Colors.black).withOpacity(0.18),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: teal.withOpacity(0.06),
          blurRadius: 40,
          offset: const Offset(0, 0),
        ),
      ];
}

/// Frosted-glass gradient container with a gradient border and soft
/// multi-layer shadow. Wrap any card/section in this for the
/// "luxury glassmorphism" look.
class GlassGradientCard extends StatelessWidget {
  const GlassGradientCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.gradient,
    this.padding = const EdgeInsets.all(16),
    this.blurSigma = 12,
  });

  final Widget child;
  final double borderRadius;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppGradients.softShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ?? AppGradients.card(),
              borderRadius: BorderRadius.circular(borderRadius),
              border: GradientBoxBorder(gradient: AppGradients.border, width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Flutter has no built-in gradient border, so this paints one manually.
class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({required this.gradient, this.width = 1.0});

  final Gradient gradient;
  final double width;

  @override
  BorderSide get bottom => BorderSide.none;
  @override
  BorderSide get top => BorderSide.none;

  @override
  void paint(Canvas canvas, Rect rect,
      {TextDirection? textDirection,
      BoxShape shape = BoxShape.rectangle,
      BorderRadius? borderRadius}) {
    final RRect outer = (borderRadius ?? BorderRadius.zero)
        .toRRect(rect)
        .deflate(width / 2);
    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawRRect(outer, paint);
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  BoxBorder scale(double t) => GradientBoxBorder(gradient: gradient, width: width * t);
}

/// Equivalent of Tailwind's `active:scale-95 transition duration-200`:
/// wrap any tappable card/button/nav-item in this for a springy
/// press-down -> bounce-back feel. Purely visual — pass [onTap] through.
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Bottom-nav item with a soft glowing pill indicator when active.
class GlowNavItem extends StatelessWidget {
  const GlowNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: active
              ? LinearGradient(
                  colors: [AppGradients.teal, AppGradients.cyan],
                )
              : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppGradients.teal.withOpacity(0.45),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.white : Colors.white70, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
                color: active ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
