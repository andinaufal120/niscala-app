import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/complaints/ui/complaint_form_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala/features/home/ui/tenant_home_screen.dart';
import 'package:niscala/features/rent_bills/ui/tenant_payments_screen.dart';
import 'package:niscala/features/rent_bills/ui/upload_receipt_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/layout.dart';
import '../../auth/ui/auth_ui_helpers.dart';

const _upload = 'Unggah bukti transfer';
const _cashNote = 'Bayar tunai langsung ke pengelola sebelum jatuh tempo.';
const _history = 'Lihat riwayat pembayaran';
const _complaints = 'Keluhan saya';
const _apply = 'Ajukan';
const _retry = 'Coba lagi';
const _noLease = 'Anda belum memiliki masa sewa aktif. Hubungi pengelola kost.';
const _noBills = 'Tidak ada tagihan aktif';
const _noComplaints = 'Belum ada keluhan';
const _loadingLabel = 'Memuat';

final _account = Account(
  email: 'siti@example.com',
  emailVerified: true,
  googleEmail: null,
  hasPassword: true,
  id: 'account-9',
  name: 'Siti Rahayu',
  role: UserRole.tenant,
);

const _failure = ApiFailure(code: 'INTERNAL_ERROR');

FakeAuthRepository _auth() => FakeAuthRepository()..accountResult = _account;

FakeLeaseRepository _lease() => FakeLeaseRepository(lease: makeCurrentLease());

