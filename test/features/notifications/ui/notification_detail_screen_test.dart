import 'dart:async';

import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/notifications/ui/notification_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'notification_ui_helpers.dart';

const _tenant = UserRole.tenant;
const _owner = UserRole.owner;

/// A receipt upload that management reads, with every fact the API can send.
Notification _receipt({String id = 'n1', bool read = false}) {
  final place = makeNotificationPlace();
  return makeNotification(
    id: id,
    read: read,
    type: NotificationType.receiptUploaded,
    rentBill: makeNotificationRentBill(
      paymentStatus: PaymentStatus.awaitingVerification,
      paymentMethod: PaymentMethod.transfer,
      reason: 'Menunggu pengecekan',
    ),
    tenant: place.tenant,
    room: place.room,
    property: place.property,
    actorName: 'Siti Pemilik',
  );
}

Notification _bill(NotificationType type) {
  final place = makeNotificationPlace();
  return makeNotification(
    type: type,
    rentBill: makeNotificationRentBill(),
    tenant: place.tenant,
    room: place.room,
    property: place.property,
    actorName: 'Siti Pemilik',
  );
}

Notification _complaint(NotificationType type) {
  final place = makeNotificationPlace();
  return makeNotification(
    type: type,
    complaint: makeNotificationComplaint(
      status: ComplaintStatus.inProgress,
      description: 'Keran air bocor',
      category: 'Pipa dan air',
      urgency: ComplaintUrgency.high,
      handlingNote: 'Tukang datang besok',
    ),
    tenant: place.tenant,
    room: place.room,
    property: place.property,
  );
}

FakeNotificationRepository _repo(List<Notification> notifications) =>
    FakeNotificationRepository(notifications: notifications);

Future<void> _openDetail(
  WidgetTester tester,
  FakeNotificationRepository repo, {
  UserRole role = _owner,
  String id = 'n1',
  bool settle = true,
  bool largeText = false,
}) => pumpNotificationApp(
  tester,
  repo,
  role: role,
  path: notificationPath(role, id),
  settle: settle,
  largeText: largeText,
);

