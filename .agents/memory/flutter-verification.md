---
name: Flutter verification
description: Environment constraint for verifying imported Flutter projects
---

Imported Flutter projects may include Android and iOS source but not the Flutter
or Dart SDK in the workspace. Static XML, asset, and source checks are still
possible, but a real emulator boot, `flutter analyze`, and dependency
resolution require a Flutter-enabled environment.

**Why:** The SDK binaries were unavailable while verifying this project, so
claiming a successful mobile boot from static inspection would be misleading.

**How to apply:** Check for `flutter` and `dart` before attempting runtime
verification; report the limitation if they are absent rather than installing a
second toolchain or claiming the app was run.