# Barbary Link

Independent Android and Windows fork for Eslam Elbarbary, based on [NectarLink](https://github.com/thtbee/nectarlink), commit `3eff9a0`.

## Status

Build and test verification is in progress. This repository is source code, not a signed app release. Do not install an original NectarLink download expecting it to be Barbary Link. The requested APK, unpublished Play AAB and Windows installer are supplied separately after verification and signing.

## Fork changes

- App name: **Barbary Link**, version 1.0.0.
- Independent phone-and-monitor icon and Windows installer identity.
- Android application ID: `com.eslamelbarbary.wasla`.
- Owner credit, Facebook and Telegram links.
- Original-project automatic update and APK-download paths are disabled. Updates must be installed manually from a Barbary Link build signed with the same Android key.
- The Windows installer includes `Barbary-Link.apk` for its phone-install feature. The staged development package does not include it until final assembly.

The upstream feature implementation is retained, including device pairing, files, clipboard, notifications, messages and screen features. Successful compilation is not proof that these work on a particular phone or PC. Device pairing and elevated/optional features need real-device testing.

The UI retains upstream languages and is **not fully translated into Arabic**. The source-page QR code opens this fork's code, not an APK download page.

## Build and verification

See [BARBARY-LINK.md](BARBARY-LINK.md) for toolchains and build commands. The manual `Barbary Link build` workflow can build Android, Windows or both, using standard runners. It does not contain signing keys, passwords or automatic publishing jobs.

Android release outputs are unsigned unless a keystore is supplied locally. Never commit credentials or signing keys. Keep the Android signing key safe, because future updates need the same key.

Windows checks include native compilation, a fork-update-isolation test, UI checks with synthetic phone data and screenshots, and a preflight installer test. Check actual job results before claiming any test passed. The final installer adds the separately signed Android APK after those preflight checks. Windows Authenticode signing is not configured.

## Licenses and attribution

The Android and desktop applications remain **GPL-3.0-or-later**. Core licensing remains **MPL-2.0** where specified upstream. Original copyright notices and third-party notices are retained in [LICENSE](LICENSE), `LICENSES/`, and the source files. This fork is not affiliated with the original project.

[UPSTREAM-README.md](UPSTREAM-README.md) preserves the original documentation. Its original-product download links and screenshots are reference material, not Barbary Link artifacts or proof of this fork's tests.
