import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps any widget with a smooth press animation (scale + fade).
///
/// Uses raw pointer events, so it also animates when the child already has
/// its own InkWell / GestureDetector. Pass [onTap] if the child has no tap
/// handler of its own.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.haptic = false,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedScale(
      scale: _pressed ? widget.scale : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.haptic) HapticFeedback.selectionClick();
          widget.onTap!();
        },
        child: content,
      );
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: content,
    );
  }
}

/// Text / icon filled with a brand gradient.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final List<Color> colors;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.colors = const [Color(0xFF00A8CC), Color(0xFF6C63FF)],
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => LinearGradient(colors: colors).createShader(r),
      child: Text(text, style: style),
    );
  }
}
