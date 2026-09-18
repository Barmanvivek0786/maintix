# Maintix project notes

## Supabase configuration

Supabase is initialized once in `lib/services/supabase_service.dart` using the
Maintix project's fixed URL and anon key. Builds do not require Supabase
dart-defines.

For local development:

```bash
flutter run
```

Use a URL and key from the same Supabase project. The app rejects non-HTTPS
Supabase URLs and mismatched JWT project references before making auth calls.

## Android release builds

The canonical release workflow is
`.github/workflows/build_release.yml`. It builds split release APKs, checks
their size, and passes the signing values through environment variables.
Required GitHub Actions secrets are documented in `README.md`.