# ACCESSIBILITY.md — Niscala mobile app

> **Audience:** coding agents working in this repository.
> **Scope:** every screen, dialog and widget in the Flutter Android app.
> **Status:** self-contained. Apply these rules to all UI work; don't look for accessibility requirements elsewhere.

## 1. Target

- **Required:** WCAG 2.2 **Level A** (NFR-14), applied to a native app as described below.
- **Project rules:** four **Level AA** criteria on top of Level A, because users include tenants and owners with low tech literacy:
    - 1.4.3 Contrast (Minimum)
    - 1.4.4 Resize Text
    - 2.5.8 Target Size (Minimum), applied as Android's 48 × 48 dp
    - 3.3.8 Accessible Authentication (Minimum)
- Other Level AA and all AAA criteria are **not** required. Don't add work for them unless a plan says so.

Users: Indonesian speakers with TalkBack, large system font sizes, low vision, colour blindness, or limited dexterity. The UI language is Indonesian, so every spoken label is Indonesian too.

## 2. Rules

Each rule cites the WCAG success criterion (SC) it comes from. "N/A" criteria are listed in §4 so nobody re-checks them.

### 2.1 Labels and semantics

| SC                           | Rule                                                                                                                                                                                                             |
|------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1.1.1 Non-text Content       | Every meaningful icon, image and icon-only button has an Indonesian `semanticLabel` / `tooltip`. Decorative images use `excludeFromSemantics: true`.                                                             |
| 1.1.1                        | A receipt image (UC-05, UC-07) is labelled with what it is, e.g. `"Bukti transfer, Budi, <periode>"`. The period's display format follows `docs/SPEC.md` U-5.                                                     |
| 1.1.1                        | An invitation QR code (UC-18, UC-20) is never the only way to get the link: the same screen offers the link as text and as a share action.                                                                       |
| 4.1.2 Name, Role, Value      | Use standard Material widgets where possible; they expose name, role and state. A custom tappable widget is wrapped in `Semantics(button: true, label: ...)`, and toggles/checkboxes expose `checked`/`toggled`. |
| 2.5.3 Label in Name          | If a control shows visible text, its spoken label starts with that text. Don't override `"Simpan"` with an unrelated label like `"Kirim formulir"`.                                                              |
| 1.3.1 Info and Relationships | Screen and section titles use `Semantics(header: true)`. Form fields get their label through `InputDecoration.labelText`, not a separate `Text` placed above the field.                                          |
| 1.3.2 Meaningful Sequence    | Reading order matches visual order. Use `MergeSemantics` for list rows so a row reads as one item (e.g. `"Kamar 12, Terisi, Rp 800.000"`).                                                                       |

### 2.2 Colour, contrast and text size

| SC                                     | Rule                                                                                                                                                                                                         |
|----------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1.4.1 Use of Color                     | Status is never shown by colour alone. Every status badge (SPEC.md §5) shows its Indonesian text label; colour and icon only reinforce it. The same applies to the at-risk flag (UC-26) and urgency (UC-23). |
| 1.3.3 Sensory Characteristics          | Instructions never rely on colour, shape or position alone. Write `"Ketuk Simpan"`, not `"Ketuk tombol hijau"`.                                                                                              |
| 1.4.3 Contrast *(AA, project rule)*    | Text contrast is at least 4.5:1, or 3:1 for large text (18 sp, or 14 sp bold). Take colours from the theme; no hard-coded text colours.                                                                      |
| 1.4.4 Resize Text *(AA, project rule)* | Respect the system font size. Never clamp or override `TextScaler`. At 200 % text scale, nothing overflows, is clipped or is hidden. Let text wrap; avoid fixed heights on containers that hold text.        |

### 2.3 Touch and interaction

