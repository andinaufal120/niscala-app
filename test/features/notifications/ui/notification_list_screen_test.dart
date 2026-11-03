import 'dart:async';

import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/notifications/ui/notification_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'notification_ui_helpers.dart';

const _tenant = UserRole.tenant;

/// Three unread and one read notification of a tenant, newest first.
List<Notification> _sample() {
  final bill = makeNotificationRentBill();
  return [
    makeNotification(
      id: 'n1',
      type: NotificationType.billIssued,
      rentBill: bill,
      createdAt: DateTime.utc(2026, 11, 2, 12),
    ),
    makeNotification(
      id: 'n2',
      type: NotificationType.dueDateReminder,
      rentBill: bill,
      createdAt: DateTime.utc(2026, 10, 31, 12),
    ),
    makeNotification(
      id: 'n3',
      type: NotificationType.paymentStatusChanged,
      read: true,
      rentBill: makeNotificationRentBill(
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.transfer,
      ),
      createdAt: DateTime.utc(2026, 10, 20, 12),
    ),
    makeNotification(
      id: 'n4',
      type: NotificationType.complaintStatusChanged,
      complaint: makeNotificationComplaint(
        status: ComplaintStatus.inProgress,
        handlingNote: 'Tukang datang besok',
      ),
      createdAt: DateTime.utc(2026, 10, 18, 12),
    ),
  ];
}

const _billIssuedBody =
    'Tagihan 1 Nov 2026 - 30 Nov 2026 sebesar Rp800.000, jatuh tempo 5 Nov 2026.';

FakeNotificationRepository _repo([List<Notification>? notifications]) =>
    FakeNotificationRepository(notifications: notifications ?? _sample());

Finder _inRow(String title, Finder matching) =>
    find.descendant(of: notificationRow(title), matching: matching);

