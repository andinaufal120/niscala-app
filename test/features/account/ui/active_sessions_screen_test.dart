import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/account/ui/active_sessions_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'account_ui_helpers.dart';

const _roles = [UserRole.owner, UserRole.manager, UserRole.tenant];

const _announced = 'Perangkat dikeluarkan.';
const _emptyMessage = 'Tidak ada perangkat lain yang masuk ke akun ini.';
const _bulkLabel = 'Keluarkan semua perangkat lain';
const _notFoundMessage = 'Perangkat ini sudah keluar atau tidak ditemukan.';
const _isCurrentMessage =
    'Perangkat yang sedang dipakai keluar lewat tombol Keluar.';

/// The current device, Pixel 8, and two others: Galaxy A54 last active
/// 25 Okt 2026 and Redmi Note 12 last active 18 Okt 2026.
List<Session> _devices() => [
  makeSession(
    id: 'current',
    deviceName: 'Pixel 8',
    platform: 'Android',
    loginMethod: LoginMethod.google,
    lastActiveAt: DateTime.utc(2026, 10, 27, 12),
    isCurrent: true,
  ),
  makeSession(
    id: 's2',
    deviceName: 'Galaxy A54',
    platform: 'Android',
    loginMethod: LoginMethod.password,
    lastActiveAt: DateTime.utc(2026, 10, 25, 12),
  ),
  makeSession(
    id: 's3',
    deviceName: 'Redmi Note 12',
    platform: 'iOS',
    loginMethod: LoginMethod.google,
    lastActiveAt: DateTime.utc(2026, 10, 18, 12),
  ),
];

FakeAccountRepository _repo({List<Session>? devices}) =>
    FakeAccountRepository(devices: devices ?? _devices());

/// One other device besides the current one.
FakeAccountRepository _oneOther() => _repo(devices: _devices().sublist(0, 2));

/// Only the current device.
FakeAccountRepository _noOthers() => _repo(devices: _devices().sublist(0, 1));

Future<void> _open(
  WidgetTester tester,
  FakeAccountRepository repo, {
  UserRole role = UserRole.owner,
  bool settle = true,
  bool largeText = false,
}) => pumpAccountApp(
  tester,
  repo,
  role: role,
  path: sessionsPath(role),
  settle: settle,
  largeText: largeText,
);

/// The calls of the repository that belong to the devices screen: the account
/// behind it may load its profile too.
List<String> _calls(FakeAccountRepository repo) =>
    repo.calls.where((c) => c != 'me').toList();

/// The Keluarkan buttons of the other devices, in list order.
Finder _endButtons() => find.text('Keluarkan');

Finder _bulkButton() => find.text(_bulkLabel);

Finder _dialog() => find.byType(AlertDialog);

Finder _dialogTitle(String title) =>
    find.descendant(of: _dialog(), matching: find.text(title));

Finder _inDialog(Finder matching) =>
    find.descendant(of: _dialog(), matching: matching);

Finder _snackBar() => find.byType(SnackBar);

/// The line of a device that shows its platform and login method.
Finder _line(String text) => find.textContaining(text);

/// The text that says when a device was last active, with [date] in it.
Finder _lastActive(String date) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? '').contains('Terakhir aktif') &&
      (widget.data ?? '').contains(date),
  description: 'last active text with $date',
);

/// The announcement that a bulk end succeeded: some text that says devices
/// were signed out, other than the retention note.
Finder _bulkAnnouncement() => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? '').contains('dikeluarkan') &&
      !(widget.data ?? '').contains('90 hari'),
  description: 'the announcement of ended devices',
);

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

void _expectHeader(WidgetTester tester, String text) {
  expect(find.text(text), findsOneWidget);
  final handle = tester.ensureSemantics();
  try {
    expect(tester.getSemantics(find.text(text)), isSemantics(isHeader: true));
  } finally {
    handle.dispose();
  }
}

