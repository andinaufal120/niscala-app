import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import 'notification_ui_helpers.dart';

const _period = '1 Nov 2026 - 30 Nov 2026';
const _billBody = 'Tagihan $_period sebesar Rp800.000, jatuh tempo 5 Nov 2026.';

typedef _Case = ({
  String name,
  Notification notification,
  String title,
  String body,
});

_Case _case(
  String name,
  Notification notification,
  String title,
  String body,
) => (name: name, notification: notification, title: title, body: body);

/// The titles and bodies a tenant reads.
List<_Case> _tenantCases() => [
  _case(
    'a new bill',
    makeNotification(
      type: NotificationType.billIssued,
      rentBill: makeNotificationRentBill(),
    ),
    'Tagihan baru terbit',
    _billBody,
  ),
  _case(
    'a due date reminder',
    makeNotification(
      type: NotificationType.dueDateReminder,
      rentBill: makeNotificationRentBill(),
    ),
    'Tagihan hampir jatuh tempo',
    _billBody,
  ),
  _case(
    'an overdue bill',
    makeNotification(
      type: NotificationType.billOverdue,
      rentBill: makeNotificationRentBill(daysOverdue: 3),
      tenant: makeNotificationPlace().tenant,
      room: makeNotificationPlace().room,
    ),
    'Tagihan lewat jatuh tempo',
    'Tagihan $_period sebesar Rp800.000 terlambat 3 hari.',
  ),
  _case(
    'a payment paid by transfer',
    makeNotification(
      type: NotificationType.paymentStatusChanged,
      rentBill: makeNotificationRentBill(
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.transfer,
      ),
    ),
    'Pembayaran lunas',
    'Tagihan $_period sebesar Rp800.000 lunas (Transfer).',
  ),
  _case(
    'a payment paid in cash',
    makeNotification(
      type: NotificationType.paymentStatusChanged,
      rentBill: makeNotificationRentBill(
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.cash,
      ),
    ),
    'Pembayaran lunas',
    'Tagihan $_period sebesar Rp800.000 lunas (Tunai).',
  ),
  _case(
    'a rejected payment',
    makeNotification(
      type: NotificationType.paymentStatusChanged,
      rentBill: makeNotificationRentBill(
        paymentStatus: PaymentStatus.rejected,
        reason: 'Foto buram',
      ),
    ),
    'Bukti pembayaran ditolak',
    'Alasan: Foto buram',
  ),
  _case(
    'a payment set back to unpaid with a reason',
    makeNotification(
      type: NotificationType.paymentStatusChanged,
      rentBill: makeNotificationRentBill(reason: 'Dikoreksi pengelola'),
    ),
    'Status pembayaran diubah',
    'Tagihan $_period kini Belum Bayar. Alasan: Dikoreksi pengelola',
  ),
  _case(
    'a payment set back to unpaid without a reason',
    makeNotification(
      type: NotificationType.paymentStatusChanged,
      rentBill: makeNotificationRentBill(),
    ),
    'Status pembayaran diubah',
    'Tagihan $_period kini Belum Bayar.',
  ),
  _case(
    'a payment awaiting verification',
    makeNotification(
      type: NotificationType.paymentStatusChanged,
      rentBill: makeNotificationRentBill(
        paymentStatus: PaymentStatus.awaitingVerification,
      ),
    ),
    'Status pembayaran diubah',
    'Tagihan $_period kini Menunggu Verifikasi.',
  ),
  _case(
    'a complaint in progress with a handling note',
    makeNotification(
      type: NotificationType.complaintStatusChanged,
      complaint: makeNotificationComplaint(
        status: ComplaintStatus.inProgress,
        handlingNote: 'Tukang datang besok',
      ),
    ),
    'Keluhan diproses',
    'Tukang datang besok',
  ),
  _case(
    'a finished complaint without a handling note',
    makeNotification(
      type: NotificationType.complaintStatusChanged,
      complaint: makeNotificationComplaint(
        status: ComplaintStatus.done,
        description: 'Lampu kamar mati',
      ),
    ),
    'Keluhan selesai',
    'Lampu kamar mati',
  ),
  _case(
    'a complaint back to new',
    makeNotification(
      type: NotificationType.complaintStatusChanged,
      complaint: makeNotificationComplaint(description: 'Pintu sulit dikunci'),
    ),
    'Keluhan baru',
    'Pintu sulit dikunci',
  ),
];