void main() {
  group('screen', () {
    testWidgets('shows the title Notifikasi in the app bar', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      expect(find.byType(NotificationListScreen), findsOneWidget);
      expect(appBarTitle('Notifikasi'), findsOneWidget);
    });

    testWidgets('loads the notifications once', (tester) async {
      final repo = _repo();
      await pumpNotificationApp(tester, repo, role: _tenant);

      expect(repo.listCalls, 1);
    });

    testWidgets('covers the bottom navigation', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Kembali returns to the account tab', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      await pressBack(tester);

      expect(currentPath(tester), accountPath(_tenant));
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('rows', () {
    testWidgets('show the title, the body and the date of each notification', (
      tester,
    ) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      expect(find.text('Tagihan baru terbit'), findsOneWidget);
      expect(find.text(_billIssuedBody), findsNWidgets(2));
      expect(find.text('Tagihan hampir jatuh tempo'), findsOneWidget);
      expect(find.text('Pembayaran lunas'), findsOneWidget);
      expect(find.text('Keluhan diproses'), findsOneWidget);
      expect(find.text('Tukang datang besok'), findsOneWidget);
      expect(
        _inRow('Tagihan baru terbit', find.textContaining('2 Nov 2026')),
        findsOneWidget,
      );
      expect(
        _inRow(
          'Tagihan hampir jatuh tempo',
          find.textContaining('31 Okt 2026'),
        ),
        findsOneWidget,
      );
      expect(
        _inRow('Pembayaran lunas', find.textContaining('20 Okt 2026')),
        findsOneWidget,
      );
      expect(
        _inRow('Keluhan diproses', find.textContaining('18 Okt 2026')),
        findsOneWidget,
      );
    });

    testWidgets('keep the order of the response', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      double top(String title) => tester.getTopLeft(find.text(title)).dy;
      expect(
        top('Tagihan baru terbit'),
        lessThan(top('Tagihan hampir jatuh tempo')),
      );
      expect(
        top('Tagihan hampir jatuh tempo'),
        lessThan(top('Pembayaran lunas')),
      );
      expect(top('Pembayaran lunas'), lessThan(top('Keluhan diproses')));
    });

    testWidgets('keep the order of the response when it is not by date', (
      tester,
    ) async {
      final repo = _repo([_sample()[3], _sample()[0]]);
      await pumpNotificationApp(tester, repo, role: _tenant);

      expect(
        tester.getTopLeft(find.text('Keluhan diproses')).dy,
        lessThan(tester.getTopLeft(find.text('Tagihan baru terbit')).dy),
      );
    });

    testWidgets('show the date in local time, without a time of day', (
      tester,
    ) async {
      final evening = DateTime.utc(2026, 11, 2, 23, 30);
      final place = makeNotificationPlace();
      final repo = _repo([
        makeNotification(
          type: NotificationType.tenantActivated,
          tenant: place.tenant,
          room: place.room,
          property: place.property,
          createdAt: evening,
        ),
      ]);
      await pumpNotificationApp(tester, repo, role: UserRole.owner);

      expect(
        find.textContaining(formatDate(evening.toLocal())),
        findsOneWidget,
      );
      expect(find.textContaining(RegExp(r'\d{1,2}:\d{2}')), findsNothing);
    });

    const typeLabels = {
      NotificationType.billIssued: 'Tagihan',
      NotificationType.dueDateReminder: 'Tagihan',
      NotificationType.billOverdue: 'Tagihan',
      NotificationType.paymentStatusChanged: 'Pembayaran',
      NotificationType.receiptUploaded: 'Pembayaran',
      NotificationType.cashPaymentRecorded: 'Pembayaran',
      NotificationType.complaintStatusChanged: 'Keluhan',
      NotificationType.complaintSubmitted: 'Keluhan',
      NotificationType.tenantActivated: 'Akun',
      NotificationType.managerActivated: 'Akun',
    };
    for (final entry in typeLabels.entries) {
      testWidgets('show the type label ${entry.value} for ${entry.key}', (
        tester,
      ) async {
        final place = makeNotificationPlace();
        final repo = _repo([
          makeNotification(
            type: entry.key,
            rentBill: makeNotificationRentBill(),
            complaint: makeNotificationComplaint(),
            tenant: place.tenant,
            room: place.room,
            property: place.property,
            actorName: 'Siti Pemilik',
          ),
        ]);
        await pumpNotificationApp(tester, repo, role: UserRole.owner);

        final card = find.byType(Card);
        expect(card, findsOneWidget);
        expect(
          find.descendant(of: card, matching: find.text(entry.value)),
          findsOneWidget,
        );
      });
    }

    testWidgets('mark an unread notification with a dot and the words', (
      tester,
    ) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      expect(unreadDotOf('Tagihan baru terbit'), findsOneWidget);
      expect(unreadDotOf('Tagihan hampir jatuh tempo'), findsOneWidget);
      expect(unreadDotOf('Keluhan diproses'), findsOneWidget);
      expect(unreadDots(), findsNWidgets(3));
      expect(rowLabel(tester, 'Tagihan baru terbit'), contains('Belum dibaca'));
      expect(rowLabel(tester, 'Keluhan diproses'), contains('Belum dibaca'));
    });

    testWidgets('mark a read notification with neither dot nor words', (
      tester,
    ) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      expect(unreadDotOf('Pembayaran lunas'), findsNothing);
      expect(
        rowLabel(tester, 'Pembayaran lunas'),
        isNot(contains('Belum dibaca')),
      );
    });

    testWidgets('draw the title of an unread notification bolder', (
      tester,
    ) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      final unread = titleWeight(tester, 'Tagihan baru terbit');
      final read = titleWeight(tester, 'Pembayaran lunas');
      expect(unread, isNotNull);
      expect(unread!.value, greaterThanOrEqualTo(FontWeight.w600.value));
      expect(read == null || read.value < unread.value, isTrue);
    });

    testWidgets('read as one item with the title and the body', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      final label = rowLabel(tester, 'Tagihan baru terbit');
      expect(label, contains('Tagihan baru terbit'));
      expect(label, contains(_billIssuedBody));
    });

    testWidgets('are at least 48 dp tall targets', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      expectTargetSize(tester, 'Tagihan baru terbit');
    });

    testWidgets('open the notification on tap', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      await tester.tap(find.text('Pembayaran lunas'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), notificationPath(_tenant, 'n3'));
      expect(appBarTitle('Detail Notifikasi'), findsOneWidget);
    });

    testWidgets('open the notification under the management path', (
      tester,
    ) async {
      await pumpNotificationApp(tester, _repo(), role: UserRole.manager);

      await tester.tap(find.text('Pembayaran lunas'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/akun/notifikasi/n3');
    });

    testWidgets('lists management notifications under the management path', (
      tester,
    ) async {
      final place = makeNotificationPlace();
      final repo = _repo([
        makeNotification(
          type: NotificationType.tenantActivated,
          tenant: place.tenant,
          room: place.room,
          property: place.property,
        ),
      ]);
      await pumpNotificationApp(tester, repo, role: UserRole.owner);

      expect(currentPath(tester), '/akun/notifikasi');
      expect(find.text('Budi Santoso mengaktifkan akun'), findsOneWidget);
    });
  });

  group('unread count', () {
    testWidgets('is shown in the header area while notifications are unread', (
      tester,
    ) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      expect(find.text('3 belum dibaca'), findsOneWidget);
    });

    testWidgets('follows the count the API reports', (tester) async {
      final repo = _repo();
      repo.unreadCount = 12;
      await pumpNotificationApp(tester, repo, role: _tenant);

      expect(find.text('12 belum dibaca'), findsOneWidget);
    });

    testWidgets('is not shown when every notification is read', (tester) async {
      final repo = _repo([_sample()[2]]);
      await pumpNotificationApp(tester, repo, role: _tenant);

      expect(find.textContaining('belum dibaca'), findsNothing);
      expect(unreadDots(), findsNothing);
    });
  });

  group('mark all read', () {
    testWidgets('is offered while notifications are unread', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      expect(buttonLabelled('Tandai semua dibaca'), findsOneWidget);
    });

    testWidgets('is not offered when every notification is read', (
      tester,
    ) async {
      final repo = _repo([_sample()[2]]);
      await pumpNotificationApp(tester, repo, role: _tenant);

      expect(find.text('Tandai semua dibaca'), findsNothing);
    });

    testWidgets('marks every row read, clears the count and the button', (
      tester,
    ) async {
      final repo = _repo();
      await pumpNotificationApp(tester, repo, role: _tenant);

      await tester.tap(buttonLabelled('Tandai semua dibaca'));
      await tester.pumpAndSettle();

      expect(repo.markAllReadCalls, 1);
      expect(unreadDots(), findsNothing);
      expect(find.textContaining('belum dibaca'), findsNothing);
      expect(find.text('Tandai semua dibaca'), findsNothing);
      expect(
        rowLabel(tester, 'Tagihan baru terbit'),
        isNot(contains('Belum dibaca')),
      );
    });

    testWidgets('does not ask for confirmation', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      await tester.tap(buttonLabelled('Tandai semua dibaca'));
      await tester.pump();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('keeps every notification in the list', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      await tester.tap(buttonLabelled('Tandai semua dibaca'));
      await tester.pumpAndSettle();

      expect(find.text('Tagihan baru terbit'), findsOneWidget);
      expect(find.text('Keluhan diproses'), findsOneWidget);
      expect(find.text('Pembayaran lunas'), findsOneWidget);
    });

    testWidgets('sends one request for a double tap', (tester) async {
      final repo = _repo()..markAllReadScript.gate = Completer<void>();
      await pumpNotificationApp(tester, repo, role: _tenant);
      final button = buttonLabelled('Tandai semua dibaca');

      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      repo.markAllReadScript.gate!.complete();
      await tester.pumpAndSettle();

      expect(repo.markAllReadCalls, 1);
    });

    testWidgets('shows the Indonesian message of a failure and keeps unread', (
      tester,
    ) async {
      final repo = _repo()
        ..markAllReadScript.always = const ApiFailure.network();
      await pumpNotificationApp(tester, repo, role: _tenant);

      await tester.tap(buttonLabelled('Tandai semua dibaca'));
      await tester.pumpAndSettle();

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(unreadDots(), findsNWidgets(3));
      expect(find.text('3 belum dibaca'), findsOneWidget);
      expect(buttonLabelled('Tandai semua dibaca'), findsOneWidget);
    });

    testWidgets('can be retried after a failure', (tester) async {
      final repo = _repo()
        ..markAllReadScript.queue.add(const ApiFailure.network());
      await pumpNotificationApp(tester, repo, role: _tenant);
      await tester.tap(buttonLabelled('Tandai semua dibaca'));
      await tester.pumpAndSettle();

      await tester.tap(buttonLabelled('Tandai semua dibaca'));
      await tester.pumpAndSettle();

      expect(repo.markAllReadCalls, 2);
      expect(unreadDots(), findsNothing);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
    });

    testWidgets('has a target of at least 48 dp', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      expectTargetSize(tester, 'Tandai semua dibaca');
    });
  });

  group('settings action', () {
    testWidgets('is an icon button with a tooltip', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      expect(find.byTooltip('Pengaturan notifikasi'), findsOneWidget);
    });

    testWidgets('has a target of at least 48 dp', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      final rect = tester.getRect(find.byTooltip('Pengaturan notifikasi'));
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
    });

    testWidgets('opens the settings of a tenant', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      await tester.tap(find.byTooltip('Pengaturan notifikasi'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), notificationSettingsPath(_tenant));
      expect(appBarTitle('Pengaturan Notifikasi'), findsOneWidget);
    });

    testWidgets('opens the settings of management', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: UserRole.owner);

      await tester.tap(find.byTooltip('Pengaturan notifikasi'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/akun/notifikasi/pengaturan');
    });

    testWidgets('is offered when there are no notifications', (tester) async {
      await pumpNotificationApp(tester, _repo([]), role: _tenant);

      expect(find.byTooltip('Pengaturan notifikasi'), findsOneWidget);
    });

    testWidgets('returns to the list with Kembali', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);
      await tester.tap(find.byTooltip('Pengaturan notifikasi'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), notificationsPath(_tenant));
      expect(find.text('Tagihan baru terbit'), findsOneWidget);
    });
  });

  group('empty state', () {
    testWidgets('says there are no notifications', (tester) async {
      await pumpNotificationApp(tester, _repo([]), role: _tenant);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.textContaining('Belum ada notifikasi'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(find.text('Tandai semua dibaca'), findsNothing);
      expect(find.textContaining('belum dibaca'), findsNothing);
    });

    testWidgets('explains itself with a sentence for the role', (tester) async {
      String shownMessage() {
        final text = find.descendant(
          of: find.byType(EmptyState),
          matching: find.byType(Text),
        );
        return tester.widget<Text>(text.first).data!;
      }

      await pumpNotificationApp(tester, _repo([]), role: _tenant);
      final tenantMessage = shownMessage();
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpNotificationApp(tester, _repo([]), role: UserRole.owner);
      final managementMessage = shownMessage();

      expect(tenantMessage, startsWith('Belum ada notifikasi'));
      expect(managementMessage, startsWith('Belum ada notifikasi'));
      expect(tenantMessage.length, greaterThan('Belum ada notifikasi.'.length));
      expect(
        managementMessage.length,
        greaterThan('Belum ada notifikasi.'.length),
      );
      expect(managementMessage, isNot(tenantMessage));
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpNotificationApp(tester, repo, role: _tenant, settle: false);

      expectLoading(tester);
      expect(find.text('Tagihan baru terbit'), findsNothing);
      expect(appBarTitle('Notifikasi'), findsOneWidget);
    });

    testWidgets('shows the notifications once loading finishes', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _repo()..listScript.gate = gate;
      await pumpNotificationApp(tester, repo, role: _tenant, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Tagihan baru terbit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpNotificationApp(tester, repo, role: _tenant);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Tagihan baru terbit'), findsNothing);
    });

    testWidgets('shows the message of a forbidden failure', (tester) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(
          code: 'FORBIDDEN',
          statusCode: 403,
        );
      await pumpNotificationApp(tester, repo, role: _tenant);

      expect(find.text(messageOfCode('FORBIDDEN')), findsOneWidget);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpNotificationApp(tester, repo, role: _tenant);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('a failure is not retried in the background', (tester) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpNotificationApp(tester, repo, role: _tenant);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 1);
    });

    testWidgets('Coba lagi loads the notifications again', (tester) async {
      final repo = _repo()..listScript.queue.add(const ApiFailure.network());
      await pumpNotificationApp(tester, repo, role: _tenant);
      expect(repo.listCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Tagihan baru terbit'), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final repo = _repo()
        ..listScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await pumpNotificationApp(tester, repo, role: _tenant);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines when loaded', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines when loaded for management', (
      tester,
    ) async {
      final place = makeNotificationPlace();
      final repo = _repo([
        makeNotification(
          type: NotificationType.receiptUploaded,
          rentBill: makeNotificationRentBill(),
          tenant: place.tenant,
          room: place.room,
          property: place.property,
        ),
        makeNotification(
          id: 'n2',
          read: true,
          type: NotificationType.tenantActivated,
          tenant: place.tenant,
          room: place.room,
          property: place.property,
        ),
      ]);
      await pumpNotificationApp(tester, repo, role: UserRole.manager);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines when every notification is read', (
      tester,
    ) async {
      await pumpNotificationApp(tester, _repo([_sample()[2]]), role: _tenant);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines when empty', (tester) async {
      await pumpNotificationApp(tester, _repo([]), role: _tenant);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines on failure', (tester) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpNotificationApp(tester, repo, role: _tenant);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpNotificationApp(tester, repo, role: _tenant, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('announces the title as a header', (tester) async {
      await pumpNotificationApp(tester, _repo(), role: _tenant);

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(appBarTitle('Notifikasi')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('fits at large text size when loaded', (tester) async {
      await pumpNotificationApp(
        tester,
        _repo(),
        role: _tenant,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Tandai semua dibaca'), findsOneWidget);
    });

    testWidgets('reaches the last row at large text size', (tester) async {
      await pumpNotificationApp(
        tester,
        _repo(),
        role: _tenant,
        largeText: true,
      );

      await tester.scrollUntilVisible(
        find.text('Keluhan diproses'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Keluhan diproses'), findsOneWidget);
    });

    testWidgets('fits at large text size with long text', (tester) async {
      final repo = _repo([
        makeNotification(
          type: NotificationType.complaintStatusChanged,
          complaint: makeNotificationComplaint(
            status: ComplaintStatus.inProgress,
            handlingNote:
                'Tukang ledeng akan datang besok pagi untuk memperbaiki keran '
                'dan pipa yang bocor di kamar mandi lantai dua.',
          ),
        ),
      ]);
      await pumpNotificationApp(tester, repo, role: _tenant, largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Tukang ledeng akan datang'), findsOneWidget);
    });

    testWidgets('fits at large text size when empty', (tester) async {
      await pumpNotificationApp(
        tester,
        _repo([]),
        role: _tenant,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Belum ada notifikasi'), findsOneWidget);
    });

    testWidgets('fits at large text size on failure', (tester) async {
      final repo = _repo()..listScript.always = const ApiFailure.network();
      await pumpNotificationApp(tester, repo, role: _tenant, largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = _repo()..listScript.gate = Completer<void>();
      await pumpNotificationApp(
        tester,
        repo,
        role: _tenant,
        largeText: true,
        settle: false,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
