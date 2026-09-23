import 'package:flutter/material.dart';

/// Maintix full brand logo (name + tagline).
///
/// Loaded directly from the bundled asset (assets/images/maintix_full_logo.png,
/// already declared under `flutter/assets/` in pubspec.yaml) instead of an
/// embedded base64 string. The previous embedded-base64 approach was fragile:
/// a single corrupted/truncated copy-paste silently broke the image on every
/// screen with no visible error. Using the asset file directly means Flutter's
/// own asset pipeline validates the file at build time.
class MaintixLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  const MaintixLogo({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 14,
    this.fit = BoxFit.contain,
  });

  static const String _assetPath = 'assets/images/maintix_full_logo.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        _assetPath,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          // Visible fallback (standalone 'M' mark) instead of a silent blank
          // box, so a future asset problem is obvious immediately.
          return Image.asset(
            'assets/images/maintix_m_logo.png',
            width: width,
            height: height,
            fit: fit,
          );
        },
      ),
    );
  }
}