| SC                                      | Rule                                                                                                                                                                                    |
|-----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2.5.8 Target Size *(AA, project rule)*  | Every tappable target is at least 48 × 48 dp, including icon buttons, chips and list-row actions.                                                                                       |
| 2.5.1 Pointer Gestures                  | Any swipe, drag or long-press action also has a single-tap alternative, e.g. swipe-to-delete plus a `Hapus` button on the detail screen.                                                |
| 2.5.2 Pointer Cancellation              | Trigger actions on tap-up (`onTap`, `onPressed`), never on `onTapDown`.                                                                                                                 |
| 2.5.4 Motion Actuation                  | No feature is triggered by shaking or tilting the device.                                                                                                                               |
| 2.1.1 Keyboard / 2.1.2 No Keyboard Trap | Everything works with TalkBack, Switch Access or an external keyboard. Don't break focus traversal; dialogs and bottom sheets can always be closed.                                     |
| 2.4.3 Focus Order                       | Focus moves through a screen in a logical order. When a dialog closes, focus returns to the control that opened it.                                                                     |
| 2.2.1 Timing Adjustable                 | Important information is never shown only in a self-dismissing message. A `SnackBar` may confirm an action, but errors and results the user must act on stay on screen until dismissed. |
| 2.2.2 Pause, Stop, Hide                 | No auto-scrolling carousels or auto-advancing content.                                                                                                                                  |
| 2.3.1 Three Flashes                     | Nothing flashes more than three times per second.                                                                                                                                       |

### 2.4 Screens, forms and errors

| SC                              | Rule                                                                                                                                                                                                                         |
|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2.4.2 Page Titled               | Every screen has a title (usually the `AppBar` title) that names the screen, e.g. `"Tambah Penyewa"`.                                                                                                                        |
| 2.4.4 Link Purpose              | Link and button text says what it does: `"Lihat riwayat pembayaran"`, not `"Lihat"` or `"Klik di sini"`.                                                                                                                     |
| 3.1.1 Language of Page          | The app sets the Indonesian locale (`Locale('id')`) so TalkBack reads with an Indonesian voice.                                                                                                                              |
| 3.2.1 On Focus / 3.2.2 On Input | Focusing a field or changing a value never navigates, submits or opens something unexpectedly. Choosing a property or period in a filter updates the list in place. Submitting a form always needs an explicit button press. |
| 3.2.6 Consistent Help           | The in-app help entry point sits in the same place on every screen that has it.                                                                                                                                              |
| 3.3.1 Error Identification      | A validation error names the field and the cause in text, next to the field (SPEC.md §6 rule 2), and is exposed to TalkBack through the field's `errorText`.                                                                 |
| 3.3.2 Labels or Instructions    | Every input has a visible label. Required and optional fields are marked in text (`"(wajib)"` / `"(opsional)"`), not only with `*`. Formats are stated, e.g. `"Nomor telepon, contoh: 0812…"`.                               |
| 3.3.7 Redundant Entry           | Never ask the user for information they already gave in the same process. Tenant activation (FR-01) pre-fills everything management entered; the tenant only completes what is missing.                                      |

### 2.5 Authentication

Applies to sign-up, login, invitation activation and the profile menu's password screens (SPEC.md §7).

| SC                                                   | Rule                                                                                                                                                                                              |
|------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 3.3.8 Accessible Authentication *(AA, project rule)* | Logging in never depends on memorising or transcribing something. Users can always paste into email and password fields and use a password manager or autofill.                                   |
| 3.3.8                                                | Never disable paste or text selection on credential fields (`enableInteractiveSelection` stays `true`; no custom `contextMenuBuilder` that removes Paste).                                        |
| 3.3.8                                                | Wrap each credential form in an `AutofillGroup`. Email fields use `AutofillHints.email`; login password fields use `AutofillHints.password`; new-password fields use `AutofillHints.newPassword`. |
| 3.3.8                                                | Every password field has a show-password toggle (also NFR-11), and the toggle has an Indonesian label (`"Tampilkan kata sandi"` / `"Sembunyikan kata sandi"`).                                    |
| 3.3.8                                                | No puzzle-style CAPTCHA or "retype the code" check. If the backend rate-limits login, show the Indonesian message for the error code it returns; don't add a challenge in the app.                                              |
| 3.3.8                                                | Google sign-in stays available on the login and invitation-activation screens.                                                                                                                    |

