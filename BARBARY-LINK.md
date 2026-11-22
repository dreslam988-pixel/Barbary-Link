# Barbary Link 1.0.0 (Android)

Independent modification for Eslam Elbarbary, based on NectarLink commit 3eff9a0.
Original project: https://github.com/thtbee/nectarlink

Android package: com.eslamelbarbary.wasla
Android source namespace: com.eslamelbarbary.wasla.android
Upstream wire protocol identifiers are retained for compatibility.

Changes: independent app name, package, original icon, owner credit and owner social links.
The app UI remains primarily in the upstream languages. This is not a complete Arabic translation.
Automatic installation of original-project updates is disabled in this fork. Update it manually with a same-key Barbary Link release.
Upstream licenses and copyright notices are retained in LICENSE and LICENSES.
The Android and desktop applications remain GPL-3.0-or-later; core licenses remain unchanged.

Windows source branding is preparatory; no Windows binary was compiled or tested in this environment.
Do not publish a Windows build until the installer identity, update tasks, download targets and complete runtime behavior have been reviewed on Windows.
Android-to-PC pairing requires device testing and is not established by a successful compilation.

No signing keys or passwords belong in this source archive.

## Build notes

Use JDK 21, Android SDK platform 37.0, NDK 30.0.16248370 and Rust 1.100.0 with the aarch64-linux-android target and cargo-ndk. Set ANDROID_HOME and JAVA_HOME.

From android/: `./gradlew :app:assembleDebug -Pnectarlink.abis=arm64-v8a`
For release artifacts: `./gradlew :app:assembleRelease :app:bundleRelease -Pnectarlink.abis=arm64-v8a`
Release signing is not configured in source. Without NECTARLINK_KEYSTORE and NECTARLINK_KEYSTORE_PASSWORD, the release output is unsigned. The key alias is nectarlink. Keep credentials out of source and CI logs.

The FFI source is generated through tools/barbary-bindgen, pinned to UniFFI 0.32.2, and compiled in android/corebindings to reduce peak compilation memory. Its package remains app.nectarlink.core; only Android application code was moved to the new namespace.

The local Android Rust profile currently disables LTO, uses optimization level 1 for dependencies and no optimization for nectarlink-core. This preserved functions but performance has not been measured. Restore upstream Android profile settings for a performance-tested production build on a stronger build machine.

No APK, AAB, unit-test suite or live Android UI has yet passed verification. Do not describe source compilation of individual components as successful application testing.

Upstream GitHub workflows have the .disabled suffix in this handoff so that uploading the source does not automatically launch builds or publishing jobs. Review and authorize any replacement workflow before enabling it.

## Remote build route

The production Rust optimization profile has been restored for GitHub-hosted standard runners. Desktop brand, native icon, installer identity and optional component CLSIDs are now distinct. Windows installers must include the separately signed Barbary-Link.apk beside the desktop executable. Original-project auto-updates and APK downloads are not used.

The manual Barbary Link build workflow compiles Android unsigned release artifacts and runs unit tests. It separately compiles and stages the Windows app, runs the UI-check mode with synthetic demo data and captures previews. Final signing and installer assembly are separate, subsequent steps. Do not call an artifact tested until its job and checks have actually passed.