void main() {
  group('screen', () {
    testWidgets('shows the title Detail Notifikasi in the app bar', (
      tester,
    ) async {
      await _openDetail(tester, _repo([_receipt()]));

      expect(find.byType(NotificationDetailScreen), findsOneWidget);
      expect(appBarTitle('Detail Notifikasi'), findsOneWidget);
    });

    testWidgets('shows the type label, title, body and date', (tester) async {
      await _openDetail(tester, _repo([_receipt()]));

      expect(find.text('Pembayaran'), findsWidgets);
      expect(find.text('Budi Santoso mengunggah bukti transfer'), findsWidgets);
      expect(
        find.text('Kamar 08 · tagihan 1 Nov 2026 - 30 Nov 2026 Rp800.000.'),
        findsWidgets,
      );
      expect(find.textContaining('2 Nov 2026'), findsWidgets);
      expect(find.textContaining(RegExp(r'\d{1,2}:\d{2}')), findsNothing);
    });

    testWidgets('covers the bottom navigation', (tester) async {
      await _openDetail(tester, _repo([_receipt()]));

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Kembali returns to the list', (tester) async {
      await _openDetail(tester, _repo([_receipt()]));

      await pressBack(tester);

      expect(currentPath(tester), notificationsPath(_owner));
      expect(appBarTitle('Notifikasi'), findsOneWidget);
    });

    testWidgets('is opened from a row of the list', (tester) async {
      final repo = _repo([_receipt()]);
      await pumpNotificationApp(tester, repo, role: _owner);

      await tester.tap(find.text('Budi Santoso mengunggah bukti transfer'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), notificationPath(_owner, 'n1'));
      expect(find.byType(NotificationDetailScreen), findsOneWidget);
    });

    testWidgets('is opened for a tenant under the tenant path', (tester) async {
      final repo = _repo([_bill(NotificationType.billIssued)]);
      await _openDetail(tester, repo, role: _tenant);

      expect(currentPath(tester), '/penyewa/akun/notifikasi/n1');
      expect(find.text('Tagihan baru terbit'), findsWidgets);
    });

    testWidgets('does not read the settings path as a notification', (
      tester,
    ) async {
      final repo = _repo([_receipt()]);
      await pumpNotificationApp(
        tester,
        repo,
        role: _owner,
        path: notificationSettingsPath(_owner),
      );

      expect(find.byType(NotificationDetailScreen), findsNothing);
      expect(appBarTitle('Pengaturan Notifikasi'), findsOneWidget);
      expect(repo.markReadCalls, 0);
    });
  });

  group('marking read', () {
    testWidgets('marks the notification read when it opens', (tester) async {
      final repo = _repo([_receipt()]);
      await _openDetail(tester, repo);

      expect(repo.calls, contains('markRead:n1'));
      expect(repo.markReadCalls, 1);
      expect(repo.notifications.single.read, isTrue);
      expect(repo.unreadCount, 0);
    });

    testWidgets('marks it once however long it stays open', (tester) async {
      final repo = _repo([_receipt()]);
      await _openDetail(tester, repo);

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();

      expect(repo.markReadCalls, 1);
    });

    testWidgets('does not mark the other notifications', (tester) async {
      final repo = _repo([_receipt(), _receipt(id: 'n2')]);
      await _openDetail(tester, repo);

      expect(repo.calls, isNot(contains('markRead:n2')));
      expect(repo.notifications.last.read, isFalse);
      expect(repo.unreadCount, 1);
    });

    testWidgets('the list shows the notification read afterwards', (
      tester,
    ) async {
      final repo = _repo([_receipt(), _receipt(id: 'n2'), _receipt(id: 'n3')]);
      await pumpNotificationApp(tester, repo, role: _owner);
      expect(find.text('3 belum dibaca'), findsOneWidget);

      await tester.tap(
        find.text('Budi Santoso mengunggah bukti transfer').first,
      );
      await tester.pumpAndSettle();
      await pressBack(tester);

      expect(find.text('2 belum dibaca'), findsOneWidget);
      expect(unreadDots(), findsNWidgets(2));
    });

    testWidgets('the list drops the count when the last one is read', (
      tester,
    ) async {
      final repo = _repo([_receipt()]);
      await _openDetail(tester, repo);

      await pressBack(tester);

      expect(find.textContaining('belum dibaca'), findsNothing);
      expect(unreadDots(), findsNothing);
      expect(find.text('Tandai semua dibaca'), findsNothing);
    });

    testWidgets('a failing request does not block showing the notification', (
      tester,
    ) async {
      final repo = _repo([_receipt()])
        ..markReadScript.always = const ApiFailure.network();
      await _openDetail(tester, repo);

      expect(repo.markReadCalls, 1);
      expect(find.text('Budi Santoso mengunggah bukti transfer'), findsWidgets);
      expect(find.text('Notifikasi tidak ditemukan.'), findsNothing);
    });

    testWidgets('a failing request shows no error', (tester) async {
      final repo = _repo([_receipt()])
        ..markReadScript.always = const ApiFailure.network();
      await _openDetail(tester, repo);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Coba lagi'), findsNothing);
    });

    testWidgets(
      'a failing request leaves the notification unread in the list',
      (tester) async {
        final repo = _repo([_receipt()])
          ..markReadScript.always = const ApiFailure.network();
        await _openDetail(tester, repo);

        await pressBack(tester);

        expect(unreadDots(), findsOneWidget);
        expect(find.text('1 belum dibaca'), findsOneWidget);
      },
    );

    testWidgets('shows the notification while the request is in flight', (
      tester,
    ) async {
      final repo = _repo([_receipt()])..markReadScript.gate = Completer<void>();
      await _openDetail(tester, repo, settle: false);

      expect(find.text('Budi Santoso mengunggah bukti transfer'), findsWidgets);
    });
  });

  group('finding the notification', () {
    testWidgets('loads the list when it was not loaded yet', (tester) async {
      final repo = _repo([_receipt()]);
      await _openDetail(tester, repo);

      expect(repo.listCalls, greaterThanOrEqualTo(1));
      expect(find.text('Notifikasi tidak ditemukan.'), findsNothing);
    });

    testWidgets('reloads the list when the id is not in the loaded one', (
      tester,
    ) async {
      final repo = _repo([_receipt()]);
      await pumpNotificationApp(tester, repo, role: _owner);
      final loaded = repo.listCalls;
      repo.add(_receipt(id: 'n9'));

      goTo(tester, notificationPath(_owner, 'n9'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, greaterThan(loaded));
      expect(find.text('Notifikasi tidak ditemukan.'), findsNothing);
      expect(find.text('Budi Santoso mengunggah bukti transfer'), findsWidgets);
      expect(repo.calls, contains('markRead:n9'));
    });

    testWidgets('says so when the id is not found', (tester) async {
      final repo = _repo([_receipt()]);
      await _openDetail(tester, repo, id: 'missing');

      expect(find.text('Notifikasi tidak ditemukan.'), findsOneWidget);
      expect(appBarTitle('Detail Notifikasi'), findsOneWidget);
      expect(repo.markReadCalls, 0);
    });

    testWidgets('says so after reloading when the id is still not found', (
      tester,
    ) async {
      final repo = _repo([_receipt()]);
      await pumpNotificationApp(tester, repo, role: _owner);
      final loaded = repo.listCalls;

      goTo(tester, notificationPath(_owner, 'missing'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, greaterThan(loaded));
      expect(find.text('Notifikasi tidak ditemukan.'), findsOneWidget);
      expect(repo.markReadCalls, 0);
    });

    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = _repo([_receipt()])..listScript.gate = Completer<void>();
      await _openDetail(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Notifikasi tidak ditemukan.'), findsNothing);
    });

    testWidgets('shows the message of a failure to load, with a retry', (
      tester,
    ) async {
      final repo = _repo([_receipt()])
        ..listScript.queue.add(const ApiFailure.network());
      await _openDetail(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Budi Santoso mengunggah bukti transfer'), findsWidgets);
      expect(repo.markReadCalls, 1);
    });
  });

  group('facts', () {
    testWidgets('show the tenant, room, property and actor', (tester) async {
      await _openDetail(tester, _repo([_receipt()]));

      expect(find.text('Penyewa'), findsOneWidget);
      expect(find.textContaining('Budi Santoso'), findsWidgets);
      expect(find.text('Kamar'), findsOneWidget);
      expect(find.text('Properti'), findsOneWidget);
      expect(find.textContaining('Kos Melati'), findsWidgets);
      expect(find.text('Dilakukan oleh'), findsOneWidget);
      expect(find.textContaining('Siti Pemilik'), findsWidgets);
    });

    testWidgets('show the period, amount, due date, status and reason', (
      tester,
    ) async {
      await _openDetail(tester, _repo([_receipt()]));

      expect(find.text('Periode'), findsOneWidget);
      expect(find.textContaining('1 Nov 2026 - 30 Nov 2026'), findsWidgets);
      expect(find.text('Jumlah'), findsOneWidget);
      expect(find.textContaining('Rp800.000'), findsWidgets);
      expect(find.text('Jatuh tempo'), findsOneWidget);
      expect(find.textContaining('5 Nov 2026'), findsWidgets);
      expect(find.text('Status pembayaran'), findsOneWidget);
      expect(find.textContaining('Menunggu Verifikasi'), findsWidgets);
      expect(find.text('Alasan'), findsOneWidget);
      expect(find.textContaining('Menunggu pengecekan'), findsWidgets);
    });

    testWidgets('show the payment method of a paid bill', (tester) async {
      final repo = _repo([
        makeNotification(
          type: NotificationType.paymentStatusChanged,
          rentBill: makeNotificationRentBill(
            paymentStatus: PaymentStatus.paid,
            paymentMethod: PaymentMethod.cash,
          ),
        ),
      ]);
      await _openDetail(tester, repo, role: _tenant);

      expect(find.text('Metode pembayaran'), findsOneWidget);
      expect(find.textContaining('Tunai'), findsWidgets);
      expect(find.text('Status pembayaran'), findsOneWidget);
      expect(find.textContaining('Lunas'), findsWidgets);
    });

    testWidgets('omit the facts a bill does not carry', (tester) async {
      final repo = _repo([
        makeNotification(
          type: NotificationType.billIssued,
          rentBill: makeNotificationRentBill(),
        ),
      ]);
      await _openDetail(tester, repo, role: _tenant);

      expect(find.text('Periode'), findsOneWidget);
      expect(find.text('Alasan'), findsNothing);
      expect(find.text('Metode pembayaran'), findsNothing);
      expect(find.text('Penyewa'), findsNothing);
      expect(find.text('Kamar'), findsNothing);
      expect(find.text('Properti'), findsNothing);
      expect(find.text('Dilakukan oleh'), findsNothing);
      expect(find.text('Isi keluhan'), findsNothing);
    });

    testWidgets('show the complaint facts', (tester) async {
      await _openDetail(
        tester,
        _repo([_complaint(NotificationType.complaintSubmitted)]),
      );

      expect(find.text('Isi keluhan'), findsOneWidget);
      expect(find.textContaining('Keran air bocor'), findsWidgets);
      expect(find.text('Status keluhan'), findsOneWidget);
      expect(find.textContaining('Diproses'), findsWidgets);
      expect(find.text('Kategori'), findsOneWidget);
      expect(find.textContaining('Pipa dan air'), findsWidgets);
      expect(find.text('Urgensi'), findsOneWidget);
      expect(find.textContaining('Tinggi'), findsWidgets);
      expect(find.text('Catatan penanganan'), findsOneWidget);
      expect(find.textContaining('Tukang datang besok'), findsWidgets);
    });

    testWidgets('omit the complaint facts that are not set', (tester) async {
      final repo = _repo([
        makeNotification(
          type: NotificationType.complaintStatusChanged,
          complaint: makeNotificationComplaint(description: 'Keran bocor'),
        ),
      ]);
      await _openDetail(tester, repo, role: _tenant);

      expect(find.text('Isi keluhan'), findsOneWidget);
      expect(find.text('Status keluhan'), findsOneWidget);
      expect(find.text('Kategori'), findsNothing);
      expect(find.text('Urgensi'), findsNothing);
      expect(find.text('Catatan penanganan'), findsNothing);
    });

    testWidgets('show the tenant and property of an activation', (
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
      await _openDetail(tester, repo);

      expect(find.text('Penyewa'), findsOneWidget);
      expect(find.text('Kamar'), findsOneWidget);
      expect(find.text('Properti'), findsOneWidget);
      expect(find.text('Periode'), findsNothing);
    });
  });

  group('link to the related page', () {
    const billTypes = [
      NotificationType.billIssued,
      NotificationType.dueDateReminder,
      NotificationType.billOverdue,
      NotificationType.paymentStatusChanged,
      NotificationType.receiptUploaded,
      NotificationType.cashPaymentRecorded,
    ];
    for (final role in [_owner, UserRole.manager]) {
      for (final type in billTypes) {
        testWidgets('Lihat tagihan of $type opens the bill for a $role', (
          tester,
        ) async {
          await _openDetail(tester, _repo([_bill(type)]), role: role);

          expect(buttonLabelled('Lihat tagihan'), findsOneWidget);
          expect(find.text('Lihat keluhan'), findsNothing);
          await tester.tap(buttonLabelled('Lihat tagihan'));
          await tester.pumpAndSettle();

          expect(currentPath(tester), '/pembayaran/tagihan/b1');
        });
      }
    }

    testWidgets(
      'the bill page is pushed, so going back returns to the detail',
      (tester) async {
        await _openDetail(tester, _repo([_receipt()]));
        await tester.tap(buttonLabelled('Lihat tagihan'));
        await tester.pumpAndSettle();

        popRoute(tester);
        await tester.pumpAndSettle();

        expect(currentPath(tester), notificationPath(_owner, 'n1'));
        expect(appBarTitle('Detail Notifikasi'), findsOneWidget);
      },
    );

    for (final type in [
      NotificationType.billIssued,
      NotificationType.dueDateReminder,
      NotificationType.billOverdue,
      NotificationType.paymentStatusChanged,
    ]) {
      testWidgets('Lihat tagihan of $type opens the payments of a tenant', (
        tester,
      ) async {
        await _openDetail(tester, _repo([_bill(type)]), role: _tenant);

        await tester.tap(buttonLabelled('Lihat tagihan'));
        await tester.pumpAndSettle();

        expect(currentPath(tester), '/penyewa/pembayaran');
      });
    }

    for (final role in [_owner, UserRole.manager]) {
      testWidgets('Lihat keluhan opens the complaint for a $role', (
        tester,
      ) async {
        await _openDetail(
          tester,
          _repo([_complaint(NotificationType.complaintSubmitted)]),
          role: role,
        );

        expect(buttonLabelled('Lihat keluhan'), findsOneWidget);
        expect(find.text('Lihat tagihan'), findsNothing);
        await tester.tap(buttonLabelled('Lihat keluhan'));
        await tester.pumpAndSettle();

        expect(currentPath(tester), '/keluhan/c1');
      });
    }

    testWidgets('Lihat keluhan opens the complaint of a tenant', (
      tester,
    ) async {
      await _openDetail(
        tester,
        _repo([_complaint(NotificationType.complaintStatusChanged)]),
        role: _tenant,
      );

      await tester.tap(buttonLabelled('Lihat keluhan'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/penyewa/keluhan/c1');
    });

    for (final type in [
      NotificationType.tenantActivated,
      NotificationType.managerActivated,
    ]) {
      testWidgets('$type has no link', (tester) async {
        final place = makeNotificationPlace();
        final repo = _repo([
          makeNotification(
            type: type,
            tenant: place.tenant,
            room: place.room,
            property: place.property,
            actorName: 'Rina Putri',
          ),
        ]);
        await _openDetail(tester, repo);

        expect(find.text('Lihat tagihan'), findsNothing);
        expect(find.text('Lihat keluhan'), findsNothing);
      });
    }

    testWidgets('the links have a target of at least 48 dp', (tester) async {
      await _openDetail(tester, _repo([_receipt()]));

      expectTargetSize(tester, 'Lihat tagihan');
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines for a bill of management', (
      tester,
    ) async {
      await _openDetail(tester, _repo([_receipt()]));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines for a complaint of a tenant', (
      tester,
    ) async {
      await _openDetail(
        tester,
        _repo([_complaint(NotificationType.complaintStatusChanged)]),
        role: _tenant,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines for an account activity', (tester) async {
      final place = makeNotificationPlace();
      final repo = _repo([
        makeNotification(
          type: NotificationType.tenantActivated,
          tenant: place.tenant,
          room: place.room,
          property: place.property,
        ),
      ]);
      await _openDetail(tester, repo);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines when the notification is not found', (
      tester,
    ) async {
      await _openDetail(tester, _repo([_receipt()]), id: 'missing');

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines on failure to load', (tester) async {
      final repo = _repo([_receipt()])
        ..listScript.always = const ApiFailure.network();
      await _openDetail(tester, repo);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = _repo([_receipt()])..listScript.gate = Completer<void>();
      await _openDetail(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('announces the title as a header', (tester) async {
      await _openDetail(tester, _repo([_receipt()]));

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(appBarTitle('Detail Notifikasi')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('fits at large text size for a bill of management', (
      tester,
    ) async {
      await _openDetail(tester, _repo([_receipt()]), largeText: true);

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Lihat tagihan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size for a complaint', (tester) async {
      await _openDetail(
        tester,
        _repo([_complaint(NotificationType.complaintSubmitted)]),
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Lihat keluhan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at large text size when not found', (tester) async {
      await _openDetail(
        tester,
        _repo([_receipt()]),
        id: 'missing',
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Notifikasi tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('fits at large text size on failure to load', (tester) async {
      final repo = _repo([_receipt()])
        ..listScript.always = const ApiFailure.network();
      await _openDetail(tester, repo, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