void _expectBulkAnnounced(WidgetTester tester) {
  expect(_bulkAnnouncement(), findsOneWidget);
  final handle = tester.ensureSemantics();
  try {
    expect(
      tester.getSemantics(_bulkAnnouncement()),
      isSemantics(isLiveRegion: true),
    );
  } finally {
    handle.dispose();
  }
}

/// Taps the Keluarkan button of the other device at [index].
Future<void> _tapEnd(WidgetTester tester, int index) async {
  await tester.tap(_endButtons().at(index));
  await tester.pumpAndSettle();
}

/// Presses the confirm button of the open dialog.
Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(_inDialog(find.byType(FilledButton)));
  await tester.pumpAndSettle();
}

Future<void> _cancel(WidgetTester tester) async {
  await tester.tap(_inDialog(find.text('Batal')));
  await tester.pumpAndSettle();
}

/// Ends the other device at [index] and confirms.
Future<void> _endAndConfirm(WidgetTester tester, int index) async {
  await _tapEnd(tester, index);
  await _confirm(tester);
}

Future<void> _endAllAndConfirm(WidgetTester tester) async {
  await tester.tap(_bulkButton());
  await tester.pumpAndSettle();
  await _confirm(tester);
}

void main() {
  group('the page', () {
    for (final role in _roles) {
      testWidgets('is titled Perangkat aktif for a $role', (tester) async {
        final repo = _repo();
        await _open(tester, repo, role: role);

        expect(find.byType(ActiveSessionsScreen), findsOneWidget);
        expect(appBarTitle('Perangkat aktif'), findsOneWidget);
        expect(currentPath(tester), sessionsPath(role));
      });
    }

    testWidgets('uses the white detail app bar with a back button', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.byType(DetailAppBar), findsOneWidget);
      expectDetailAppBar(tester);
      expect(backButton(), findsOneWidget);
    });

    testWidgets('announces the title as a header', (tester) async {
      await _open(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(appBarTitle('Perangkat aktif')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('loads the sessions once', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      expect(_calls(repo), ['sessions']);
    });

    testWidgets('explains when sessions end by themselves', (tester) async {
      await _open(tester, _repo());

      expect(find.textContaining('90 hari'), findsOneWidget);
      expect(find.textContaining('1 tahun'), findsOneWidget);
    });

    testWidgets('shows the note when there are no other devices', (
      tester,
    ) async {
      await _open(tester, _noOthers());

      expect(find.textContaining('90 hari'), findsOneWidget);
      expect(find.textContaining('1 tahun'), findsOneWidget);
    });

    testWidgets('Kembali returns to the account tab', (tester) async {
      await _open(tester, _repo());

      await pressBack(tester);

      expect(currentPath(tester), accountPath(UserRole.owner));
    });

    testWidgets('never prints null or an English term', (tester) async {
      await _open(tester, _repo());

      expect(find.textContaining('null'), findsNothing);
      for (final english in ['Session', 'Device', 'Current', 'Active']) {
        expect(find.textContaining(english), findsNothing);
      }
    });
  });

  group('the current device', () {
    testWidgets('is announced as a header over its section', (tester) async {
      await _open(tester, _repo());

      _expectHeader(tester, 'Perangkat ini');
    });

    testWidgets('shows its name, platform and login method', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Pixel 8'), findsOneWidget);
      expect(_line('Android · masuk dengan Google'), findsOneWidget);
    });

    testWidgets('shows the text badge Aktif sekarang', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Aktif sekarang'), findsOneWidget);
    });

    testWidgets('shows the badge on the current device only', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Aktif sekarang'), findsOneWidget);
      expect(
        (tester.getTopLeft(find.text('Aktif sekarang')).dy -
                tester.getTopLeft(find.text('Pixel 8')).dy)
            .abs(),
        lessThan(
          tester.getTopLeft(find.text('Galaxy A54')).dy -
              tester.getTopLeft(find.text('Pixel 8')).dy,
        ),
      );
    });

    testWidgets('has no end button', (tester) async {
      await _open(tester, _noOthers());

      expect(_endButtons(), findsNothing);
      expect(_bulkButton(), findsNothing);
    });

    testWidgets('has no end button among the other devices', (tester) async {
      await _open(tester, _repo());

      expect(_endButtons(), findsNWidgets(2));
    });

    testWidgets('sits in its own section above the other devices', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(
        _top(tester, find.text('Perangkat ini')),
        lessThan(_top(tester, find.text('Pixel 8'))),
      );
      expect(
        _top(tester, find.text('Pixel 8')),
        lessThan(_top(tester, find.text('Perangkat lain · 2'))),
      );
      expect(
        _top(tester, find.text('Perangkat lain · 2')),
        lessThan(_top(tester, find.text('Galaxy A54'))),
      );
    });

    testWidgets('stays in its section when the API lists it last', (
      tester,
    ) async {
      final devices = _devices();
      await _open(tester, _repo(devices: [devices[1], devices[2], devices[0]]));

      expect(
        _top(tester, find.text('Pixel 8')),
        lessThan(_top(tester, find.text('Galaxy A54'))),
      );
      expect(_endButtons(), findsNWidgets(2));
    });

    testWidgets('shows a password login as kata sandi', (tester) async {
      final devices = [
        makeSession(
          id: 'current',
          deviceName: 'Pixel 8',
          loginMethod: LoginMethod.password,
          isCurrent: true,
        ),
      ];
      await _open(tester, _repo(devices: devices));

      expect(_line('Android · masuk dengan kata sandi'), findsOneWidget);
    });
  });

  group('the other devices', () {
    testWidgets('are counted in a header over their section', (tester) async {
      await _open(tester, _repo());

      _expectHeader(tester, 'Perangkat lain · 2');
    });

    testWidgets('update the count with the number of devices', (tester) async {
      await _open(tester, _oneOther());

      _expectHeader(tester, 'Perangkat lain · 1');
    });

    testWidgets('show the name of each device', (tester) async {
      await _open(tester, _repo());

      expect(find.text('Galaxy A54'), findsOneWidget);
      expect(find.text('Redmi Note 12'), findsOneWidget);
    });

    testWidgets('show the platform and login method of each device', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(_line('Android · masuk dengan kata sandi'), findsOneWidget);
      expect(_line('iOS · masuk dengan Google'), findsOneWidget);
    });

    testWidgets('show when each device was last active', (tester) async {
      await _open(tester, _repo());

      expect(_lastActive('25 Okt 2026'), findsOneWidget);
      expect(_lastActive('18 Okt 2026'), findsOneWidget);
    });

    testWidgets('show the last active date of the right device', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(
        _top(tester, _lastActive('25 Okt 2026')),
        lessThan(_top(tester, find.text('Redmi Note 12'))),
      );
      expect(
        _top(tester, _lastActive('18 Okt 2026')),
        greaterThan(_top(tester, find.text('Redmi Note 12'))),
      );
    });

    testWidgets('keep the order of the API, most recent first', (tester) async {
      await _open(tester, _repo());

      expect(
        _top(tester, find.text('Galaxy A54')),
        lessThan(_top(tester, find.text('Redmi Note 12'))),
      );
    });

    testWidgets('are not sorted again by the app', (tester) async {
      final devices = _devices();
      await _open(tester, _repo(devices: [devices[0], devices[2], devices[1]]));

      expect(
        _top(tester, find.text('Redmi Note 12')),
        lessThan(_top(tester, find.text('Galaxy A54'))),
      );
    });

    testWidgets('each have a Keluarkan button beside their own row', (
      tester,
    ) async {
      await _open(tester, _repo());

      final galaxy = _top(tester, find.text('Galaxy A54'));
      final redmi = _top(tester, find.text('Redmi Note 12'));
      final first = tester.getCenter(_endButtons().at(0)).dy;
      final second = tester.getCenter(_endButtons().at(1)).dy;
      expect(first, greaterThan(galaxy));
      expect(first, lessThan(redmi));
      expect(second, greaterThan(redmi));
    });

    testWidgets('give each Keluarkan button a label that names its device', (
      tester,
    ) async {
      await _open(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        final labels = [
          for (var i = 0; i < 2; i++)
            tester.getSemantics(_endButtons().at(i)).label,
        ];
        expect(labels[0], startsWith('Keluarkan'));
        expect(labels[0], contains('Galaxy A54'));
        expect(labels[0], isNot(contains('Redmi Note 12')));
        expect(labels[1], startsWith('Keluarkan'));
        expect(labels[1], contains('Redmi Note 12'));
        expect(labels[1], isNot(contains('Galaxy A54')));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('make each Keluarkan button at least 48 dp square', (
      tester,
    ) async {
      await _open(tester, _repo());

      final handle = tester.ensureSemantics();
      try {
        for (var i = 0; i < 2; i++) {
          final rect = tester.getSemantics(_endButtons().at(i)).rect;
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.width, greaterThanOrEqualTo(48));
        }
      } finally {
        handle.dispose();
      }
    });
  });

  group('the bulk button', () {
    testWidgets('shows with two other devices', (tester) async {
      await _open(tester, _repo());

      expect(_bulkButton(), findsOneWidget);
    });

    testWidgets('shows with more than two other devices', (tester) async {
      final devices = [
        ..._devices(),
        makeSession(id: 's4', deviceName: 'Oppo A78'),
      ];
      await _open(tester, _repo(devices: devices));

      expect(_bulkButton(), findsOneWidget);
      expect(_endButtons(), findsNWidgets(3));
    });

    testWidgets('is hidden with one other device', (tester) async {
      await _open(tester, _oneOther());

      expect(_bulkButton(), findsNothing);
      expect(_endButtons(), findsOneWidget);
      expect(find.text('Galaxy A54'), findsOneWidget);
    });

    testWidgets('is hidden with no other device', (tester) async {
      await _open(tester, _noOthers());

      expect(_bulkButton(), findsNothing);
    });

    testWidgets('is at least 48 dp square', (tester) async {
      await _open(tester, _repo());

      expectTargetSize(tester, _bulkLabel);
    });
  });

  group('without other devices', () {
    testWidgets('shows the empty state', (tester) async {
      await _open(tester, _noOthers());

      expect(find.text(_emptyMessage), findsOneWidget);
    });

    testWidgets('still shows the current device', (tester) async {
      await _open(tester, _noOthers());

      _expectHeader(tester, 'Perangkat ini');
      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.text('Aktif sekarang'), findsOneWidget);
    });

    testWidgets('shows no end button and no bulk button', (tester) async {
      await _open(tester, _noOthers());

      expect(_endButtons(), findsNothing);
      expect(_bulkButton(), findsNothing);
    });

    testWidgets('shows no empty state when there are other devices', (
      tester,
    ) async {
      await _open(tester, _repo());

      expect(find.text(_emptyMessage), findsNothing);
    });
  });

  group('while loading', () {
    testWidgets('shows a progress indicator labelled Memuat', (tester) async {
      final repo = _repo()..sessionsScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Pixel 8'), findsNothing);
      expect(find.text(_emptyMessage), findsNothing);
      expect(_endButtons(), findsNothing);
    });

    testWidgets('keeps the title and the back button', (tester) async {
      final repo = _repo()..sessionsScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expect(appBarTitle('Perangkat aktif'), findsOneWidget);
      expect(backButton(), findsOneWidget);
    });

    testWidgets('shows the devices once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _repo()..sessionsScript.gate = gate;
      await _open(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.text('Galaxy A54'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('when loading fails', () {
    for (final code in ['NETWORK_ERROR', 'FORBIDDEN', 'INTERNAL_ERROR']) {
      testWidgets('shows the Indonesian message of $code with Coba lagi', (
        tester,
      ) async {
        final repo = _repo()..sessionsScript.always = ApiFailure(code: code);
        await _open(tester, repo);

        expect(find.byType(ErrorView), findsOneWidget);
        expect(find.text(messageOfCode(code)), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);
        expect(find.text('Pixel 8'), findsNothing);
        expect(_endButtons(), findsNothing);
        expect(_bulkButton(), findsNothing);
      });
    }

    testWidgets('keeps the title and the back button', (tester) async {
      final repo = _repo()..sessionsScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(appBarTitle('Perangkat aktif'), findsOneWidget);
      expect(backButton(), findsOneWidget);
    });

    testWidgets('Coba lagi loads the sessions again and shows them', (
      tester,
    ) async {
      final repo = _repo()
        ..sessionsScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      expect(repo.sessionsCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.sessionsCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Pixel 8'), findsOneWidget);
      expect(find.text('Galaxy A54'), findsOneWidget);
    });

    testWidgets('Coba lagi that fails again keeps the error', (tester) async {
      final repo = _repo()..sessionsScript.always = const ApiFailure.network();
      await _open(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.sessionsCalls, 2);
      expect(find.byType(ErrorView), findsOneWidget);
    });

    testWidgets('does not retry in the background', (tester) async {
      final repo = _repo()..sessionsScript.always = const ApiFailure.network();
      await _open(tester, repo);
      await tester.pump(const Duration(seconds: 10));

      expect(repo.sessionsCalls, 1);
    });
  });

  group('ending one device', () {
    testWidgets('asks for confirmation first, naming the device', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);

      await _tapEnd(tester, 0);

      expect(_dialog(), findsOneWidget);
      expect(_dialogTitle('Keluarkan Galaxy A54?'), findsOneWidget);
      expect(_inDialog(find.text('Batal')), findsOneWidget);
      expect(repo.endCalls, 0);
      expect(_calls(repo), ['sessions']);
    });

    testWidgets('names the device of the second row in its dialog', (
      tester,
    ) async {
      await _open(tester, _repo());

      await _tapEnd(tester, 1);

      expect(_dialogTitle('Keluarkan Redmi Note 12?'), findsOneWidget);
    });

    testWidgets('Batal closes the dialog and makes no call', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _tapEnd(tester, 0);

      await _cancel(tester);

      expect(_dialog(), findsNothing);
      expect(_calls(repo), ['sessions']);
      expect(find.text('Galaxy A54'), findsOneWidget);
      expect(find.text('Redmi Note 12'), findsOneWidget);
      expect(find.text(_announced), findsNothing);
    });

    testWidgets('dismissing the dialog makes no call either', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await _tapEnd(tester, 0);

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(_dialog(), findsNothing);
      expect(_calls(repo), ['sessions']);
      expect(find.text('Galaxy A54'), findsOneWidget);
    });

    testWidgets('confirming ends that session, then reloads the list', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);

      await _endAndConfirm(tester, 0);

      expect(_calls(repo), ['sessions', 'end:s2', 'sessions']);
      expect(_dialog(), findsNothing);
      expect(find.text('Galaxy A54'), findsNothing);
      expect(find.text('Redmi Note 12'), findsOneWidget);
      expect(find.text('Pixel 8'), findsOneWidget);
      _expectHeader(tester, 'Perangkat lain · 1');
    });

    testWidgets('confirming on the second row ends the second session', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);

      await _endAndConfirm(tester, 1);

      expect(_calls(repo), ['sessions', 'end:s3', 'sessions']);
      expect(find.text('Redmi Note 12'), findsNothing);
      expect(find.text('Galaxy A54'), findsOneWidget);
    });

    testWidgets('shows the reloaded list, not a stale copy', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      repo.devices.add(makeSession(id: 's4', deviceName: 'Oppo A78'));

      await _endAndConfirm(tester, 0);

      expect(find.text('Oppo A78'), findsOneWidget);
    });

    testWidgets('announces Perangkat dikeluarkan. as a live region', (
      tester,
    ) async {
      await _open(tester, _repo());

      await _endAndConfirm(tester, 0);

      expect(find.text(_announced), findsOneWidget);
      expectLiveRegion(tester, _announced);
    });

    testWidgets('announces inline, not in a snack bar', (tester) async {
      await _open(tester, _repo());

      await _endAndConfirm(tester, 0);

      expect(_snackBar(), findsNothing);
      expect(find.text(_announced), findsOneWidget);
    });

    testWidgets('keeps the announcement on screen', (tester) async {
      await _open(tester, _repo());
      await _endAndConfirm(tester, 0);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(_announced), findsOneWidget);
    });

    testWidgets('does not announce before the session is ended', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _repo()..endScript.gate = gate;
      await _open(tester, repo);

      await _tapEnd(tester, 0);
      await tester.tap(_inDialog(find.byType(FilledButton)));
      await tester.pump();
      await tester.pump();

      expect(repo.endCalls, 1);
      expect(find.text(_announced), findsNothing);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text(_announced), findsOneWidget);
    });

    testWidgets('ending the last other device shows the empty state', (
      tester,
    ) async {
      final repo = _oneOther();
      await _open(tester, repo);

      await _endAndConfirm(tester, 0);

      expect(find.text(_emptyMessage), findsOneWidget);
      expect(_endButtons(), findsNothing);
      expect(_bulkButton(), findsNothing);
      expect(find.text(_announced), findsOneWidget);
      expect(find.text('Pixel 8'), findsOneWidget);
    });

    testWidgets('ending one of two leaves no bulk button', (tester) async {
      await _open(tester, _repo());

      await _endAndConfirm(tester, 0);

      expect(_bulkButton(), findsNothing);
      expect(_endButtons(), findsOneWidget);
    });

    testWidgets('ends one device after another', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      await _endAndConfirm(tester, 0);
      await _endAndConfirm(tester, 0);

      expect(_calls(repo), [
        'sessions',
        'end:s2',
        'sessions',
        'end:s3',
        'sessions',
      ]);
      expect(find.text(_emptyMessage), findsOneWidget);
    });
  });

  group('when ending one device fails', () {
    testWidgets('a vanished session shows its message and reloads', (
      tester,
    ) async {
      final repo = _repo();
      repo.endScript.queue.add(
        const ApiFailure(code: 'SESSION_NOT_FOUND', statusCode: 404),
      );
      await _open(tester, repo);
      repo.devices.removeWhere((s) => s.id == 's2');

      await _endAndConfirm(tester, 0);

      expect(find.text(_notFoundMessage), findsOneWidget);
      expect(repo.sessionsCalls, 2);
      expect(find.text('Galaxy A54'), findsNothing);
      expect(find.text('Redmi Note 12'), findsOneWidget);
      expect(find.text(_announced), findsNothing);
      expect(_snackBar(), findsNothing);
    });

    testWidgets('a vanished session takes its text from the error code', (
      tester,
    ) async {
      final repo = _repo();
      repo.endScript.queue.add(const ApiFailure(code: 'SESSION_NOT_FOUND'));
      await _open(tester, repo);

      await _endAndConfirm(tester, 0);

      expect(find.text(messageOfCode('SESSION_NOT_FOUND')), findsOneWidget);
    });

    testWidgets('ending the current session shows its message', (tester) async {
      final repo = _repo();
      repo.endScript.queue.add(
        const ApiFailure(code: 'SESSION_IS_CURRENT', statusCode: 409),
      );
      await _open(tester, repo);

      await _endAndConfirm(tester, 0);

      expect(find.text(_isCurrentMessage), findsOneWidget);
      expect(find.text('Galaxy A54'), findsOneWidget);
      expect(find.text(_announced), findsNothing);
    });

    for (final code in ['NETWORK_ERROR', 'FORBIDDEN', 'INTERNAL_ERROR']) {
      testWidgets('$code shows its message and changes nothing', (
        tester,
      ) async {
        final repo = _repo();
        repo.endScript.queue.add(ApiFailure(code: code));
        await _open(tester, repo);

        await _endAndConfirm(tester, 0);

        expect(find.text(messageOfCode(code)), findsOneWidget);
        expect(find.text('Galaxy A54'), findsOneWidget);
        expect(find.text('Redmi Note 12'), findsOneWidget);
        expect(find.text('Pixel 8'), findsOneWidget);
        expect(find.text(_announced), findsNothing);
        expect(find.byType(ErrorView), findsNothing);
        expect(_snackBar(), findsNothing);
        expect(_dialog(), findsNothing);
      });
    }

    testWidgets('an unknown code shows the generic message', (tester) async {
      final repo = _repo();
      repo.endScript.queue.add(const ApiFailure(code: 'SOMETHING_NEW'));
      await _open(tester, repo);

      await _endAndConfirm(tester, 0);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
      expect(find.text('Galaxy A54'), findsOneWidget);
    });

    testWidgets('the message stays on screen', (tester) async {
      final repo = _repo();
      repo.endScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _endAndConfirm(tester, 0);

      await tester.pump(const Duration(seconds: 30));

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
    });

    testWidgets('trying again calls the API again and can succeed', (
      tester,
    ) async {
      final repo = _repo();
      repo.endScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _endAndConfirm(tester, 0);
      expect(repo.endCalls, 1);

      await _endAndConfirm(tester, 0);

      expect(repo.endCalls, 2);
      expect(_calls(repo).where((c) => c == 'end:s2'), hasLength(2));
      expect(find.text('Galaxy A54'), findsNothing);
      expect(find.text(_announced), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('the Keluarkan buttons stay available after a failure', (
      tester,
    ) async {
      final repo = _repo();
      repo.endScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await _endAndConfirm(tester, 0);

      expect(_endButtons(), findsNWidgets(2));
      expect(_bulkButton(), findsOneWidget);
    });
  });

  group('ending all other devices', () {
    testWidgets('asks for confirmation first', (tester) async {
      final repo = _repo();
      await _open(tester, repo);

      await tester.tap(_bulkButton());
      await tester.pumpAndSettle();

      expect(_dialog(), findsOneWidget);
      expect(_dialogTitle('Keluarkan semua perangkat lain?'), findsOneWidget);
      expect(_inDialog(find.text('Batal')), findsOneWidget);
      expect(repo.endOthersCalls, 0);
      expect(_calls(repo), ['sessions']);
    });

    testWidgets('Batal closes the dialog and makes no call', (tester) async {
      final repo = _repo();
      await _open(tester, repo);
      await tester.tap(_bulkButton());
      await tester.pumpAndSettle();

      await _cancel(tester);

      expect(_dialog(), findsNothing);
      expect(_calls(repo), ['sessions']);
      expect(find.text('Galaxy A54'), findsOneWidget);
      expect(find.text('Redmi Note 12'), findsOneWidget);
      expect(_bulkButton(), findsOneWidget);
    });

    testWidgets('confirming ends the others, then reloads the list', (
      tester,
    ) async {
      final repo = _repo();
      await _open(tester, repo);

      await _endAllAndConfirm(tester);

      expect(_calls(repo), ['sessions', 'endOthers', 'sessions']);
      expect(repo.endCalls, 0);
      expect(_dialog(), findsNothing);
      expect(find.text('Galaxy A54'), findsNothing);
      expect(find.text('Redmi Note 12'), findsNothing);
      expect(find.text('Pixel 8'), findsOneWidget);
    });

    testWidgets('leaves the empty state and no bulk button', (tester) async {
      await _open(tester, _repo());

      await _endAllAndConfirm(tester);

      expect(find.text(_emptyMessage), findsOneWidget);
      expect(_bulkButton(), findsNothing);
      expect(_endButtons(), findsNothing);
    });

    testWidgets('announces the result inline as a live region', (tester) async {
      await _open(tester, _repo());

      await _endAllAndConfirm(tester);

      _expectBulkAnnounced(tester);
      expect(_snackBar(), findsNothing);
    });

    testWidgets('keeps the announcement on screen', (tester) async {
      await _open(tester, _repo());
      await _endAllAndConfirm(tester);

      await tester.pump(const Duration(seconds: 30));

      expect(_bulkAnnouncement(), findsOneWidget);
    });

    for (final code in ['NETWORK_ERROR', 'FORBIDDEN', 'INTERNAL_ERROR']) {
      testWidgets('$code shows its message and changes nothing', (
        tester,
      ) async {
        final repo = _repo();
        repo.endOthersScript.queue.add(ApiFailure(code: code));
        await _open(tester, repo);

        await _endAllAndConfirm(tester);

        expect(find.text(messageOfCode(code)), findsOneWidget);
        expect(find.text('Galaxy A54'), findsOneWidget);
        expect(find.text('Redmi Note 12'), findsOneWidget);
        expect(_bulkButton(), findsOneWidget);
        expect(_bulkAnnouncement(), findsNothing);
        expect(find.byType(ErrorView), findsNothing);
        expect(_snackBar(), findsNothing);
      });
    }

    testWidgets('trying again after a failure can succeed', (tester) async {
      final repo = _repo();
      repo.endOthersScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _endAllAndConfirm(tester);

      await _endAllAndConfirm(tester);

      expect(repo.endOthersCalls, 2);
      expect(find.text(_emptyMessage), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });
  });

  group('accessibility', () {
    final states = <String, FakeAccountRepository Function()>{
      'with several other devices': _repo,
      'with one other device': _oneOther,
      'without other devices': _noOthers,
      'when loading fails': () =>
          _repo()..sessionsScript.always = const ApiFailure.network(),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines ${entry.key}', (tester) async {
        await _open(tester, entry.value());

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size ${entry.key}', (tester) async {
        await _open(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
      });
    }

    for (final role in _roles) {
      testWidgets('meets the guidelines for a $role', (tester) async {
        await _open(tester, _repo(), role: role);

        await expectMeetsA11yGuidelines(tester);
      });
    }

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..sessionsScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..sessionsScript.gate = Completer<void>();
      await _open(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines with the end dialog open', (
      tester,
    ) async {
      await _open(tester, _repo());
      await _tapEnd(tester, 0);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with the bulk dialog open', (
      tester,
    ) async {
      await _open(tester, _repo());
      await tester.tap(_bulkButton());
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the end dialog open', (
      tester,
    ) async {
      await _open(tester, _repo(), largeText: true);
      await tapVisible(tester, _endButtons().first);

      expect(_dialog(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size with the bulk dialog open', (
      tester,
    ) async {
      await _open(tester, _repo(), largeText: true);
      await tapVisible(tester, _bulkButton());

      expect(_dialog(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines after ending one device', (tester) async {
      await _open(tester, _repo());
      await _endAndConfirm(tester, 0);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size after ending one device', (
      tester,
    ) async {
      await _open(tester, _repo(), largeText: true);
      await tapVisible(tester, _endButtons().first);
      await _confirm(tester);

      expect(find.text(_announced), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines after ending all other devices', (
      tester,
    ) async {
      await _open(tester, _repo());
      await _endAllAndConfirm(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size after ending all other devices', (
      tester,
    ) async {
      await _open(tester, _repo(), largeText: true);
      await tapVisible(tester, _bulkButton());
      await _confirm(tester);

      expect(find.text(_emptyMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines after a vanished session', (
      tester,
    ) async {
      final repo = _repo();
      repo.endScript.queue.add(const ApiFailure(code: 'SESSION_NOT_FOUND'));
      await _open(tester, repo);
      await _endAndConfirm(tester, 0);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size after a vanished session', (
      tester,
    ) async {
      final repo = _repo();
      repo.endScript.queue.add(const ApiFailure(code: 'SESSION_NOT_FOUND'));
      await _open(tester, repo, largeText: true);
      await tapVisible(tester, _endButtons().first);
      await _confirm(tester);

      expect(find.text(_notFoundMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines after another failure', (tester) async {
      final repo = _repo();
      repo.endScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _endAndConfirm(tester, 0);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size after another failure', (
      tester,
    ) async {
      final repo = _repo();
      repo.endScript.queue.add(const ApiFailure.network());
      await _open(tester, repo, largeText: true);
      await tapVisible(tester, _endButtons().first);
      await _confirm(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines after a failure to end all', (
      tester,
    ) async {
      final repo = _repo();
      repo.endOthersScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await _endAllAndConfirm(tester);

      await expectMeetsA11yGuidelines(tester);
    });
  });
}
