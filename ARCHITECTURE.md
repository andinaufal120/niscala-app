# ARCHITECTURE.md — Niscala mobile app

> **Audience:** coding agents working in this repository.
> **Scope:** how the Flutter app is built, up to the API boundary. What the app has to do is in `docs/SPEC.md`; this file does not repeat it. Backend internals are not documented here.
> Update this file in the same PR as any change to the structure it describes.

## 1. Layout

```
lib/
  main.dart, app.dart        # entry point, MaterialApp.router, theme, Locale('id')
  core/
    api/                     # HTTP client, error mapping, providers for the generated client
    session/                 # tokens, secure storage, session state
    shell/                   # bottom-navigation shells and the account screen
    widgets/                 # shared widgets (status badge, empty/error states, dialogs)
    router.dart              # routes and the role-based redirect
    theme.dart               # colour and type tokens
    format.dart              # money and date display
  features/<area>/           # added per feature: data/ (repositories) and ui/ (screens)
packages/niscala_api/        # generated Dart client (never hand-edited)
api/openapi.json             # exported OpenAPI document (never hand-edited)
tool/generate_api_client.sh  # refreshes the two above from a niscala-api git ref
test/                        # mirrors lib/; shared helpers in test/helpers/
```

## 2. Stack

Riverpod 3 (no code generation) for state and dependency injection, `go_router` for navigation, `flutter_secure_storage` for tokens, `device_info_plus` for the device sent at login, `intl` with `flutter_localizations` for Indonesian formatting. Plus Jakarta Sans is bundled under `assets/fonts/`; the app fetches no fonts at run time.

## 3. The API boundary

- The generated client in `packages/niscala_api` is the only code that knows endpoint paths and wire types. Feature repositories wrap it and turn failures into `ApiFailure {code, field, statusCode}` (`core/api/api_failure_mapper.dart`). Screens never see HTTP exceptions.
- The base URL comes from `--dart-define=API_BASE_URL` (default `http://10.0.2.2:8000`, the host machine seen from an Android emulator). Debug builds may use plain HTTP; release builds are HTTPS only.
- `AuthHttpClient` adds the bearer token to every request. When the API answers `401` with `ACCESS_TOKEN_INVALID` it refreshes the token pair once (one refresh shared by concurrent requests) and retries the request once. A failed refresh ends the session.
- Error text shown to the user is Indonesian, mapped from `ApiFailure.code` in `core/api/error_messages.dart`. The API's English message is never displayed. Unknown codes and `VALIDATION_FAILED` show the generic message; a field error is shown next to its field using `ApiFailure.field`.
- The app computes no backend value (billing, occupancy, risk, gating). Where a screen needs a value the API does not provide, that is a contract gap.

## 4. Session and routing

`SessionController` holds `SessionLoading`, `SignedOut` or `SignedIn(role, emailVerified)`, persists tokens in secure storage and implements `TokenSource` for the HTTP client. `NiscalaApp` restores the stored session at start-up.

`redirectFor(state, location)` in `core/router.dart` is a pure function and the single place that decides where a session may be:

| Session                          | Goes to                                                         |
|----------------------------------|-----------------------------------------------------------------|
| loading                          | `/memuat`                                                       |
| signed out                       | `/masuk` (auth routes `/masuk`, `/daftar`, `/aktivasi` stay put) |
| signed in, email not verified    | `/verifikasi-email`                                             |
| owner or manager                 | management shell, `/beranda` and siblings                       |
| tenant                           | tenant shell, `/penyewa/beranda` and siblings                   |
| admin                            | `/admin`                                                        |

Each shell is a `StatefulShellRoute` with a bottom navigation bar (SPEC §6a). Tabs whose feature is not built yet show `PlaceholderScreen`.

## 5. UI conventions

- Colours and text styles come from `buildTheme()`; widgets do not hard-code them.
- A status is always shown with its text label; `StatusBadge(label, tone, icon)` takes the label from a data table owned by the feature (SPEC §5), so colour never carries meaning alone.
- Empty, error and confirmation states use `EmptyState`, `ErrorView` and `showConfirmDialog`.
- Money and dates go through `formatRupiah` and `formatDate`.
- Every screen is covered by the shared accessibility checks in `test/helpers/a11y.dart` (`docs/ACCESSIBILITY.md` §3).

## 6. Testing

Tests are written before the code (`CLAUDE.md`, Workflow). Widget tests override the providers that cross the boundary (`sessionStoreProvider`, `refreshTokensProvider`, `logoutProvider`, and each feature's repository provider) with fakes from `test/helpers/fakes.dart`; no test calls a real server.

## 7. Open points

Deep links for invitation and password-reset links (U-4), the minimum Android version (TBD-2) and the list of API error codes (U-9) are in `docs/SPEC.md` §10.
