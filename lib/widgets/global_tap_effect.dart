import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// App-wide tap animation.
///
/// Sits once at the root of the app. On every pointer-down it finds the
/// tappable widget under the finger (buttons, cards, list rows, icons, text
/// links - anything that handles onTap) and plays a gradient glow + soft
/// expanding outline over it. No per-screen changes are needed, so every
/// section and function of the app gets the effect automatically.
class GlobalTapEffect extends StatefulWidget {
  final Widget child;
  const GlobalTapEffect({super.key, required this.child});

  @override
  State<GlobalTapEffect> createState() => _GlobalTapEffectState();
}

class _GlobalTapEffectState extends State<GlobalTapEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    reverseDuration: const Duration(milliseconds: 420),
  );
  Rect? _rect;
  Offset? _down;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onDown(PointerDownEvent e) {
    try {
      final result = HitTestResult();
      WidgetsBinding.instance.hitTestInView(result, e.position, e.viewId);
      RenderBox? target;
      for (final entry in result.path) {
        final t = entry.target;
        if (t is RenderSemanticsGestureHandler &&
            t.onTap != null &&
            t.hasSize) {
          target = t;
          break;
        }
      }
      final root = context.findRenderObject();
      if (target == null || root is! RenderBox || !root.hasSize) return;
      final rect = target.localToGlobal(Offset.zero, ancestor: root) &
          target.size;
      // Ignore huge touch areas (full-screen taps / backdrops).
      if (rect.width * rect.height > root.size.width * root.size.height * 0.5) {
        return;
      }
      _rect = rect;
      _down = e.position;
      _c.forward();
    } catch (_) {
      // Never let a visual effect break input handling.
    }
  }

  void _onMove(PointerMoveEvent e) {
    final d = _down;
    if (d != null && (e.position - d).distance > 14) {
      _down = null;
      _c.reverse();
    }
  }

  void _release() {
    _down = null;
    if (_c.value > 0) _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) {
                  final r = _rect;
                  if (r == null || _c.value == 0) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(painter: _TapPainter(r, _c.value));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TapPainter extends CustomPainter {
  final Rect rect;
  final double t;
  _TapPainter(this.rect, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeOut.transform(t);
    final rr = RRect.fromRectAndRadius(
      rect.inflate(3 * eased),
      Radius.circular((rect.shortestSide / 2).clamp(0.0, 16.0)),
    );
    // Gradient fill (teal -> violet)
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF00A8CC).withAlpha((70 * eased).round()),
            const Color(0xFF6C63FF).withAlpha((60 * eased).round()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rr.outerRect),
    );
    // Soft glowing outline
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF00A8CC).withAlpha((150 * eased).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_TapPainter old) => old.t != t || old.rect != rect;
}