/// The titles and bodies the Owner and the Manager read.
List<_Case> _managementCases() {
  final place = makeNotificationPlace();
  return [
    _case(
      'an overdue bill',
      makeNotification(
        type: NotificationType.billOverdue,
        rentBill: makeNotificationRentBill(daysOverdue: 3),
        tenant: place.tenant,
        room: place.room,
        property: place.property,
      ),
      'Budi Santoso terlambat membayar',
      'Kamar 08 · Rp800.000 · terlambat 3 hari.',
    ),
    _case(
      'an unclassified complaint',
      makeNotification(
        type: NotificationType.complaintSubmitted,
        complaint: makeNotificationComplaint(description: 'Keran air bocor'),
        tenant: place.tenant,
        room: place.room,
        property: place.property,
      ),
      'Keluhan baru',
      'Kamar 08 · Keran air bocor',
    ),
    _case(
      'a classified complaint',
      makeNotification(
        type: NotificationType.complaintSubmitted,
        complaint: makeNotificationComplaint(
          description: 'Keran air bocor',
          category: 'Pipa dan air',
          urgency: ComplaintUrgency.high,
        ),
        tenant: place.tenant,
        room: place.room,
        property: place.property,
      ),
      'Keluhan baru',
      'Kamar 08 · Keran air bocor · Pipa dan air · urgensi Tinggi',
    ),
    _case(
      'a classified complaint of medium urgency',
      makeNotification(
        type: NotificationType.complaintSubmitted,
        complaint: makeNotificationComplaint(
          description: 'Lampu berkedip',
          category: 'Listrik',
          urgency: ComplaintUrgency.medium,
        ),
        tenant: place.tenant,
        room: place.room,
        property: place.property,
      ),
      'Keluhan baru',
      'Kamar 08 · Lampu berkedip · Listrik · urgensi Sedang',
    ),
    _case(
      'an uploaded receipt',
      makeNotification(
        type: NotificationType.receiptUploaded,
        rentBill: makeNotificationRentBill(),
        tenant: place.tenant,
        room: place.room,
        property: place.property,
      ),
      'Budi Santoso mengunggah bukti transfer',
      'Kamar 08 · tagihan $_period Rp800.000.',
    ),
    _case(
      'a recorded cash payment',
      makeNotification(
        type: NotificationType.cashPaymentRecorded,
        rentBill: makeNotificationRentBill(
          paymentStatus: PaymentStatus.paid,
          paymentMethod: PaymentMethod.cash,
        ),
        tenant: place.tenant,
        room: place.room,
        property: place.property,
        actorName: 'Siti Pemilik',
      ),
      'Siti Pemilik mencatat pembayaran tunai',
      'Budi Santoso · Kamar 08 · Rp800.000.',
    ),
    _case(
      'an activated tenant',
      makeNotification(
        type: NotificationType.tenantActivated,
        tenant: place.tenant,
        room: place.room,
        property: place.property,
      ),
      'Budi Santoso mengaktifkan akun',
      'Kamar 08 · Kos Melati.',
    ),
    _case(
      'an activated manager',
      makeNotification(
        type: NotificationType.managerActivated,
        property: place.property,
        actorName: 'Rina Putri',
      ),
      'Rina Putri mengaktifkan akun pengelola',
      'Ia kini dapat mengelola Kos Melati.',
    ),
  ];
}

/// A notification of [type] without any optional fact.
Notification _bare(NotificationType type) => makeNotification(type: type);

