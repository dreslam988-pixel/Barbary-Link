# Barbary Link

برامج إسلام البربري

Independent Android and Windows fork for Eslam Elbarbary, based on [NectarLink](https://github.com/thtbee/nectarlink), commit `3eff9a0`.

## Distribution

This repository contains source code, not a published signed app release. Verified delivery files are supplied separately: an Android APK, an unpublished AAB, a Windows x64 installer, and a complete project source ZIP. Never install an original NectarLink download expecting it to be Barbary Link.

## Fork changes

- Product name: **Barbary Link**, version 1.0.0.
- Independent phone-and-monitor icons, Android application identity and Windows installer identity.
- Android application ID: `com.eslamelbarbary.wasla`.
- Arabic owner credit and owner community links.
- Original-project automatic update and APK-download paths are disabled. Install future Barbary Link updates manually, signed with the same Android key.
- The final Windows installer includes the separately signed `Barbary-Link.apk` for its phone-install feature.

The upstream feature implementation is retained, including pairing, files, clipboard, notifications, messages and screen features. This does not mean every feature has been tested on real devices.

## Language and testing limits

The core Windows and Android interfaces are **English in the checks performed**, with upstream translations available in Settings. There is **no complete Arabic translation**. Arabic text in the owner/community section and the infographic does not mean the app's controls are Arabic.

Android reached Home and Settings in an Android 15 emulator. Windows passed native compilation, UI screenshots and a preflight install/launch/uninstall check. No physical phone-to-PC pairing, phone permissions, calls, messages, transfers, screen streaming or optional elevated features have been verified end to end.

See [BUILD-TEST-REPORT.md](BUILD-TEST-REPORT.md) for exact results, including the corrected test fixture and the distinction between the tested Windows preflight and the final installer.

## Build

See [BARBARY-LINK.md](BARBARY-LINK.md) for toolchains and commands. The manual build workflow uses standard GitHub-hosted runners. It contains no signing key, password or automatic release/store publication.

Android outputs are unsigned unless a keystore is supplied locally. Never commit credentials. Windows Authenticode signing is not configured.

## Licenses and attribution

The Android and desktop applications remain **GPL-3.0-or-later**. Core licensing remains **MPL-2.0** where specified upstream. Original copyright notices, some component metadata credits and third-party notices are retained in [LICENSE](LICENSE), `LICENSES/`, and the source files. This fork is independent of the original project.

[UPSTREAM-README.md](UPSTREAM-README.md) preserves the original documentation. Its original-product download links and screenshots are reference material, not Barbary Link artifacts or proof of this fork's tests.
