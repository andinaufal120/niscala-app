import 'dart:async';

import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/notifications/ui/notification_settings_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'notification_ui_helpers.dart';

const _tenant = UserRole.tenant;
const _owner = UserRole.owner;

const _labels = {
  NotificationCategory.billing: 'Tagihan dan pengingat',
  NotificationCategory.paymentStatus: 'Status pembayaran',
  NotificationCategory.complaintProgress: 'Perkembangan keluhan',
  NotificationCategory.newComplaint: 'Keluhan baru',
  NotificationCategory.receiptUpload: 'Bukti transfer baru',
  NotificationCategory.overdueBill: 'Tagihan terlambat',
  NotificationCategory.accountActivity: 'Aktivitas akun',
};

const _saved = 'Pengaturan disimpan';

FakeNotificationRepository _tenantRepo() => FakeNotificationRepository();

FakeNotificationRepository _managementRepo() =>
    FakeNotificationRepository(settings: makeManagementNotificationSettings());

FakeNotificationRepository _allRepo() => FakeNotificationRepository(
  settings: [
    for (final category in NotificationCategory.values)
      NotificationSettingItem(
        category: category,
        pushEnabled: true,
        urgencyScope: category == NotificationCategory.newComplaint
            ? NotificationUrgencyScope.allUrgencies
            : null,
      ),
  ],
);

Future<void> _open(
  WidgetTester tester,
  FakeNotificationRepository repo, {
  UserRole role = _owner,
  bool settle = true,
  bool largeText = false,
}) => pumpNotificationApp(
  tester,
  repo,
  role: role,
  path: notificationSettingsPath(role),
  settle: settle,
  largeText: largeText,
);

Finder get _save => buttonLabelled('Simpan');

Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(_save);
  await tester.pumpAndSettle();
}

