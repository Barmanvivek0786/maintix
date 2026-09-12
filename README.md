# Flutter

A modern Flutter-based mobile application utilizing the latest mobile development technologies and tools for building responsive cross-platform applications.

## 📋 Prerequisites

- Flutter SDK (^3.38.4)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)

## 🛠️ Installation and configuration

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Copy `env.example.json` to `env.json` and replace the placeholders with
   values from the same Supabase project. `env.json` is ignored by Git and must
   never be committed.

3. Run the application:
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

The app intentionally has no fallback Supabase key. It validates that the
Supabase URL is HTTPS and that a JWT key belongs to the same project before
initializing. This prevents a build from silently using a different or stale
project configuration.

### GitHub Actions release build

The workflow in `.github/workflows/build_release.yml` builds the signed Android
App Bundle with Flutter 3.38.4. Add these repository secrets before pushing to
`main` or `master`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (or the project's `sb_publishable_...` key)
- `RAZORPAY_KEY_ID`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEYSTORE_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

The workflow calls Supabase Auth before compiling. If the URL/key pair is
missing or rejected, it stops without producing an AAB. Do not reuse the
previous committed values; the Supabase project owner should issue a current
key and rotate any credentials that were committed previously.

## 📁 Project Structure

```
flutter_app/
├── android/            # Android-specific configuration
├── ios/                # iOS-specific configuration
├── lib/
│   ├── core/           # Core utilities and services
│   │   └── utils/      # Utility classes
│   ├── presentation/   # UI screens and widgets
│   │   └── splash_screen/ # Splash screen implementation
│   ├── routes/         # Application routing
│   ├── theme/          # Theme configuration
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # Application entry point
├── assets/             # Static assets (images, fonts, etc.)
├── pubspec.yaml        # Project dependencies and configuration
└── README.md           # Project documentation
```

## 🧩 Adding Routes

To add new routes to the application, update the `lib/routes/app_routes.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:package_name/presentation/home_screen/home_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    // Add more routes as needed
  }
}
```

## 🎨 Theming

This project includes a comprehensive theming system with both light and dark themes:

```dart
// Access the current theme
ThemeData theme = Theme.of(context);

// Use theme colors
Color primaryColor = theme.colorScheme.primary;
```

The theme configuration includes:
- Color schemes for light and dark modes
- Typography styles
- Button themes
- Input decoration themes
- Card and dialog themes

## 📱 Responsive Design

The app is built with responsive design using the Sizer package:

```dart
// Example of responsive sizing
Container(
  width: 50.w, // 50% of screen width
  height: 20.h, // 20% of screen height
  child: Text('Responsive Container'),
)
```
## 📦 Deployment

Build the application for production:

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release
```

## 🙏 Acknowledgments
- Built with [Rocket.new](https://rocket.new)
- Powered by [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- Styled with Material Design

Built with ❤️ on Rocket.new
