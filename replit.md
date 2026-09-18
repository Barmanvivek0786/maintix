# Maintix project notes

## Supabase configuration

Supabase is initialized once in `lib/services/supabase_service.dart` using the
Maintix project's public URL and anon key. The checked-in defaults make the
first build work without extra setup; CI or local builds may override them with
`--dart-define=SUPABASE_URL=...` and
`--dart-define=SUPABASE_ANON_KEY=...`. The anon key is a public client
credential; never put a Supabase service-role key in the app.

For local development:

```bash
flutter run
```

Use a URL and key from the same Supabase project. The app rejects non-HTTPS
Supabase URLs and mismatched JWT project references before making auth calls.

## App icons

The supplied Android density icons are installed under
`android/app/src/main/res/mipmap-*`, with the supplied 512x512 image used for
the high-resolution launcher asset. The supplied iOS pixel-size icons are
mapped to `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.

## Android release builds

The canonical release workflow is
`.github/workflows/build_release.yml`. It builds split release APKs, checks
their size, and passes the signing values through environment variables.
Required GitHub Actions secrets are documented in `README.md`.