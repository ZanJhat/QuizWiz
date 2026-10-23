# QuizWiz

QuizWiz is a flashcard and study app built with Flutter. This repository is an
unofficial upgraded and modified version of the original
[QuizWiz project by Dev-Salem](https://github.com/Dev-Salem/quizwiz).

The changes in this fork are maintained by [ZanJhat](https://github.com/ZanJhat).
This project is not affiliated with, endorsed by, or maintained by the original
author.

## What changed in this fork

This fork builds on the original QuizWiz app with additional study, content
creation, and portability features, including:

- Generate flashcards with Gemini AI using a prompt and up to five attachments.
- Configure the Gemini API key and model in the app's Settings screen.
- Add notes, tags, answer choices, and attachments to cards.
- Organize related questions as grouped cards.
- Export and import collections as ZIP files, including bundles containing
  multiple collection ZIP files.
- Choose the order used for review and adjust quiz text size.
- Use sound feedback while practicing.
- Download card-format templates as a text file or ZIP archive.
- Configure light or dark appearance.

The original app's core workflows are also retained: create and manage
collections, review cards using the SM-2 spaced-repetition algorithm, and
practice with multiple-choice or written-answer quizzes.

## Download and install the Android app

You do not need Flutter, Android Studio, or a computer to install a published
APK:

1. Open the [QuizWiz Releases page](https://github.com/ZanJhat/QuizWiz/releases).
2. Open the version you want and expand **Assets**. Download exactly one APK
   for your device:
   - `app-arm64-v8a-release.apk` — recommended for most Android phones and
     tablets made in recent years.
   - `app-armeabi-v7a-release.apk` — for older 32-bit ARM Android devices.
   - `app-x86_64-release.apk` — mainly for x86-64 Android emulators and devices.
3. On your Android device, open the downloaded APK from **Downloads** or your
   browser's download notification.
4. If Android asks, allow your browser or file manager to **Install unknown
   apps**, return to the APK, and tap **Install**. Only install APKs you trust.

You only need one APK; do not install all three. If a release has no APK files
under **Assets**, that version has not published downloadable APKs yet.

## Requirements for building from source

To build the Android APK yourself, install:

- [Git](https://git-scm.com/downloads), to download the source code.
- The [Flutter SDK](https://docs.flutter.dev/get-started/install) and its
  bundled Dart SDK. The project declares Dart `>=3.0.3`; this Android build
  was verified with Flutter 3.47.7 and Dart 3.13.5. Flutter may require Android
  Gradle, Android Gradle Plugin, or Kotlin upgrades in future releases.
- [Android Studio](https://developer.android.com/studio), including the Android
  SDK and Android SDK Command-line Tools. You do not need to install Visual
  Studio or its C++ workload to build the Android app.
- A Java Development Kit (JDK) 17 installation. Flutter can use the JDK bundled
  with Android Studio; check the Java path reported by `flutter doctor -v`.

After installing Flutter and Android Studio, open a terminal and run:

```bash
flutter doctor -v
flutter doctor --android-licenses
```

Accept the Android SDK licenses when prompted. Resolve any Flutter or Android
toolchain errors shown by `flutter doctor` before building. A connected Android
device or emulator is only needed to run the app, not to build APK files.

## Build Android APKs from source

1. Clone this repository and enter its directory:

   ```bash
   git clone https://github.com/ZanJhat/QuizWiz.git
   cd QuizWiz
   ```

2. Check that the terminal is in the project directory, then download the
   project dependencies:

   ```bash
   flutter pub get
   ```

3. Build one APK per Android CPU architecture:

   ```bash
   flutter build apk --release --split-per-abi
   ```

   The command can take several minutes the first time. When it succeeds, Flutter
   prints a `Built ...` line for each APK. The files are created under
   `build/app/outputs/flutter-apk/` in the project directory:

   - `app-armeabi-v7a-release.apk`
   - `app-arm64-v8a-release.apk`
   - `app-x86_64-release.apk`

   The `build/` directory is generated output and is not tracked by Git. Upload
   only the APK files you intend to distribute, for example as assets on a
   GitHub Release.

On Windows PowerShell, the commands are the same. You can confirm the current
project directory with `Get-Location` before starting the build. If you moved
the project and Gradle or Flutter reports stale paths, run `flutter clean`,
then `flutter pub get` and the build command again from the new project
directory. Do not upload APKs from an old project folder.

On Windows, list the APKs created by the build with:

```powershell
Get-ChildItem .\build\app\outputs\flutter-apk\*-release.apk
```

To build a single APK containing all supported ABIs instead, run
`flutter build apk --release`; Flutter writes it as
`build/app/outputs/flutter-apk/app-release.apk`. It is larger than an
architecture-specific APK.

### Release signing

The Android release build configuration in this repository currently signs
release APKs with the Android debug signing key. These APKs can be used for
local testing, but this is not a production signing setup. Before distributing
an official release or publishing to Google Play, configure a private release
keystore and signing configuration. Keep the keystore and its passwords
private, and back them up securely; future updates to an installed app must be
signed with the same key. Google Play submissions generally use an Android App
Bundle (`.aab`) rather than these split APKs.

### Publish APKs on GitHub Releases

The following steps publish APKs for testing. Do not use the current
debug-signed APKs as an official production release; set up release signing
first.

1. Build the APKs using the command above and confirm the files are present in
   `build/app/outputs/flutter-apk/`.
2. Sign in to GitHub with an account that has permission to publish releases
   for this repository, then open the
   [QuizWiz Releases page](https://github.com/ZanJhat/QuizWiz/releases).
3. Select **Draft a new release** (or **Create a new release**).
4. Create or select a tag matching the app version in `pubspec.yaml` (for
   example, `v2.2.0` for version `2.2.0+5`) and enter a release title.
5. Under **Attach binaries by dropping them here or selecting them**, select
   the three `*-release.apk` files from
   `build/app/outputs/flutter-apk/`. Do not attach the `.sha1` files or APKs
   from an old project folder.
6. Review the release title, tag, and attached APK names, then select **Publish
   release**. After publishing, users can download the APKs from the release's
   **Assets** section as described above.

## Run the app and enable AI card generation

To run the app on a connected device or emulator after setting up the
requirements:

```bash
flutter run
```

To enable AI card generation, open **Settings → Gemini AI**, enter your API
key (and model, if needed), then save. Do not commit or share your API key.
The app stores this configuration outside the application bundle.

## Built with

- Flutter and Dart
- `flutter_bloc` for state management
- Isar for local data
- Gemini API for AI-assisted card generation

## Attribution and license

The original project is available at
[Dev-Salem/quizwiz](https://github.com/Dev-Salem/quizwiz) and is licensed under
the MIT License. This fork retains the original [LICENSE](LICENSE), including
the original copyright notice. The modifications in this repository were made
by ZanJhat; the original copyright remains with its respective holder.

This is an independent fork. Please refer to the original repository for the
upstream project's history and to this repository for changes made in this
version.
