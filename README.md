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

## Running against a local API

Clone [niscala-api](https://github.com/andinaufal120/niscala-api), start it (see its README), then point the app at it. On an Android emulator the host machine is `10.0.2.2`:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Release builds must use an HTTPS URL.

## Docs

- `docs/SPEC.md`: what the app has to do
- `docs/ACCESSIBILITY.md`: accessibility rules and how they are tested
- `CLAUDE.md`: conventions for coding agents (and a good summary for people)
- `REVIEW.md`: what code review checks

## License

[MIT](LICENSE)
