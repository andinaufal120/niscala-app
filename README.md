# niscala

Niscala ("Kelola Kost Tanpa Ribet") is an Android app that helps boarding-house (kos) owners and managers handle properties, rooms, tenants, rent payments and maintenance complaints.

This repository holds the Flutter app. It renders what the API returns; the backend, which owns the business rules and the API contract, lives in [niscala-api](https://github.com/andinaufal120/niscala-api).

## Requirements

- Flutter (stable channel), Dart SDK ^3.13
- An Android device or emulator

## Development

```sh
flutter pub get    # install dependencies
flutter analyze    # static analysis
flutter test       # run tests
dart format .      # format
flutter run        # run on a connected device or emulator
```

To regenerate the launcher icon after changing the images in `assets/icon/`, run `dart run flutter_launcher_icons`.

## Running against a local API

Clone [niscala-api](https://github.com/andinaufal120/niscala-api), start it (see its README), then point the app at it. On an Android emulator the host machine is `10.0.2.2`:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Release builds must use an HTTPS URL.

### Local configuration

Per-developer settings live in a `.env` file that is not committed. Copy `.env.example` to `.env`, fill it in and pass it to Flutter:

```sh
cp .env.example .env
flutter run --dart-define-from-file=.env
```

| Key | Meaning |
|---|---|
| `API_BASE_URL` | Base URL of the API. Defaults to `http://10.0.2.2:8000`. |
| `GOOGLE_SERVER_CLIENT_ID` | OAuth **Web** client ID used to get Google ID tokens. Without it the Google buttons say that Google sign-in is not available yet. |

The Web client ID is not a secret (it ends up in the APK), but it differs per environment. To make Google sign-in work:

1. In Google Cloud, create an OAuth client of type *Android* for `com.andinaufal.niscala` with the SHA-1 of your debug or release key, and an OAuth client of type *Web*.
2. Put the Web client ID in `.env` as `GOOGLE_SERVER_CLIENT_ID`.
3. Add the same Web client ID to `GOOGLE_CLIENT_IDS` in the niscala-api environment, so the API accepts tokens issued for it.

## Release build

Release builds are signed with an upload key that stays on your machine.

1. Create the upload keystore once, outside the repository, and back it up together with its passwords:

   ```sh
   keytool -genkey -v -keystore ~/niscala-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties` (ignored by git):

   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/home/you/niscala-upload.jks
   ```

3. Put the production `API_BASE_URL` (HTTPS) and `GOOGLE_SERVER_CLIENT_ID` in `.env.production`, then build the bundle Play expects:

   ```sh
   flutter build appbundle --release --dart-define-from-file=.env.production
   ```

   The output is `build/app/outputs/bundle/release/app-release.aab`. Without `android/key.properties` the build falls back to the debug key and prints a warning; Play rejects such a bundle.

4. Raise the build number (`+N`) in `pubspec.yaml` before every upload.

With Play App Signing, Google re-signs the app with its own key. For Google sign-in to work on Play builds, add the *App signing key certificate* SHA-1 (Play Console, *Test and release*, *App integrity*) to the Android OAuth client for `com.andinaufal.niscala`. Keep the upload key's SHA-1 there too for release builds installed directly.

## Docs

- `docs/SPEC.md`: what the app has to do
- `docs/ACCESSIBILITY.md`: accessibility rules and how they are tested
- `CLAUDE.md`: conventions for coding agents (and a good summary for people)
- `REVIEW.md`: what code review checks

## License

[MIT](LICENSE)