Future<void> _open(
  WidgetTester tester, {
  FakeLeaseRepository? leases,
  FakeRentBillRepository? rentBills,
  FakeComplaintRepository? complaints,
  FakeAuthRepository? auth,
  UserRole role = UserRole.tenant,
  String path = '/penyewa/beranda',
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    leases: leases ?? _lease(),
    rentBills: rentBills ?? FakeRentBillRepository(),
    complaints: complaints ?? FakeComplaintRepository(),
    auth: auth ?? _auth(),
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  // A held request keeps a spinner on the landing page, which never settles.
  Future<void> pumpFrames() async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  if (settle) {
    await tester.pumpAndSettle();
    goTo(tester, path);
    await tester.pumpAndSettle();
  } else {
    await pumpFrames();
    goTo(tester, path);
    await pumpFrames();
  }
}

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

Finder _anyErrorView() => find.byType(ErrorView);

Finder _retryButtons() => find.text(_retry);

void main() {
  setUpAll(loadAppFont);

  group('header', () {
    testWidgets('is a tab root header titled Beranda without an app bar', (
      tester,
    ) async {
      await _open(tester);

      expect(find.byType(TenantHomeScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScreenHeader),
          matching: find.text('Beranda'),
        ),
        findsOneWidget,
      );
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('greets the tenant by name', (tester) async {
      await _open(tester);

      expect(find.text('Halo, Siti Rahayu'), findsOneWidget);
    });

    testWidgets('names the property and the room of the lease', (tester) async {
      await _open(
        tester,
        leases: FakeLeaseRepository(
          lease: makeCurrentLease(propertyName: 'Kos Mawar', roomNumber: '12'),
        ),
      );

      expect(find.text('Kos Mawar · Kamar 12'), findsOneWidget);
    });

    testWidgets('loads the account and the lease once each', (tester) async {
      final leases = _lease();
      final auth = _auth();
      await _open(tester, leases: leases, auth: auth);

      expect(leases.calls, 1);
      expect(auth.accountLoads, greaterThanOrEqualTo(1));
    });

    testWidgets('greets without a name when the account request fails', (
      tester,
    ) async {
      final auth = _auth()..accountFailure = _failure;
      await _open(tester, auth: auth);

      expect(find.textContaining('Halo'), findsOneWidget);
      expect(find.textContaining('Halo,'), findsNothing);
      expect(find.textContaining('Siti'), findsNothing);
      expect(_anyErrorView(), findsNothing);
      expect(_retryButtons(), findsNothing);
      expect(find.text('Kos Melati · Kamar 08'), findsOneWidget);
    });

    testWidgets('shows the other sections while the account is loading', (
      tester,
    ) async {
      final auth = _auth()..accountGate = Completer<void>();
      final rentBills = FakeRentBillRepository(bills: [makeRentBill()]);
      await _open(tester, auth: auth, rentBills: rentBills, settle: false);

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(find.text(_complaints), findsOneWidget);
      expect(_anyErrorView(), findsNothing);
    });
  });

  group('next bill', () {
    testWidgets('shows the amount, the due date and the status', (
      tester,
    ) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(bills: [makeRentBill()]),
      );

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(
        find.text('Jatuh tempo ${formatDate(DateTime.utc(2026, 11, 5))}'),
        findsOneWidget,
      );
      expect(find.text('Belum Bayar'), findsOneWidget);
      expect(find.textContaining('Terlambat'), findsNothing);
    });

    for (final entry in {
      PaymentStatus.unpaid: 'Belum Bayar',
      PaymentStatus.awaitingVerification: 'Menunggu Verifikasi',
      PaymentStatus.rejected: 'Ditolak',
    }.entries) {
      testWidgets('labels a bill that is ${entry.value} in words', (
        tester,
      ) async {
        await _open(
          tester,
          rentBills: FakeRentBillRepository(
            bills: [makeRentBill(status: entry.key)],
          ),
        );

        expect(find.text(entry.value), findsOneWidget);
      });
    }

    testWidgets('shows how many days the bill is overdue', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [makeRentBill(daysOverdue: 3)],
        ),
      );

      expect(find.text('Terlambat 3 hari'), findsOneWidget);
    });

    testWidgets('shows only the first of the active bills', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [
            makeRentBill(id: 'b1', amount: 800000),
            makeRentBill(id: 'b2', amount: 950000),
          ],
        ),
      );

      expect(find.text('Rp800.000'), findsOneWidget);
      expect(find.text('Rp950.000'), findsNothing);
    });

    testWidgets('offers the upload for an uploadable bill with a bank '
        'account', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(bills: [makeRentBill()]),
      );

      expect(buttonLabelled(_upload), findsOneWidget);
      expect(find.text(_cashNote), findsNothing);
    });

    testWidgets('offers the upload for a rejected bill', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [makeRentBill(status: PaymentStatus.rejected)],
        ),
      );

      expect(buttonLabelled(_upload), findsOneWidget);
    });

    testWidgets('offers the upload for an overdue bill of an earlier '
        'period', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [makeRentBill(isCurrent: false, daysOverdue: 12)],
        ),
      );

      expect(find.text('Terlambat 12 hari'), findsOneWidget);
      expect(buttonLabelled(_upload), findsOneWidget);
    });

    testWidgets('opens the upload screen of that bill', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [
            makeRentBill(id: 'b7'),
            makeRentBill(id: 'b8', amount: 950000),
          ],
        ),
      );

      await tester.tap(find.text(_upload));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/penyewa/pembayaran/unggah/b7');
      final screen = tester.widget<UploadReceiptScreen>(
        find.byType(UploadReceiptScreen),
      );
      expect(screen.billId, 'b7');
    });

    testWidgets('shows the cash note and no upload when the property has no '
        'bank account', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [makeRentBill(withoutBankAccount: true)],
        ),
      );

      expect(find.text(_cashNote), findsOneWidget);
      expect(find.text(_upload), findsNothing);
    });

    testWidgets('shows the cash note for a rejected bill without a bank '
        'account', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [
            makeRentBill(
              status: PaymentStatus.rejected,
              withoutBankAccount: true,
            ),
          ],
        ),
      );

      expect(find.text(_cashNote), findsOneWidget);
      expect(find.text(_upload), findsNothing);
    });

    testWidgets('offers no upload without a bank account even when the bill '
        'is marked uploadable', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [
            makeRentBill(withoutBankAccount: true, canUploadReceipt: true),
          ],
        ),
      );

      expect(find.text(_upload), findsNothing);
      expect(find.text(_cashNote), findsOneWidget);
    });

    testWidgets('shows neither the upload nor the cash note for a bill '
        'awaiting verification with a bank account', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [makeRentBill(status: PaymentStatus.awaitingVerification)],
        ),
      );

      expect(find.text('Menunggu Verifikasi'), findsOneWidget);
      expect(find.text(_upload), findsNothing);
      expect(find.text(_cashNote), findsNothing);
    });

    testWidgets('decides the action from the first bill only', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [
            makeRentBill(id: 'b1', status: PaymentStatus.awaitingVerification),
            makeRentBill(id: 'b2', amount: 950000),
          ],
        ),
      );

      expect(find.text(_upload), findsNothing);
      expect(find.text('Rp950.000'), findsNothing);
    });

    testWidgets('explains that there is no active bill', (tester) async {
      await _open(tester);

      expect(find.textContaining(_noBills), findsOneWidget);
      expect(find.text(_upload), findsNothing);
      expect(find.text(_cashNote), findsNothing);
      expect(find.textContaining('Jatuh tempo'), findsNothing);
    });

    testWidgets('links to the payment history, with a bill', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(bills: [makeRentBill()]),
      );

      expect(find.text(_history), findsOneWidget);
    });

    testWidgets('links to the payment history, without a bill', (tester) async {
      await _open(tester);

      expect(find.text(_history), findsOneWidget);
    });

    testWidgets('opens the payments tab from the history link', (tester) async {
      await _open(tester);

      await tester.tap(find.text(_history));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/penyewa/pembayaran');
      expect(find.byType(TenantPaymentsScreen), findsOneWidget);
    });

    testWidgets('shows a progress indicator while the bills load', (
      tester,
    ) async {
      final rentBills = FakeRentBillRepository(bills: [makeRentBill()]);
      rentBills.listScript.gate = Completer<void>();
      final handle = tester.ensureSemantics();
      try {
        await _open(tester, rentBills: rentBills, settle: false);

        expect(find.bySemanticsLabel(_loadingLabel), findsOneWidget);
        expect(find.text('Halo, Siti Rahayu'), findsOneWidget);
        expect(find.text(_complaints), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });

  group('bills request fails', () {
    testWidgets('shows the error with a retry and keeps the other '
        'sections', (tester) async {
      final rentBills = FakeRentBillRepository()..listScript.always = _failure;
      await _open(
        tester,
        rentBills: rentBills,
        complaints: FakeComplaintRepository(complaints: [makeComplaint()]),
      );

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
      expect(_retryButtons(), findsOneWidget);
      expect(find.text('Halo, Siti Rahayu'), findsOneWidget);
      expect(find.text('Kos Melati · Kamar 08'), findsOneWidget);
      expect(find.text(_complaints), findsOneWidget);
      expect(find.text(_apply), findsOneWidget);
      expect(find.text(makeComplaint().description), findsOneWidget);
      expect(find.text(_history), findsOneWidget);
    });

    testWidgets('retries only the bills', (tester) async {
      final leases = _lease();
      final rentBills = FakeRentBillRepository(bills: [makeRentBill()])
        ..listScript.always = _failure;
      final complaints = FakeComplaintRepository();
      await _open(
        tester,
        leases: leases,
        rentBills: rentBills,
        complaints: complaints,
      );
      expect(rentBills.listCalls, 1);
      expect(complaints.listCalls, 1);

      rentBills.listScript.always = null;
      await tester.tap(_retryButtons());
      await tester.pumpAndSettle();

      expect(rentBills.listCalls, 2);
      expect(complaints.listCalls, 1);
      expect(leases.calls, 1);
      expect(find.text('Rp800.000'), findsOneWidget);
      expect(_retryButtons(), findsNothing);
    });
  });

  group('latest complaint', () {
    testWidgets('has a heading announced as a header', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _open(tester);

        expect(
          tester.getSemantics(find.text(_complaints)),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('offers Ajukan with a complaint', (tester) async {
      await _open(
        tester,
        complaints: FakeComplaintRepository(complaints: [makeComplaint()]),
      );

      expect(find.text(_apply), findsOneWidget);
    });

    testWidgets('opens the new complaint form from Ajukan', (tester) async {
      await _open(tester);

      await tester.tap(find.text(_apply));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/penyewa/keluhan/baru');
      expect(find.byType(ComplaintFormScreen), findsOneWidget);
    });

    testWidgets('shows the status and the description', (tester) async {
      await _open(
        tester,
        complaints: FakeComplaintRepository(
          complaints: [makeComplaint(status: ComplaintStatus.inProgress)],
        ),
      );

      expect(find.text('Diproses'), findsOneWidget);
      expect(find.text(makeComplaint().description), findsOneWidget);
    });

    for (final entry in {
      ComplaintStatus.new_: 'Baru',
      ComplaintStatus.inProgress: 'Diproses',
      ComplaintStatus.done: 'Selesai',
    }.entries) {
      testWidgets('labels the status ${entry.value} in words', (tester) async {
        await _open(
          tester,
          complaints: FakeComplaintRepository(
            complaints: [makeComplaint(status: entry.key)],
          ),
        );

        expect(find.text(entry.value), findsOneWidget);
      });
    }

    testWidgets('shows the category of a classified complaint', (tester) async {
      await _open(
        tester,
        complaints: FakeComplaintRepository(
          complaints: [
            makeComplaint(
              classification: makeComplaintClassification(category: 'Listrik'),
            ),
          ],
        ),
      );

      expect(find.text('Listrik'), findsOneWidget);
    });

    testWidgets('shows no category for an unclassified complaint', (
      tester,
    ) async {
      await _open(
        tester,
        complaints: FakeComplaintRepository(
          complaints: [
            makeComplaint(
              classificationState: ComplaintClassificationState.classifying,
            ),
          ],
        ),
      );

      expect(find.text('Pipa dan air'), findsNothing);
      expect(find.text(makeComplaint().description), findsOneWidget);
    });

    testWidgets('shows only the first of the complaints', (tester) async {
      await _open(
        tester,
        complaints: FakeComplaintRepository(
          complaints: [
            makeComplaint(id: 'c1', description: 'Lampu kamar mati total.'),
            makeComplaint(
              id: 'c2',
              description: 'Pintu kamar susah dikunci.',
              status: ComplaintStatus.done,
            ),
          ],
        ),
      );

      expect(find.text('Lampu kamar mati total.'), findsOneWidget);
      expect(find.text('Pintu kamar susah dikunci.'), findsNothing);
      expect(find.text('Selesai'), findsNothing);
    });

    testWidgets('shows the handling note of the latest status change', (
      tester,
    ) async {
      await _open(
        tester,
        complaints: FakeComplaintRepository(
          complaints: [
            makeComplaint(
              status: ComplaintStatus.inProgress,
              statusChanges: [
                statusChangeOf(
                  ComplaintStatus.inProgress,
                  DateTime.utc(2026, 10, 19, 9),
                  note: 'Tukang datang besok pagi.',
                ),
              ],
            ),
          ],
        ),
      );

      expect(find.textContaining('Tukang datang besok pagi.'), findsOneWidget);
    });

    testWidgets('shows the note of the latest change and not an earlier '
        'one', (tester) async {
      await _open(
        tester,
        complaints: FakeComplaintRepository(
          complaints: [
            makeComplaint(
              status: ComplaintStatus.done,
              statusChanges: [
                statusChangeOf(
                  ComplaintStatus.inProgress,
                  DateTime.utc(2026, 10, 19, 9),
                  note: 'Tukang datang besok pagi.',
                ),
                statusChangeOf(
                  ComplaintStatus.done,
                  DateTime.utc(2026, 10, 20, 9),
                  note: 'Keran sudah diganti.',
                ),
              ],
            ),
          ],
        ),
      );

      expect(find.textContaining('Keran sudah diganti.'), findsOneWidget);
      expect(find.textContaining('Tukang datang besok pagi.'), findsNothing);
    });

    testWidgets('shows no note when the latest change has none', (
      tester,
    ) async {
      await _open(
        tester,
        complaints: FakeComplaintRepository(
          complaints: [
            makeComplaint(
              status: ComplaintStatus.done,
              statusChanges: [
                statusChangeOf(
                  ComplaintStatus.inProgress,
                  DateTime.utc(2026, 10, 19, 9),
                  note: 'Tukang datang besok pagi.',
                ),
                statusChangeOf(
                  ComplaintStatus.done,
                  DateTime.utc(2026, 10, 20, 9),
                ),
              ],
            ),
          ],
        ),
      );

      expect(find.textContaining('Tukang datang besok pagi.'), findsNothing);
    });

    testWidgets('loads the detail of the shown complaint for its note', (
      tester,
    ) async {
      final complaints = FakeComplaintRepository(
        complaints: [
          makeComplaint(id: 'c1'),
          makeComplaint(id: 'c2'),
        ],
      );
      await _open(tester, complaints: complaints);

      expect(complaints.calls, contains('get:c1'));
      expect(complaints.calls, isNot(contains('get:c2')));
    });

    testWidgets('opens the detail of the complaint when tapped', (
      tester,
    ) async {
      await _open(
        tester,
        complaints: FakeComplaintRepository(
          complaints: [
            makeComplaint(id: 'c4'),
            makeComplaint(id: 'c5', description: 'Lampu kamar mati total.'),
          ],
        ),
      );

      await tester.tap(find.text(makeComplaint().description));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/penyewa/keluhan/c4');
      final screen = tester.widget<TenantComplaintDetailScreen>(
        find.byType(TenantComplaintDetailScreen),
      );
      expect(screen.complaintId, 'c4');
    });

    testWidgets('explains that there is no complaint and still offers '
        'Ajukan', (tester) async {
      await _open(tester);

      expect(find.textContaining(_noComplaints), findsOneWidget);
      expect(find.text(_complaints), findsOneWidget);
      expect(find.text(_apply), findsOneWidget);
    });

    testWidgets('shows a progress indicator while the complaints load', (
      tester,
    ) async {
      final complaints = FakeComplaintRepository(complaints: [makeComplaint()]);
      complaints.listScript.gate = Completer<void>();
      final handle = tester.ensureSemantics();
      try {
        await _open(
          tester,
          complaints: complaints,
          rentBills: FakeRentBillRepository(bills: [makeRentBill()]),
          settle: false,
        );

        expect(find.bySemanticsLabel(_loadingLabel), findsOneWidget);
        expect(find.text('Rp800.000'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });

  group('complaints request fails', () {
    testWidgets('shows the error with a retry and keeps the other '
        'sections', (tester) async {
      final complaints = FakeComplaintRepository()
        ..listScript.always = _failure;
      await _open(
        tester,
        complaints: complaints,
        rentBills: FakeRentBillRepository(bills: [makeRentBill()]),
      );

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
      expect(_retryButtons(), findsOneWidget);
      expect(find.text('Halo, Siti Rahayu'), findsOneWidget);
      expect(find.text('Rp800.000'), findsOneWidget);
      expect(find.text(_upload), findsOneWidget);
      expect(find.text(_history), findsOneWidget);
    });

    testWidgets('retries only the complaints', (tester) async {
      final leases = _lease();
      final rentBills = FakeRentBillRepository(bills: [makeRentBill()]);
      final complaints = FakeComplaintRepository(complaints: [makeComplaint()])
        ..listScript.always = _failure;
      await _open(
        tester,
        leases: leases,
        rentBills: rentBills,
        complaints: complaints,
      );
      expect(complaints.listCalls, 1);

      complaints.listScript.always = null;
      await tester.tap(_retryButtons());
      await tester.pumpAndSettle();

      expect(complaints.listCalls, 2);
      expect(rentBills.listCalls, 1);
      expect(leases.calls, 1);
      expect(find.text(makeComplaint().description), findsOneWidget);
      expect(_retryButtons(), findsNothing);
    });
  });

  group('without an active lease', () {
    FakeLeaseRepository none() => FakeLeaseRepository();

    testWidgets('tells the tenant to contact management', (tester) async {
      await _open(tester, leases: none());

      expect(find.text(_noLease), findsOneWidget);
      expect(find.text('Halo, Siti Rahayu'), findsOneWidget);
      expect(_anyErrorView(), findsNothing);
    });

    testWidgets('shows no bill, no complaint and no Ajukan', (tester) async {
      await _open(tester, leases: none());

      expect(find.text(_complaints), findsNothing);
      expect(find.text(_apply), findsNothing);
      expect(find.text(_history), findsNothing);
      expect(find.text(_upload), findsNothing);
      expect(find.textContaining(_noBills), findsNothing);
      expect(find.textContaining(_noComplaints), findsNothing);
      expect(find.textContaining('Kamar'), findsNothing);
    });

    testWidgets('does not ask for bills or complaints', (tester) async {
      final rentBills = FakeRentBillRepository(bills: [makeRentBill()]);
      final complaints = FakeComplaintRepository(complaints: [makeComplaint()]);
      await _open(
        tester,
        leases: none(),
        rentBills: rentBills,
        complaints: complaints,
      );

      expect(rentBills.calls, isEmpty);
      expect(complaints.calls, isEmpty);
    });
  });

  group('lease request fails', () {
    FakeLeaseRepository failing() =>
        FakeLeaseRepository(lease: makeCurrentLease())
          ..script.always = _failure;

    testWidgets('shows only the error with a retry', (tester) async {
      await _open(
        tester,
        leases: failing(),
        rentBills: FakeRentBillRepository(bills: [makeRentBill()]),
        complaints: FakeComplaintRepository(complaints: [makeComplaint()]),
      );

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
      expect(_retryButtons(), findsOneWidget);
      expect(find.text(_complaints), findsNothing);
      expect(find.text(_apply), findsNothing);
      expect(find.text(_history), findsNothing);
      expect(find.text(_noLease), findsNothing);
      expect(find.text('Rp800.000'), findsNothing);
    });

    testWidgets('retries the lease and then shows the sections', (
      tester,
    ) async {
      final leases = failing();
      await _open(tester, leases: leases);

      leases.script.always = null;
      await tester.tap(_retryButtons());
      await tester.pumpAndSettle();

      expect(leases.calls, 2);
      expect(_anyErrorView(), findsNothing);
      expect(find.text(_complaints), findsOneWidget);
      expect(find.text('Kos Melati · Kamar 08'), findsOneWidget);
    });
  });

  group('loading', () {
    testWidgets('shows a labelled progress indicator and nothing else', (
      tester,
    ) async {
      final leases = _lease()..script.gate = Completer<void>();
      final handle = tester.ensureSemantics();
      try {
        await _open(tester, leases: leases, settle: false);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.bySemanticsLabel(_loadingLabel), findsOneWidget);
        expect(find.text(_complaints), findsNothing);
        expect(find.text(_apply), findsNothing);
        expect(find.text(_noLease), findsNothing);
        expect(_anyErrorView(), findsNothing);
      } finally {
        handle.dispose();
      }
    });
  });

  group('content left out on purpose', () {
    testWidgets('has no notification bell, no unread badge and no countdown', (
      tester,
    ) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(bills: [makeRentBill()]),
        complaints: FakeComplaintRepository(complaints: [makeComplaint()]),
      );

      expect(find.byIcon(Icons.notifications), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      expect(find.byIcon(Icons.notifications_none), findsNothing);
      expect(find.byIcon(Icons.notifications_none_outlined), findsNothing);
      expect(find.byType(Badge), findsNothing);
      expect(find.textContaining('Notifikasi'), findsNothing);
      expect(
        find.textContaining(
          RegExp(r'hari lagi|tersisa|menuju jatuh tempo|Jatuh tempo dalam'),
        ),
        findsNothing,
      );
    });
  });

  group('layout', () {
    testWidgets('reads from the greeting to the bill to the complaint', (
      tester,
    ) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(bills: [makeRentBill()]),
        complaints: FakeComplaintRepository(complaints: [makeComplaint()]),
      );

      final greeting = _top(tester, find.text('Halo, Siti Rahayu'));
      final amount = _top(tester, find.text('Rp800.000'));
      final upload = _top(tester, find.text(_upload));
      final history = _top(tester, find.text(_history));
      final heading = _top(tester, find.text(_complaints));
      final description = _top(tester, find.text(makeComplaint().description));

      expect(greeting, lessThan(amount));
      expect(amount, lessThan(upload));
      expect(upload, lessThan(heading));
      expect(history, lessThan(heading));
      expect(heading, lessThan(description));
    });

    testWidgets('scrolls at 200 percent text without overflow', (tester) async {
      await _open(
        tester,
        largeText: true,
        rentBills: FakeRentBillRepository(
          bills: [makeRentBill(daysOverdue: 3)],
        ),
        complaints: FakeComplaintRepository(
          complaints: [
            makeComplaint(
              status: ComplaintStatus.inProgress,
              classification: makeComplaintClassification(),
              statusChanges: [
                statusChangeOf(
                  ComplaintStatus.inProgress,
                  DateTime.utc(2026, 10, 19, 9),
                  note: 'Tukang datang besok pagi sekitar jam sembilan.',
                ),
              ],
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);
      await tester.scrollUntilVisible(
        find.text(_complaints),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.textContaining('Tukang datang besok pagi'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrolls the error states at 200 percent text', (tester) async {
      await _open(
        tester,
        largeText: true,
        rentBills: FakeRentBillRepository()..listScript.always = _failure,
        complaints: FakeComplaintRepository()..listScript.always = _failure,
        auth: _auth()..accountFailure = _failure,
      );

      expect(tester.takeException(), isNull);
      expect(_retryButtons(), findsWidgets);
    });

    testWidgets('scrolls the no-lease state at 200 percent text', (
      tester,
    ) async {
      await _open(tester, largeText: true, leases: FakeLeaseRepository());

      expect(tester.takeException(), isNull);
      expect(find.text(_noLease), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('loaded with an uploadable bill and a complaint', (
      tester,
    ) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [makeRentBill(daysOverdue: 3)],
        ),
        complaints: FakeComplaintRepository(
          complaints: [
            makeComplaint(
              classification: makeComplaintClassification(),
              statusChanges: [
                statusChangeOf(
                  ComplaintStatus.new_,
                  DateTime.utc(2026, 10, 19, 9),
                  note: 'Tukang datang besok pagi.',
                ),
              ],
            ),
          ],
        ),
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('loaded with the cash note', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [makeRentBill(withoutBankAccount: true)],
        ),
        complaints: FakeComplaintRepository(complaints: [makeComplaint()]),
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('loaded with a bill awaiting verification', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository(
          bills: [makeRentBill(status: PaymentStatus.awaitingVerification)],
        ),
        complaints: FakeComplaintRepository(
          complaints: [makeComplaint(status: ComplaintStatus.done)],
        ),
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('without an active lease', (tester) async {
      await _open(tester, leases: FakeLeaseRepository());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('with empty sections', (tester) async {
      await _open(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    // The contrast check mis-samples a single-line centered message, so the
    // error states use the network failure, whose message wraps.
    const network = ApiFailure.network();

    testWidgets('with failing bills, complaints and account', (tester) async {
      await _open(
        tester,
        rentBills: FakeRentBillRepository()..listScript.always = network,
        complaints: FakeComplaintRepository()..listScript.always = network,
        auth: _auth()..accountFailure = network,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('with a failing lease request', (tester) async {
      await _open(
        tester,
        leases: FakeLeaseRepository(lease: makeCurrentLease())
          ..script.always = network,
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('while loading', (tester) async {
      final leases = _lease()..script.gate = Completer<void>();
      await _open(tester, leases: leases, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });
  });

  group('router', () {
    testWidgets('builds the home screen at the tenant home path', (
      tester,
    ) async {
      await _open(tester);

      expect(currentPath(tester), '/penyewa/beranda');
      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    testWidgets('opens the home screen for a tenant who signs in', (
      tester,
    ) async {
      useTallScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          store: InMemorySessionStore(storedSession(role: UserRole.tenant)),
          auth: _auth(),
        ),
      );
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/penyewa/beranda');
      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });

    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('keeps the management home for a $role', (tester) async {
        final leases = _lease();
        await _open(tester, role: role, path: '/beranda', leases: leases);

        expect(currentPath(tester), '/beranda');
        expect(find.byType(TenantHomeScreen), findsNothing);
        expect(leases.calls, 0);
      });
    }

    testWidgets('keeps a tenant off the management home', (tester) async {
      await _open(tester, path: '/beranda');

      expect(currentPath(tester), '/penyewa/beranda');
      expect(find.byType(TenantHomeScreen), findsOneWidget);
    });
  });
}

/// A status change at [changedAt] with an optional handling note.
ComplaintStatusChange statusChangeOf(
  ComplaintStatus status,
  DateTime changedAt, {
  String? note,
}) => ComplaintStatusChange(
  status: status,
  changedAt: changedAt,
  handlingNote: note,
);
