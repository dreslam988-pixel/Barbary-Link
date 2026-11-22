# Barbary Link: build and test record

Date: 2026-11-22. Product version: 1.0.0.

## Provenance

The distributed Android and native Windows application code was compiled from commit `1b066ad`. The source handoff also contains later documentation, a corrected crash-signature test fixture, an additional Rust test vector, installer publisher metadata, QA fixture settings, and complete original license texts in the delivery packages. Those later edits do not alter Android production code or the native Windows executable code.

The license texts are added as assets without changing any existing Android ZIP entry. They are also included in the Windows installer as a LICENSES directory.

All-platform run:
https://github.com/dreslam988-pixel/Barbary-Link/actions/runs/45030484144

Android emulator run:
https://github.com/dreslam988-pixel/Barbary-Link/actions/runs/45030486290

## Android

- Release APK and AAB compiled successfully.
- Package: `com.eslamelbarbary.wasla`, version 1.0.0, code 10000999, minSDK 26, targetSDK 37.
- Both ARM64 and ARMv7 native cores are included.
- The AAB passed bundletool validation and manifest inspection before signing.
- The emulator check used Android 15/API35, an optimized x86_64 release APK, and a disposable CI certificate.
- Welcome setup was skipped, Home and Settings were reached, and no crash was recorded by the check.
- Optimized `classes.dex` SHA-256 in both the emulator APK and the ARM release APK: `85441f02a15f2d83bc6c26540ef37e776adea8093f377160842992368d47102f`.
- This equality covers Kotlin/Java bytecode, not equality of native ARM and x86_64 libraries or signing certificates.
- Actual screenshots were inspected. At the narrow 320px emulator width, some Settings labels wrap awkwardly and category tabs are partially clipped. Horizontal scrolling was not checked. This is not full layout QA across devices.

### Unit test fixture

The CI release unit suite ran 250 tests: 249 passed and one failed. `CrashesTest.signaturesMatchTheCores` had its example class name changed to this fork's namespace while retaining the upstream expected hash.

The algorithm hashes UTF-8 input parts with a zero byte after each part, then takes the first six SHA-256 bytes. Independent calculation confirmed:

- Upstream sample class: `b3af6c6e31db`.
- Fork sample class: `bf0aaea7068b`.

The expected value was corrected in the test source. A focused Kotlin/JUnit rerun, using the unchanged production signature function and the corrected test method, passed. A separate legacy-vector JUnit test passed too. The matching Rust signature function and its test with both vectors also passed in a focused Rust run.

The complete 250-test suite was not rerun after that fixture-only correction. The original CI run therefore still records a failed Android test step. It is not described here as a fully green rerun.

## Windows

The Windows job passed:

- Native release compilation and Qt staging.
- Fork self-update isolation test.
- Actual rendered Home captures, using synthetic offline phone data. The initial walkthrough-labelled pass also showed Home because the synthetic phone triggered the existing-user walkthrough shortcut. A test-fixture setting now avoids that shortcut for subsequent validation; the original run does not establish walkthrough coverage.
- Preflight installer creation.
- Silent installation, application launch, shortcuts/firewall checks and uninstallation.

The preflight did not contain the separately signed Android APK. The final installer adds that APK, the full LICENSES directory, and changes the installer CompanyName/installed-app Publisher to the Arabic owner brand. These final assembly differences were not executed in a Windows install test.

A focused repeat validation reused the same native binaries with the corrected fixture and owner Publisher metadata:
https://github.com/dreslam988-pixel/Barbary-Link/actions/runs/45036570329

It passed install/update/launch/shortcuts/firewall/uninstall checks. Its actual Home and one walkthrough page captures were inspected. This establishes that visible walkthrough page, not every onboarding step or Windows Settings.

The final installer is intended to be one self-contained x64 EXE. It is not Authenticode-signed with a trusted publisher certificate.

## Not established

No physical Android phone, physical phone-to-PC pairing, ARM runtime launch, calls, SMS, file transfer, clipboard synchronization, screen streaming, webcam, credential provider or elevated permissions have been verified end to end. No measured performance or battery results are claimed.

The core UI is not fully Arabic. The inspected screens were English; Arabic owner/community text and the Arabic infographic are separate branding/content.

No Play Store, other app store or GitHub Release was published as part of this handoff. Signed delivery hashes and the Android certificate fingerprint are recorded separately with the final files.