## 3. Verification

Accessibility is verified with **automated widget tests only**. They are part of test-first development: write them with the screen's other widget tests.

### 3.1 What every screen test must check

For each screen, in each state it can show (**loaded**, **empty**, **error**, plus **subscription-gated** where SPEC.md §6 rule 7 applies):

| Check                                                                                                                                                                            | Covers                                            |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------|
| `meetsGuideline(labeledTapTargetGuideline)`                                                                                                                                      | 1.1.1, 4.1.2 — every tappable element has a label |
| `meetsGuideline(androidTapTargetGuideline)`                                                                                                                                      | 2.5.8 — 48 × 48 dp targets                        |
| `meetsGuideline(textContrastGuideline)`                                                                                                                                          | 1.4.3 — text contrast                             |
| Pump at text scale 2.0 on a 360 × 640 dp screen; the test fails on any overflow error                                                                                            | 1.4.4 — resize text                               |
| *Authentication screens only:* every email and password `TextField` has `enableInteractiveSelection == true` and the autofill hint from §2.5, and sits inside an `AutofillGroup` | 3.3.8 — accessible authentication                 |

### 3.2 How

Put the checks in one shared test helper so every screen runs exactly the same checks, and call it from each screen's widget tests. Sketch:

```dart
Future<void> expectMeetsA11yGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  addTearDown(handle.dispose);
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

Future<void> pumpAtLargeText(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3.0; // 360 × 640 dp
  tester.platformDispatcher.textScaleFactorTestValue = 2.0;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(screen);
  // A RenderFlex overflow is reported as an error and fails the test.
}
```

A screen is not done until these checks pass alongside `flutter analyze` and `flutter test`.

### 3.3 What tests cannot catch

These rules have no automated check. Apply them while implementing and check them when reviewing a diff:

- Labels that exist but say nothing useful (`"Tombol"`, `"Gambar"`, an English label in an Indonesian UI). — 1.1.1, 2.4.4
- Status shown by colour alone. — 1.4.1
- Reading order that differs from visual order. — 1.3.2
- Gesture-only actions without a tap alternative. — 2.5.1
- Important messages that disappear on their own. — 2.2.1
- Text over images or gradients (`textContrastGuideline` does not measure these). — 1.4.3
- Text that is clipped, cut off by `maxLines`, or ellipsized at 200 % text scale (only overflow errors fail a test). — 1.4.4
- Focus returning to the control that opened a dialog. — 2.4.3
- Operation with TalkBack, Switch Access or an external keyboard. — 2.1.1, 2.1.2
- TalkBack reading labels with an Indonesian voice. — 3.1.1

## 4. Not applicable in v1.0

| SC                            | Why                                                                             |
|-------------------------------|---------------------------------------------------------------------------------|
| 1.2.x Time-based Media        | No audio or video.                                                              |
| 1.4.2 Audio Control           | No audio.                                                                       |
| 2.1.4 Character Key Shortcuts | No single-key shortcuts.                                                        |
| 2.4.1 Bypass Blocks           | Applies to blocks repeated across web pages; not applicable to this native app. |

If a feature introduces any of these (for example a video tutorial in in-app help), the criterion applies again. Raise it in Plan mode.

## 5. Changelog

| Date       | Change                                                                                                                                                                                                        | Decided in |
|------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|
| 13-10-2026 | Initial version: Level A plus project rules for 1.4.3, 1.4.4, 2.5.8 and 3.3.8; automated verification only.                                                                                                   | NKMA-14    |
| 13-10-2026 | Google sign-in rule scoped to login and activation; §3.3 adds clipped text, focus return and assistive-tech checks; test helper disposes semantics on failure; receipt label no longer assumes a date format. | NKMA-14    |
| 15-10-2026 | 3.3.8: a rate-limit error is shown as the Indonesian message for its error code, not the API's English text.                                                                                                  | NKMA-14    |