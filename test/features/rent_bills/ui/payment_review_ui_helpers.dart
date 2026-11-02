import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'management_payment_ui_helpers.dart';

export '../../../helpers/fields.dart';
export 'management_payment_ui_helpers.dart';

/// The location of the list of payments awaiting verification of a property.
String verificationPath(String propertyId) =>
    '/pembayaran/verifikasi?properti=$propertyId';

/// The code of the answer to a review of a bill that is no longer awaiting
/// verification.
const conflictCode = 'RENT_BILL_NOT_AWAITING_VERIFICATION';

/// The Indonesian text of that answer.
const conflictMessage = 'Status pembayaran sudah diubah oleh pengguna lain.';

const verifyLabel = 'Verifikasi';
const rejectLabel = 'Tolak';
const reasonLabel = 'Alasan penolakan (wajib)';
const submitRejectionLabel = 'Kirim Penolakan';
const reasonRequiredMessage = 'Alasan penolakan wajib diisi.';
const retryLabel = 'Coba lagi';

/// Bills of two properties, in this order:
/// - b1 Budi Santoso, room 08, Rp800.000 unpaid (Kos Melati),
/// - b2 Dewi Lestari, room 12, Rp810.000 awaiting verification (Kos Melati),
/// - v2 Agus Salim, room 21, Rp820.000 awaiting verification, October (Kos
///   Melati),
/// - b4 Sari Wulandari, room 09, Rp840.000 paid (Kos Melati),
/// - c3 Maya, room B3, Rp930.000 awaiting verification (Kos Mawar).
///
/// b1, b2 and b4 are also the bills of the overview entries of Kos Melati.
List<RentBill> reviewBills() => [
  makeRentBill(
    id: 'b1',
    tenantId: 't1',
    tenantName: 'Budi Santoso',
    roomNumber: '08',
    amount: 800000,
  ),
  makeRentBill(
    id: 'b2',
    tenantId: 't2',
    tenantName: 'Dewi Lestari',
    roomNumber: '12',
    amount: 810000,
    status: PaymentStatus.awaitingVerification,
    hasReceipt: false,
  ),
  makeRentBill(
    id: 'v2',
    tenantId: 't7',
    tenantName: 'Agus Salim',
    roomNumber: '21',
    amount: 820000,
    status: PaymentStatus.awaitingVerification,
    hasReceipt: false,
    periodStart: DateTime.utc(2026, 10, 1),
    periodEnd: DateTime.utc(2026, 10, 31),
    dueDate: DateTime.utc(2026, 10, 5),
    isCurrent: false,
  ),
  makeRentBill(
    id: 'b4',
    tenantId: 't4',
    tenantName: 'Sari Wulandari',
    roomNumber: '09',
    amount: 840000,
    status: PaymentStatus.paid,
    method: PaymentMethod.cash,
    paidOn: DateTime.utc(2026, 11, 3),
  ),
  makeRentBill(
    id: 'c3',
    propertyId: 'p2',
    propertyName: 'Kos Mawar',
    tenantId: 'u3',
    tenantName: 'Maya',
    roomNumber: 'B3',
    amount: 930000,
    status: PaymentStatus.awaitingVerification,
    hasReceipt: false,
  ),
];

/// Both repositories behind the payment screens, holding the same [bills]: a
/// review through [management] is then seen by [rentBills] too, as the one API
/// would show it.
typedef ReviewRepositories = ({
  FakeManagementRentBillRepository management,
  FakeRentBillRepository rentBills,
});

ReviewRepositories reviewRepositories({
  List<RentBill>? bills,
  bool withReceipts = false,
}) {
  final shared = bills ?? reviewBills();
  return (
    management: FakeManagementRentBillRepository(
      items: {'p1': melatiItems(), 'p2': mawarItems()},
      bills: shared,
    ),
    rentBills: FakeRentBillRepository(
      bills: shared,
      receipts: withReceipts
          ? {for (final bill in shared) bill.id: tinyPng}
          : {},
    ),
  );
}

/// Shows the app signed in as [role] at [path] with both [repos] behind it.
Future<void> pumpReview(
  WidgetTester tester,
  ReviewRepositories repos, {
  UserRole role = UserRole.owner,
  String path = overviewPath,
  FakePropertyRepository? properties,
  bool settle = true,
  bool largeText = false,
}) => pumpManagementPayments(
  tester,
  management: repos.management,
  rentBills: repos.rentBills,
  properties: properties,
  role: role,
  path: path,
  settle: settle,
  largeText: largeText,
);

/// The button labelled [label] (a Material button), whatever page is on top.
Finder actionButton(String label) => buttonLabelled(label);

/// The entry of the payment overview that opens the list of payments awaiting
/// verification. A status badge with the same text is not a button.
Finder verificationEntry() => buttonLabelled('Menunggu Verifikasi');

/// [text] inside the confirmation dialog.
Finder inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

/// The multi-line field of the rejection reason.
Finder reasonField() => fieldLabeled(reasonLabel);

/// Taps [finder], scrolling it into view first in the scrollable that holds it
/// (the page, the dialog or the sheet), and lets the UI settle.
Future<void> press(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Asks for the verification and confirms it in the dialog.
Future<void> verifyAndConfirm(WidgetTester tester) async {
  await press(tester, actionButton(verifyLabel));
  await press(tester, inDialog(verifyLabel));
}

/// Opens the rejection prompt, types [reason] and sends it.
Future<void> rejectWith(WidgetTester tester, String reason) async {
  await press(tester, actionButton(rejectLabel));
  await typeInto(tester, reasonLabel, reason);
  await press(tester, actionButton(submitRejectionLabel));
}

/// Whether the screen offers neither the verification nor the rejection.
void expectNoReviewActions() {
  expect(actionButton(verifyLabel), findsNothing);
  expect(actionButton(rejectLabel), findsNothing);
}
