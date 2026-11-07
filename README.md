# Subsonica

# Features

- Subsonic player tested with Navidrome. Android is the working client. The same app is prepared for iPhone.
- Several saved connection profiles. The app opens the last one that connected. Token authentication. The password stays in secure storage.
- Library tabs for albums, tracks, artists, genres, playlists, and favorites, plus search.
- Background playback, a mini player, and a now playing screen.
- Play queue. Play replaces the queue. Add to play queue appends.
- Shuffle, and loop off, loop the album or playlist, or loop the current track.
- Playback speed from 0.5× to 2.0×, with presets 0.7, 0.85, 1, 1.25, and 1.5. The speed stays until it is changed.
- Favorite a track or an album.
- Create, rename, and delete playlists, and add tracks to a list you own. Smart and auto-imported lists stay read-only.
- Download tracks and albums onto the phone and play them without the server. Offline mode is a Settings switch. A finished download is used instead of streaming.
- Scrobble on play and again later in the track. Offline scrobbles are sent once the server is reachable.
- Lyrics from the now playing screen. Synced lines follow playback and a tap seeks. Plain lyrics stay as static text. Lyrics for a downloaded track are kept on the phone.
- English and Italian. Settings → Language defaults to Automatic, which follows the phone language.

# Build

The app has been tested only on Android so far. The iPhone project is in this same folder, but the steps below are the ones used on Android.

1. Install Flutter from [flutter.dev](https://docs.flutter.dev/get-started/install). Install Android Studio as well, so the Android SDK is on the machine. Open a terminal and run `flutter doctor`. Fix anything it reports for Android before continuing.

2. On the phone, turn on Developer options and USB debugging, then plug the phone into the computer. Accept the prompt that asks to allow USB debugging. Run `flutter devices` and check that the phone appears in the list.

3. Open a terminal in this project folder and run:

```
flutter pub get
flutter run
```

`flutter run` builds a debug copy and installs it on the connected phone. The first build can take a few minutes. Later runs are faster. Leave that terminal open while you try the app. Press `q` there when you want to stop.

To build an install file instead of launching the app:

```
flutter build apk --debug
```

The file is `build/app/outputs/flutter-apk/app-debug.apk`. Copy it to the phone and open it, or, with the phone connected, install it with:

```
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

On Windows, if the terminal says `adb` is not recognized, use `%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe`.

# Translations

English is the template in `lib/l10n/app_en.arb`. Italian is `lib/l10n/app_it.arb`. Settings → Language lists Automatic, then English and Italiano. Automatic follows the phone language and is the default.

To add a language:

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<code>.arb` and set `@@locale` to the language code, for example `fr`. Translate every message. Keep the keys, the `{placeholders}`, and the `@` metadata. `trackCount` and `albumCount` are plurals; use the categories that language needs (`one`, `few`, `many`, `other`). New app strings go in `app_en.arb` first, then into each translation.

2. From the repo root, run `flutter gen-l10n`. That rewrites `lib/l10n/app_localizations.dart` and adds `app_localizations_<code>.dart`, including `supportedLocales`. Leave the generated files unedited.

3. Accept the code as a saved choice. Add it in all three switches:
   - `knownLocale` and `localeFor` in `lib/state/locale_controller.dart`
   - `loadLocale` in `lib/services/settings_store.dart`

   A code missing from those switches is stored and then read back as Automatic.

4. Add the dropdown row in `lib/screens/settings_screen.dart`, after Automatic, English, and Italiano. Write the language's own name as a literal, such as `Français`.

5. Add the code to `CFBundleLocalizations` in `ios/Runner/Info.plist`, next to `en` and `it`. That lets an iPhone set to the new language use it when Settings is Automatic.

6. Update the Library UI bullet in `AGENTS.md` so it names the new language beside English and Italiano.

Service and player errors stay English in Dart. `localizeMessage` in `lib/l10n/context_l10n.dart` translates them when they are shown. A new user-facing error needs an ARB key and a case in that map. The thrown string stays English.

Then run `flutter analyze lib test`. On a device, open Settings and confirm the new name appears after Automatic, English, and Italiano. Select it and check a few screens, including a count such as "1 track" and "2 tracks". Set the dropdown back to Automatic and confirm it follows the phone language again.
