# Maintix project notes

## Supabase configuration

Supabase is initialized once in `lib/services/supabase_service.dart` using the
Maintix project's public URL and a compile-time anon key. The anon key is
loaded from the `SUPABASE_ANON_KEY` workspace secret by
`tool/flutter_with_env.sh`; it is intentionally not stored in source control.
The anon key is a public client credential; never put a Supabase service-role
key in the app.

For local development:

```bash
bash tool/flutter_with_env.sh run
```

Use a URL and key from the same Supabase project. The app rejects non-HTTPS
Supabase URLs and mismatched JWT project references before making auth calls.
The wrapper also supports `build apk`, `build ios`, `analyze`, and other
Flutter subcommands.

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