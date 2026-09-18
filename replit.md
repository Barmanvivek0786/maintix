# Maintix project notes

## Supabase configuration

Supabase is initialized once in `lib/services/supabase_service.dart`. Both
`SUPABASE_URL` and `SUPABASE_ANON_KEY` are required compile-time Dart defines;
there is intentionally no fallback key.

For local development:

```bash
cp env.example.json env.json
flutter run --dart-define-from-file=env.json
```

Use a URL and key from the same Supabase project. The app rejects non-HTTPS
Supabase URLs and mismatched JWT project references before making auth calls.

## Android release builds

The canonical release workflow is
`.github/workflows/build_release.yml`. It validates Supabase Auth before
building and passes the signing values through environment variables. Required
GitHub Actions secrets are documented in `README.md`.