void main() {
  for (final entry in [
    (role: UserRole.tenant, cases: _tenantCases()),
    (role: UserRole.owner, cases: _managementCases()),
    (role: UserRole.manager, cases: _managementCases()),
  ]) {
    group('copy for ${entry.role}', () {
      for (final c in entry.cases) {
        testWidgets('the list shows the title and body of ${c.name}', (
          tester,
        ) async {
          final repo = FakeNotificationRepository(
            notifications: [c.notification],
          );
          await pumpNotificationApp(tester, repo, role: entry.role);

          expect(find.text(c.title), findsOneWidget);
          expect(find.text(c.body), findsOneWidget);
          expectNoBrokenText(tester);
        });

        testWidgets('the detail shows the title and body of ${c.name}', (
          tester,
        ) async {
          final repo = FakeNotificationRepository(
            notifications: [c.notification],
          );
          await pumpNotificationApp(
            tester,
            repo,
            role: entry.role,
            path: notificationPath(entry.role, 'n1'),
          );

          expect(find.text(c.title), findsWidgets);
          expect(find.text(c.body), findsWidgets);
          expectNoBrokenText(tester);
        });
      }
    });
  }

  group('copy without optional facts', () {
    for (final role in [UserRole.tenant, UserRole.owner]) {
      for (final type in NotificationType.values) {
        testWidgets('the list shows $type for a $role without any fact', (
          tester,
        ) async {
          final repo = FakeNotificationRepository(notifications: [_bare(type)]);
          await pumpNotificationApp(tester, repo, role: role);

          expect(find.byType(Card), findsOneWidget);
          expect(tester.takeException(), isNull);
          expectNoBrokenText(tester);
        });

        testWidgets('the detail shows $type for a $role without any fact', (
          tester,
        ) async {
          final repo = FakeNotificationRepository(notifications: [_bare(type)]);
          await pumpNotificationApp(
            tester,
            repo,
            role: role,
            path: notificationPath(role, 'n1'),
          );

          expect(find.text('Notifikasi tidak ditemukan.'), findsNothing);
          expect(tester.takeException(), isNull);
          expectNoBrokenText(tester);
          expect(find.text('Lihat tagihan'), findsNothing);
          expect(find.text('Lihat keluhan'), findsNothing);
        });
      }
    }

    const staticTitles = {
      NotificationType.billIssued: 'Tagihan baru terbit',
      NotificationType.dueDateReminder: 'Tagihan hampir jatuh tempo',
      NotificationType.billOverdue: 'Tagihan lewat jatuh tempo',
    };
    for (final entry in staticTitles.entries) {
      testWidgets('${entry.key} keeps its title without bill facts', (
        tester,
      ) async {
        final repo = FakeNotificationRepository(
          notifications: [_bare(entry.key)],
        );
        await pumpNotificationApp(tester, repo, role: UserRole.tenant);

        expect(find.text(entry.value), findsOneWidget);
      });
    }

    testWidgets('an overdue bill of management keeps the tenant in the title', (
      tester,
    ) async {
      final place = makeNotificationPlace();
      final repo = FakeNotificationRepository(
        notifications: [
          makeNotification(
            type: NotificationType.billOverdue,
            tenant: place.tenant,
          ),
        ],
      );
      await pumpNotificationApp(tester, repo, role: UserRole.owner);

      expect(find.text('Budi Santoso terlambat membayar'), findsOneWidget);
      expectNoBrokenText(tester);
    });

    testWidgets('an overdue bill of management without a tenant', (
      tester,
    ) async {
      final place = makeNotificationPlace();
      final repo = FakeNotificationRepository(
        notifications: [
          makeNotification(
            type: NotificationType.billOverdue,
            rentBill: makeNotificationRentBill(daysOverdue: 3),
            room: place.room,
          ),
        ],
      );
      await pumpNotificationApp(tester, repo, role: UserRole.manager);

      expect(find.byType(Card), findsOneWidget);
      expectNoBrokenText(tester);
    });

    testWidgets('a paid payment without a method omits the method', (
      tester,
    ) async {
      final repo = FakeNotificationRepository(
        notifications: [
          makeNotification(
            type: NotificationType.paymentStatusChanged,
            rentBill: makeNotificationRentBill(
              paymentStatus: PaymentStatus.paid,
            ),
          ),
        ],
      );
      await pumpNotificationApp(tester, repo, role: UserRole.tenant);

      expect(find.text('Pembayaran lunas'), findsOneWidget);
      expect(find.textContaining('Tagihan $_period'), findsOneWidget);
      expectNoBrokenText(tester);
    });

    testWidgets('a rejected payment without a reason keeps its title', (
      tester,
    ) async {
      final repo = FakeNotificationRepository(
        notifications: [
          makeNotification(
            type: NotificationType.paymentStatusChanged,
            rentBill: makeNotificationRentBill(
              paymentStatus: PaymentStatus.rejected,
            ),
          ),
        ],
      );
      await pumpNotificationApp(tester, repo, role: UserRole.tenant);

      expect(find.text('Bukti pembayaran ditolak'), findsOneWidget);
      expectNoBrokenText(tester);
    });

    testWidgets('a complaint with only a category omits the classification', (
      tester,
    ) async {
      final place = makeNotificationPlace();
      final repo = FakeNotificationRepository(
        notifications: [
          makeNotification(
            type: NotificationType.complaintSubmitted,
            complaint: makeNotificationComplaint(
              description: 'Keran air bocor',
              category: 'Pipa dan air',
            ),
            room: place.room,
          ),
        ],
      );
      await pumpNotificationApp(tester, repo, role: UserRole.owner);

      expect(find.text('Keluhan baru'), findsOneWidget);
      expect(find.textContaining('Keran air bocor'), findsOneWidget);
      expectNoBrokenText(tester);
    });

    testWidgets('a submitted complaint without a room keeps the description', (
      tester,
    ) async {
      final repo = FakeNotificationRepository(
        notifications: [
          makeNotification(
            type: NotificationType.complaintSubmitted,
            complaint: makeNotificationComplaint(
              description: 'Keran air bocor',
            ),
          ),
        ],
      );
      await pumpNotificationApp(tester, repo, role: UserRole.owner);

      expect(find.textContaining('Keran air bocor'), findsOneWidget);
      expectNoBrokenText(tester);
    });

    testWidgets('an uploaded receipt keeps the tenant in the title', (
      tester,
    ) async {
      final place = makeNotificationPlace();
      final repo = FakeNotificationRepository(
        notifications: [
          makeNotification(
            type: NotificationType.receiptUploaded,
            tenant: place.tenant,
          ),
        ],
      );
      await pumpNotificationApp(tester, repo, role: UserRole.owner);

      expect(
        find.text('Budi Santoso mengunggah bukti transfer'),
        findsOneWidget,
      );
      expectNoBrokenText(tester);
    });

    testWidgets('a cash payment keeps the actor in the title', (tester) async {
      final repo = FakeNotificationRepository(
        notifications: [
          makeNotification(
            type: NotificationType.cashPaymentRecorded,
            actorName: 'Siti Pemilik',
          ),
        ],
      );
      await pumpNotificationApp(tester, repo, role: UserRole.manager);

      expect(
        find.text('Siti Pemilik mencatat pembayaran tunai'),
        findsOneWidget,
      );
      expectNoBrokenText(tester);
    });

    testWidgets('a cash payment without an actor omits the name', (
      tester,
    ) async {
      final place = makeNotificationPlace();
      final repo = FakeNotificationRepository(
        notifications: [
          makeNotification(
            type: NotificationType.cashPaymentRecorded,
            rentBill: makeNotificationRentBill(),
            tenant: place.tenant,
            room: place.room,
          ),
        ],
      );
      await pumpNotificationApp(tester, repo, role: UserRole.owner);

      expect(find.textContaining('mencatat pembayaran tunai'), findsOneWidget);
      expectNoBrokenText(tester);
    });

    testWidgets('an activated tenant keeps the name in the title', (
      tester,
    ) async {
      final place = makeNotificationPlace();
      final repo = FakeNotificationRepository(
        notifications: [
          makeNotification(
            type: NotificationType.tenantActivated,
            tenant: place.tenant,
          ),
        ],
      );
      await pumpNotificationApp(tester, repo, role: UserRole.owner);

      expect(find.text('Budi Santoso mengaktifkan akun'), findsOneWidget);
      expectNoBrokenText(tester);
    });

    testWidgets('an activated manager keeps the name in the title', (
      tester,
    ) async {
      final repo = FakeNotificationRepository(
        notifications: [
          makeNotification(
            type: NotificationType.managerActivated,
            actorName: 'Rina Putri',
          ),
        ],
      );
      await pumpNotificationApp(tester, repo, role: UserRole.owner);

      expect(
        find.text('Rina Putri mengaktifkan akun pengelola'),
        findsOneWidget,
      );
      expectNoBrokenText(tester);
    });
  });
}
