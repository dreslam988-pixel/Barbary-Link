# Barbary Link 1.1.0, Android Arabic UI

## Scope

This revision changes the Android interface, not the Rust connection core or the desktop app. The previously delivered Windows companion remains version 1.0.0 and English.

- Arabic resources cover every translatable Android string and all eight plural groups.
- Arabic and right-to-left layout are the default, including Android 8-12. Android 13 and newer retain the per-app language selector.
- A one-time appearance migration selects a quiet graphite dark theme. Later appearance changes remain under the user's control.
- The five-stage setup wizard becomes optional from Settings. No permission is granted automatically.
- First-use Home shows the three steps for connecting a PC, with a clear pairing button.
- The paired-PC card puts PC control, file transfer and clipboard actions first.
- Camera, shortcut deck, desk clock, audio and power tools remain under More tools. Active microphone/audio sessions reveal the fold automatically.
- Promotional Home cards no longer compete with setup. Project links and license notices remain in About.
- Button labels can use two lines with a 12sp minimum rather than squeezing Arabic into one tiny line.
- Android application ID is unchanged: `com.eslamelbarbary.wasla`. Version is 1.1.0, versionCode 10100999. The release must use the existing 1.0.0 signing certificate.

## Validation plan and boundaries

The Android build workflow compiles ARM64/ARMv7 APK and AAB and runs the full release unit-test suite. The separate UI workflow launches an optimized x86_64 release build on a free standard-runner Android API 35 and API 30 emulators, captures Arabic Home, Guide and Settings, and checks for crashes.

A separate `src/debug` screenshot fixture renders a synthetic connected PC so the simplified card and More tools fold can be inspected without a physical PC. This fixture is not part of the shipped release and does not prove pairing or transport works. Its screenshots must not be represented as a real device connection.

Source-resource completeness and format placeholders are checked before build. Final pixel review, runner results, artifact hashes and signing verification are recorded separately after they complete. The older BUILD-TEST-REPORT.md describes version 1.0.0 only.

No physical Redmi Note 10S, real phone-to-PC pairing, calls, SMS, file transfer, screen streaming, webcam or elevated-permission operation is claimed to have been tested by this UI revision.

## License

The fork keeps its distinct Barbary Link name and owner branding, upstream copyright notices, GPL-3.0-or-later license and bundled third-party license texts. Arabic interface translations and UI changes are provided under GPL-3.0-or-later.