void main() {
  group('screen', () {
    testWidgets('shows the title Pengaturan Notifikasi in the app bar', (
      tester,
    ) async {
      await _open(tester, _managementRepo());

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(appBarTitle('Pengaturan Notifikasi'), findsOneWidget);
    });

    testWidgets('loads the settings once', (tester) async {
      final repo = _managementRepo();
      await _open(tester, repo);

      expect(repo.settingsCalls, 1);
    });

    testWidgets('covers the bottom navigation', (tester) async {
      await _open(tester, _managementRepo());

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Kembali returns to the list', (tester) async {
      await _open(tester, _managementRepo());

      await pressBack(tester);

      expect(currentPath(tester), notificationsPath(_owner));
      expect(appBarTitle('Notifikasi'), findsOneWidget);
    });

    testWidgets('is opened under the tenant path for a tenant', (tester) async {
      await _open(tester, _tenantRepo(), role: _tenant);

      expect(currentPath(tester), '/penyewa/akun/notifikasi/pengaturan');
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    });

    testWidgets('says the settings only control push', (tester) async {
      await _open(tester, _managementRepo());

      expect(
        find.textContaining('hanya mengatur notifikasi push'),
        findsOneWidget,
      );
      expect(find.textContaining('tetap muncul di daftar'), findsOneWidget);
    });

    testWidgets('has a Simpan button', (tester) async {
      await _open(tester, _managementRepo());

      expect(_save, findsOneWidget);
    });
  });

  group('categories', () {
    testWidgets('a tenant sees the three categories returned', (tester) async {
      await _open(tester, _tenantRepo(), role: _tenant);

      expect(find.byType(SwitchListTile), findsNWidgets(3));
      expect(switchTile('Tagihan dan pengingat'), findsOneWidget);
      expect(switchTile('Status pembayaran'), findsOneWidget);
      expect(switchTile('Perkembangan keluhan'), findsOneWidget);
      expect(switchTile('Keluhan baru'), findsNothing);
      expect(find.text('Semua urgensi'), findsNothing);
    });

    testWidgets('management sees the four categories returned', (tester) async {
      await _open(tester, _managementRepo());

      expect(find.byType(SwitchListTile), findsNWidgets(4));
      expect(switchTile('Keluhan baru'), findsOneWidget);
      expect(switchTile('Bukti transfer baru'), findsOneWidget);
      expect(switchTile('Tagihan terlambat'), findsOneWidget);
      expect(switchTile('Aktivitas akun'), findsOneWidget);
      expect(switchTile('Tagihan dan pengingat'), findsNothing);
    });

    for (final entry in _labels.entries) {
      testWidgets('labels ${entry.key} as ${entry.value}', (tester) async {
        await _open(tester, _allRepo());

        expect(find.byType(SwitchListTile), findsNWidgets(7));
        expect(switchTile(entry.value), findsOneWidget);
      });
    }

    testWidgets('lists the categories in the order returned', (tester) async {
      await _open(tester, _managementRepo());

      double top(String label) => tester.getTopLeft(switchTile(label)).dy;
      expect(top('Keluhan baru'), lessThan(top('Bukti transfer baru')));
      expect(top('Bukti transfer baru'), lessThan(top('Tagihan terlambat')));
      expect(top('Tagihan terlambat'), lessThan(top('Aktivitas akun')));
    });

    testWidgets('shows each switch as the API has it', (tester) async {
      final repo = FakeNotificationRepository(
        settings: [
          NotificationSettingItem(
            category: NotificationCategory.billing,
            pushEnabled: false,
          ),
          NotificationSettingItem(
            category: NotificationCategory.paymentStatus,
            pushEnabled: true,
          ),
          NotificationSettingItem(
            category: NotificationCategory.complaintProgress,
            pushEnabled: false,
          ),
        ],
      );
      await _open(tester, repo, role: _tenant);

      expect(isSwitchOn(tester, 'Tagihan dan pengingat'), isFalse);
      expect(isSwitchOn(tester, 'Status pembayaran'), isTrue);
      expect(isSwitchOn(tester, 'Perkembangan keluhan'), isFalse);
    });

    testWidgets('a switch has a target of at least 48 dp', (tester) async {
      await _open(tester, _managementRepo());

      expectTargetSize(tester, 'Tagihan terlambat');
    });

    testWidgets('a switch is announced with its label and state', (
      tester,
    ) async {
      await _open(tester, _managementRepo());

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(find.text('Tagihan terlambat'));
        expect(node.label, contains('Tagihan terlambat'));
        expect(node, isSemantics(hasToggledState: true, isToggled: true));
      } finally {
        handle.dispose();
      }
    });
  });

  group('urgency scope', () {
    testWidgets('is offered next to the new complaint category', (
      tester,
    ) async {
      await _open(tester, _managementRepo());

      expect(find.text('Semua urgensi'), findsOneWidget);
      expect(find.text('Hanya urgensi tinggi'), findsOneWidget);
    });

    testWidgets('shows the scope the API has', (tester) async {
      await _open(tester, _managementRepo());
      expectRadio(tester, 'Semua urgensi', selected: true);
      expectRadio(tester, 'Hanya urgensi tinggi', selected: false);
    });

    testWidgets('shows the high only scope when the API has it', (
      tester,
    ) async {
      final repo = FakeNotificationRepository(
        settings: [
          NotificationSettingItem(
            category: NotificationCategory.newComplaint,
            pushEnabled: true,
            urgencyScope: NotificationUrgencyScope.highOnly,
          ),
        ],
      );
      await _open(tester, repo);

      expectRadio(tester, 'Semua urgensi', selected: false);
      expectRadio(tester, 'Hanya urgensi tinggi', selected: true);
    });

    testWidgets('is still visible while the category is off', (tester) async {
      final repo = FakeNotificationRepository(
        settings: [
          NotificationSettingItem(
            category: NotificationCategory.newComplaint,
            pushEnabled: false,
            urgencyScope: NotificationUrgencyScope.allUrgencies,
          ),
        ],
      );
      await _open(tester, repo);

      expect(find.text('Semua urgensi'), findsOneWidget);
      expect(find.text('Hanya urgensi tinggi'), findsOneWidget);
    });

    testWidgets('is still visible after the category is switched off', (
      tester,
    ) async {
      await _open(tester, _managementRepo());

      await tester.tap(switchTile('Keluhan baru'));
      await tester.pumpAndSettle();

      expect(find.text('Semua urgensi'), findsOneWidget);
      expect(find.text('Hanya urgensi tinggi'), findsOneWidget);
    });

    testWidgets('is not offered when the category is not returned', (
      tester,
    ) async {
      await _open(tester, _tenantRepo(), role: _tenant);

      expect(find.text('Semua urgensi'), findsNothing);
      expect(find.text('Hanya urgensi tinggi'), findsNothing);
    });

    testWidgets('choosing a scope selects it and leaves the switch alone', (
      tester,
    ) async {
      await _open(tester, _managementRepo());

      await tester.tap(find.text('Hanya urgensi tinggi'));
      await tester.pumpAndSettle();

      expectRadio(tester, 'Semua urgensi', selected: false);
      expectRadio(tester, 'Hanya urgensi tinggi', selected: true);
      expect(isSwitchOn(tester, 'Keluhan baru'), isTrue);
    });

    testWidgets('choosing a scope sends no request', (tester) async {
      final repo = _managementRepo();
      await _open(tester, repo);

      await tester.tap(find.text('Hanya urgensi tinggi'));
      await tester.pumpAndSettle();

      expect(repo.updateSettingsCalls, 0);
    });

    testWidgets('the choices have a target of at least 48 dp', (tester) async {
      await _open(tester, _managementRepo());

      expectTargetSize(tester, 'Semua urgensi');
      expectTargetSize(tester, 'Hanya urgensi tinggi');
    });
  });

  group('editing', () {
    testWidgets('a tap flips a switch', (tester) async {
      await _open(tester, _managementRepo());

      await tester.tap(switchTile('Tagihan terlambat'));
      await tester.pumpAndSettle();

      expect(isSwitchOn(tester, 'Tagihan terlambat'), isFalse);
      expect(isSwitchOn(tester, 'Bukti transfer baru'), isTrue);

      await tester.tap(switchTile('Tagihan terlambat'));
      await tester.pumpAndSettle();

      expect(isSwitchOn(tester, 'Tagihan terlambat'), isTrue);
    });

    testWidgets('a change sends no request until Simpan is tapped', (
      tester,
    ) async {
      final repo = _managementRepo();
      await _open(tester, repo);

      await tester.tap(switchTile('Tagihan terlambat'));
      await tester.pumpAndSettle();

      expect(repo.updateSettingsCalls, 0);
      expect(find.text(_saved), findsNothing);
    });
  });

  group('saving', () {
    testWidgets('sends the whole list of the categories returned', (
      tester,
    ) async {
      final repo = _managementRepo();
      await _open(tester, repo);

      await _tapSave(tester);

      expect(repo.updateSettingsCalls, 1);
      final sent = repo.updated.single;
      expect(sent.map((i) => i.category), [
        NotificationCategory.newComplaint,
        NotificationCategory.receiptUpload,
        NotificationCategory.overdueBill,
        NotificationCategory.accountActivity,
      ]);
      expect(sent.map((i) => i.pushEnabled), everyElement(isTrue));
    });

    testWidgets('sends the urgency scope only for the new complaint category', (
      tester,
    ) async {
      final repo = _managementRepo();
      await _open(tester, repo);

      await _tapSave(tester);

      final sent = repo.updated.single;
      expect(sent.first.urgencyScope, NotificationUrgencyScope.allUrgencies);
      expect(sent.skip(1).map((i) => i.urgencyScope), everyElement(isNull));
    });

    testWidgets('sends no categories that were not returned', (tester) async {
      final repo = _tenantRepo();
      await _open(tester, repo, role: _tenant);

      await _tapSave(tester);

      expect(repo.updated.single.map((i) => i.category), [
        NotificationCategory.billing,
        NotificationCategory.paymentStatus,
        NotificationCategory.complaintProgress,
      ]);
      expect(
        repo.updated.single.map((i) => i.urgencyScope),
        everyElement(isNull),
      );
    });

    testWidgets('sends the edits of switches and scope', (tester) async {
      final repo = _managementRepo();
      await _open(tester, repo);

      await tester.tap(switchTile('Bukti transfer baru'));
      await tester.tap(switchTile('Aktivitas akun'));
      await tester.tap(find.text('Hanya urgensi tinggi'));
      await tester.pumpAndSettle();
      await _tapSave(tester);

      final sent = {for (final i in repo.updated.single) i.category: i};
      expect(sent[NotificationCategory.newComplaint]!.pushEnabled, isTrue);
      expect(
        sent[NotificationCategory.newComplaint]!.urgencyScope,
        NotificationUrgencyScope.highOnly,
      );
      expect(sent[NotificationCategory.receiptUpload]!.pushEnabled, isFalse);
      expect(sent[NotificationCategory.overdueBill]!.pushEnabled, isTrue);
      expect(sent[NotificationCategory.accountActivity]!.pushEnabled, isFalse);
    });

    testWidgets('sends the scope of a category that is switched off', (
      tester,
    ) async {
      final repo = _managementRepo();
      await _open(tester, repo);

      await tester.tap(switchTile('Keluhan baru'));
      await tester.tap(find.text('Hanya urgensi tinggi'));
      await tester.pumpAndSettle();
      await _tapSave(tester);

      final first = repo.updated.single.first;
      expect(first.category, NotificationCategory.newComplaint);
      expect(first.pushEnabled, isFalse);
      expect(first.urgencyScope, NotificationUrgencyScope.highOnly);
    });

    testWidgets('unchanged settings can still be saved', (tester) async {
      final repo = _tenantRepo();
      await _open(tester, repo, role: _tenant);

      expect(tester.widget<ButtonStyleButton>(_save).onPressed, isNotNull);
      await _tapSave(tester);

      expect(repo.updateSettingsCalls, 1);
      expect(find.text(_saved), findsOneWidget);
    });

    testWidgets('confirms with a message that stays on screen', (tester) async {
      await _open(tester, _managementRepo());
      expect(find.text(_saved), findsNothing);

      await _tapSave(tester);
      expect(find.text(_saved), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(find.text(_saved), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('announces the confirmation as a live region', (tester) async {
      await _open(tester, _managementRepo());

      await _tapSave(tester);

      expectLiveRegion(tester, _saved);
    });

    testWidgets('keeps the edits after saving', (tester) async {
      await _open(tester, _managementRepo());
      await tester.tap(switchTile('Tagihan terlambat'));
      await tester.tap(find.text('Hanya urgensi tinggi'));
      await tester.pumpAndSettle();

      await _tapSave(tester);

      expect(isSwitchOn(tester, 'Tagihan terlambat'), isFalse);
      expectRadio(tester, 'Hanya urgensi tinggi', selected: true);
    });

    testWidgets('shows the progress of a request in flight', (tester) async {
      final repo = _managementRepo()
        ..updateSettingsScript.gate = Completer<void>();
      await _open(tester, repo);

      await tester.tap(_save);
      await tester.pump();

      expectBusy(tester);
      expect(find.text(_saved), findsNothing);

      repo.updateSettingsScript.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.text(_saved), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('sends one request for a double tap', (tester) async {
      final repo = _managementRepo()
        ..updateSettingsScript.gate = Completer<void>();
      await _open(tester, repo);

      await tester.tap(_save);
      await tester.tap(_save, warnIfMissed: false);
      await tester.pump();
      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();
      repo.updateSettingsScript.gate!.complete();
      await tester.pumpAndSettle();

      expect(repo.updateSettingsCalls, 1);
    });

    testWidgets('shows the Indonesian message of a failure and keeps edits', (
      tester,
    ) async {
      final repo = _managementRepo()
        ..updateSettingsScript.always = const ApiFailure.network();
      await _open(tester, repo);
      await tester.tap(switchTile('Tagihan terlambat'));
      await tester.tap(find.text('Hanya urgensi tinggi'));
      await tester.pumpAndSettle();

      await _tapSave(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text(_saved), findsNothing);
      expect(isSwitchOn(tester, 'Tagihan terlambat'), isFalse);
      expectRadio(tester, 'Hanya urgensi tinggi', selected: true);
    });

    testWidgets('keeps the failure message on screen', (tester) async {
      final repo = _managementRepo()
        ..updateSettingsScript.always = const ApiFailure.network();
      await _open(tester, repo);
      await _tapSave(tester);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('announces the failure as a live region', (tester) async {
      final repo = _managementRepo()
        ..updateSettingsScript.always = const ApiFailure.network();
      await _open(tester, repo);

      await _tapSave(tester);

      expectLiveRegion(tester, messageOfCode('NETWORK_ERROR'));
    });

    testWidgets('shows the message of a forbidden failure', (tester) async {
      final repo = _managementRepo()
        ..updateSettingsScript.always = const ApiFailure(
          code: 'FORBIDDEN',
          statusCode: 403,
        );
      await _open(tester, repo);

      await _tapSave(tester);

      expect(find.text(messageOfCode('FORBIDDEN')), findsOneWidget);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _managementRepo()
        ..updateSettingsScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, repo);

      await _tapSave(tester);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('can be retried after a failure', (tester) async {
      final repo = _managementRepo()
        ..updateSettingsScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);
      await tester.tap(switchTile('Tagihan terlambat'));
      await tester.pumpAndSettle();
      await _tapSave(tester);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);

      await _tapSave(tester);

      expect(repo.updateSettingsCalls, 2);
      expect(repo.updated.last.map((i) => i.pushEnabled), [
        true,
        true,
        false,
        true,
      ]);
      expect(find.text(_saved), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('a success replaces the stored settings', (tester) async {
      final repo = _managementRepo();
      await _open(tester, repo);
      await tester.tap(switchTile('Aktivitas akun'));
      await tester.pumpAndSettle();

      await _tapSave(tester);

      expect(repo.settingItems.last.pushEnabled, isFalse);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _managementRepo()..settingsScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.byType(SwitchListTile), findsNothing);
      expect(appBarTitle('Pengaturan Notifikasi'), findsOneWidget);
    });

    testWidgets('shows the switches once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = _managementRepo()..settingsScript.gate = gate;
      await _open(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsNWidgets(4));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = _managementRepo()
        ..settingsScript.always = const ApiFailure.network();
      await _open(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
      expect(_save, findsNothing);
    });

    testWidgets('shows the message of a forbidden failure', (tester) async {
      final repo = _managementRepo()
        ..settingsScript.always = const ApiFailure(
          code: 'FORBIDDEN',
          statusCode: 403,
        );
      await _open(tester, repo);

      expect(find.text(messageOfCode('FORBIDDEN')), findsOneWidget);
    });

    testWidgets('a failure is not retried in the background', (tester) async {
      final repo = _managementRepo()
        ..settingsScript.always = const ApiFailure.network();
      await _open(tester, repo);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(repo.settingsCalls, 1);
    });

    testWidgets('Coba lagi loads the settings again', (tester) async {
      final repo = _managementRepo()
        ..settingsScript.queue.add(const ApiFailure.network());
      await _open(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.settingsCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.byType(SwitchListTile), findsNWidgets(4));
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines for a tenant', (tester) async {
      await _open(tester, _tenantRepo(), role: _tenant);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines for management', (tester) async {
      await _open(tester, _managementRepo());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with every category off', (tester) async {
      final repo = FakeNotificationRepository(
        settings: [
          NotificationSettingItem(
            category: NotificationCategory.newComplaint,
            pushEnabled: false,
            urgencyScope: NotificationUrgencyScope.highOnly,
          ),
          NotificationSettingItem(
            category: NotificationCategory.overdueBill,
            pushEnabled: false,
          ),
        ],
      );
      await _open(tester, repo);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines after saving', (tester) async {
      await _open(tester, _managementRepo());
      await _tapSave(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines after a failed save', (tester) async {
      final repo = _managementRepo()
        ..updateSettingsScript.always = const ApiFailure.network();
      await _open(tester, repo);
      await _tapSave(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines on failure to load', (tester) async {
      final repo = _managementRepo()
        ..settingsScript.always = const ApiFailure.network();
      await _open(tester, repo);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _managementRepo()..settingsScript.gate = Completer<void>();
      await _open(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('announces the title as a header', (tester) async {
      await _open(tester, _managementRepo());

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(appBarTitle('Pengaturan Notifikasi')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('fits at large text size for management', (tester) async {
      await _open(tester, _managementRepo(), largeText: true);

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _save,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size for a tenant', (tester) async {
      await _open(tester, _tenantRepo(), role: _tenant, largeText: true);

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        _save,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size after saving', (tester) async {
      await _open(tester, _managementRepo(), largeText: true);
      await tester.scrollUntilVisible(
        _save,
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await _tapSave(tester);

      expect(find.text(_saved), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size after a failed save', (tester) async {
      final repo = _managementRepo()
        ..updateSettingsScript.always = const ApiFailure.network();
      await _open(tester, repo, largeText: true);
      await tester.scrollUntilVisible(
        _save,
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await _tapSave(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size on failure to load', (tester) async {
      final repo = _managementRepo()
        ..settingsScript.always = const ApiFailure.network();
      await _open(tester, repo, largeText: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _managementRepo()..settingsScript.gate = Completer<void>();
      await _open(tester, repo, largeText: true, settle: false);

      expect(tester.takeException(), isNull);
    });
  });
}
