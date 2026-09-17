# Maintix project notes

## Supabase configuration

Supabase is initialized once in `lib/services/supabase_service.dart`. The
project's default URL and publishable anon key are embedded for launches that
omit Dart defines. `SUPABASE_URL` and `SUPABASE_ANON_KEY` can still override
those defaults at compile time for another environment.

For local development:

```bash
cp env.example.json env.json
flutter run --dart-define-from-file=env.json
```

Use a URL and key from the same Supabase project when overriding the defaults.
The app rejects non-HTTPS Supabase URLs and mismatched JWT project references
before making auth calls.

## Splash screen

The Android launch screen explicitly keeps fullscreen disabled and constrains
the centered logo to a 280dp square so the native preload cannot stretch it to
the device dimensions.

## Android release builds

The canonical release workflow is
`.github/workflows/build_release.yml`. It validates Supabase Auth before
building and passes the signing values through environment variables. Required
GitHub Actions secrets are documented in `README.md`.