# Barbary Link 1.0.0: build notes

Independent modification for Eslam Elbarbary, based on NectarLink commit `3eff9a0`.
Original project: https://github.com/thtbee/nectarlink

Android ID: `com.eslamelbarbary.wasla`
Android source namespace: `com.eslamelbarbary.wasla.android`
Upstream wire protocol and UniFFI identifiers are retained for compatibility. The optional privileged helper retains its stable Binder API namespace, `app.nectarlink.services`.

## Toolchain

- JDK 21
- Android SDK platform 37.0, build tools 37.0.0
- Android NDK 30.0.16248370
- Rust 1.100.0, cargo-ndk, ARM64 and ARMv7 Android targets
- Windows: Qt 6.12.0, MSVC 2022 x64 kit, NSIS 3

Set `JAVA_HOME` and `ANDROID_HOME`. Follow the pinned versions and dependencies in the manual GitHub Actions workflows and lockfiles.

## Android

From `android/`:

```sh
./gradlew :app:assembleRelease :app:bundleRelease -Pnectarlink.abis=arm64-v8a,armeabi-v7a
./gradlew :app:testReleaseUnitTest -Pnectarlink.abis=arm64-v8a,armeabi-v7a
```

Release outputs are unsigned without local signing credentials. The delivery APK and AAB are signed separately with the same private Android key. The key alias is `nectarlink`; this internal alias is not the installed app name. Keys and passwords are intentionally absent from source and CI.

The FFI source is generated through `tools/barbary-bindgen`, pinned to UniFFI 0.32.2, and compiled in `android/corebindings`. Its namespace remains `app.nectarlink.core`.

The ARM release APK and the emulator test APK had identical optimized `classes.dex` bytes. The emulator used an x86_64 native core and a disposable test certificate, so this does not prove ARM native runtime behavior on a physical phone.

## Windows

Use the manual Windows workflow or `scripts/package.ps1`. Build and stage with `-StageOnly`. Put the separately signed Android APK in the final stage as `Barbary-Link.apk` before assembling the final NSIS installer. This supports the app's phone-install feature without fetching an original-project APK.

Native builds, fork update isolation, visible Home screenshots and a preflight install/launch/uninstall test passed in the referenced run. The final installer is assembled afterward with the signed APK and owner publisher metadata and full original license texts. It must not be described as the exact installer executed by that preflight test.

No trusted Windows Authenticode certificate is present. Windows may show an unknown-publisher warning. Do not disable security tools to work around it.

## Fork isolation and limits

Original-project self-updates are disabled in GUI, direct and elevated update paths. No original updater task is registered. The source-page QR code opens this fork's source, not an APK download page.

App controls retain upstream languages; there is no Arabic locale. Arabic owner/community branding is included. Some original contributor metadata remains as attribution.

Real-device pairing, permissions and optional elevated/helper integration still need device testing. Compilation, emulator launch and synthetic Windows demo data do not establish these functions end to end.

See `BUILD-TEST-REPORT.md` for the exact test record and artifact provenance. No signing key, password or temporary access credential belongs in this archive.
