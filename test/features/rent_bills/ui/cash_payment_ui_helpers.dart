import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import 'payment_review_ui_helpers.dart';

export 'payment_review_ui_helpers.dart';

/// The entry on the overview and the bill detail, and the title of the flow.
const cashLabel = 'Catat Pembayaran Tunai';

/// The full label of the date field.
const dateLabel = 'Tanggal diterima (wajib)';

/// The label of the confirmation checkbox.
const confirmLabel = 'Saya sudah menerima uang tunai';

/// The submit button.
const saveLabel = 'Simpan Pembayaran';

/// The empty state of the flow, without its final period.
const noPayableMessage = 'Tidak ada tagihan yang menunggu pembayaran';

/// The error shown with the checkbox when it is not ticked.
const confirmRequiredMessage = 'Centang bahwa Anda sudah menerima uang tunai.';

/// The message for a bill whose status changed under the user.
const notPayableMessage =
    'Tagihan ini tidak bisa dibayar tunai karena statusnya sudah berubah.';

/// The message for a date after today.
const futureDateMessage = 'Tanggal diterima tidak boleh lebih dari hari ini.';

/// The message for any other rejection of the date.
const invalidDateMessage = 'Tanggal diterima tidak valid.';

/// The location of the flow for [propertyId], with [billId] preselected.
String cashPath(String propertyId, {String? billId}) =>
    '/pembayaran/tunai?properti=$propertyId'
    '${billId == null ? '' : '&tagihan=$billId'}';

/// Bills of two properties, in this order:
/// - b3 Rina Putri, room 15, Rp830.000 rejected, 3 days overdue (Kos Melati),
/// - b1 Budi Santoso, room 08, Rp800.000 unpaid, November,
/// - b0 Budi Santoso, room 08, Rp790.000 rejected, October,
/// - b6 Wati, room 11, Rp850.000 unpaid, 12 days overdue,
/// - b2 Dewi Lestari, room 12, Rp810.000 awaiting verification,
/// - b4 Sari Wulandari, room 09, Rp840.000 paid in cash,
/// - c2 Lina, room B2, Rp910.000 unpaid (Kos Mawar).
///
/// b1, b2, b3, b4 and b6 are also the bills of the overview entries of Kos
/// Melati, and c2 the one of Kos Mawar. Budi has two payable bills; Rina and
/// Wati have one each; Dewi and Sari have none.
List<RentBill> cashBills() => [
  makeRentBill(
    id: 'b3',
    tenantId: 't3',
    tenantName: 'Rina Putri',
    roomNumber: '15',
    amount: 830000,
    status: PaymentStatus.rejected,
    rejectionReason: 'Foto buram.',
    daysOverdue: 3,
  ),
  makeRentBill(id: 'b1'),
  makeRentBill(
    id: 'b0',
    amount: 790000,
    status: PaymentStatus.rejected,
    rejectionReason: 'Nominal tidak sesuai.',
    daysOverdue: 28,
    periodStart: DateTime.utc(2026, 10, 1),
    periodEnd: DateTime.utc(2026, 10, 31),
    dueDate: DateTime.utc(2026, 10, 5),
    isCurrent: false,
  ),
  makeRentBill(
    id: 'b6',
    tenantId: 't6',
    tenantName: 'Wati',
    roomNumber: '11',
    amount: 850000,
    daysOverdue: 12,
  ),
  makeRentBill(
    id: 'b2',
    tenantId: 't2',
    tenantName: 'Dewi Lestari',
    roomNumber: '12',
    amount: 810000,
    status: PaymentStatus.awaitingVerification,
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
    id: 'c2',
    propertyId: 'p2',
    propertyName: 'Kos Mawar',
    tenantId: 'u2',
    tenantName: 'Lina',
    roomNumber: 'B2',
    amount: 910000,
  ),
];

/// Both repositories behind the payment screens, holding [cashBills] unless
/// other [bills] are given.
ReviewRepositories cashRepositories({List<RentBill>? bills}) =>
    reviewRepositories(bills: bills ?? cashBills());

/// Shows the overview of the first property and opens the cash payment flow
/// from its entry.
Future<ReviewRepositories> openCashFlow(
  WidgetTester tester, {
  ReviewRepositories? repos,
  UserRole role = UserRole.owner,
  FakePropertyRepository? properties,
  bool largeText = false,
}) async {
  final shown = repos ?? cashRepositories();
  await pumpReview(
    tester,
    shown,
    role: role,
    properties: properties,
    largeText: largeText,
  );
  await press(tester, actionButton(cashLabel));
  return shown;
}

/// Shows the bill [billId] and opens the cash payment flow from its action.
Future<ReviewRepositories> openCashFlowFromBill(
  WidgetTester tester,
  String billId, {
  ReviewRepositories? repos,
  UserRole role = UserRole.owner,
  bool largeText = false,
}) async {
  final shown = repos ?? cashRepositories();
  await pumpReview(
    tester,
    shown,
    role: role,
    path: billPath(billId),
    largeText: largeText,
  );
  await press(tester, actionButton(cashLabel));
  return shown;
}

/// The date field of the flow.
Finder dateField() => fieldLabeled(dateLabel);

/// The text shown in the date field.
String shownDate(WidgetTester tester) =>
    labeledTextField(tester, dateLabel).controller!.text;

/// The confirmation checkbox.
Finder confirmCheckbox() => find.ancestor(
  of: find.text(confirmLabel),
  matching: find.byWidgetPredicate(
    (widget) => widget is CheckboxListTile || widget is Checkbox,
  ),
);

/// Whether the checkbox is ticked.
bool isConfirmed(WidgetTester tester) {
  final widget = tester.widget(confirmCheckbox().first);
  if (widget is CheckboxListTile) return widget.value ?? false;
  return (widget as Checkbox).value ?? false;
}

/// The submit button.
Finder saveButton() => actionButton(saveLabel);

/// Chooses the tenant named [tenant] and, when the tenant has several bills and
/// so the form is not shown yet, the bill with the amount text [amount].
Future<void> chooseTenantAndBill(
  WidgetTester tester,
  String tenant,
  String amount,
) async {
  await press(tester, find.text(tenant));
  if (dateField().evaluate().isEmpty) {
    await press(tester, find.text(amount));
  }
}

/// Ticks the confirmation checkbox.
Future<void> confirmReceived(WidgetTester tester) =>
    press(tester, find.text(confirmLabel));

/// Taps the submit button.
Future<void> saveCash(WidgetTester tester) => press(tester, saveButton());

/// Chooses the tenant and bill, ticks the confirmation and saves, with the
/// date left at today.
Future<void> recordCash(
  WidgetTester tester,
  String tenant,
  String amount,
) async {
  await chooseTenantAndBill(tester, tenant, amount);
  await confirmReceived(tester);
  await saveCash(tester);
}

/// Opens the date picker from the date field, goes to the previous month,
/// picks the 15th and confirms. Returns the day picked.
Future<DateTime> pickDateInPreviousMonthOfField(WidgetTester tester) async {
  await press(tester, dateField());
  await tester.tap(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byIcon(Icons.chevron_left),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('15').last);
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .descendant(of: find.byType(Dialog), matching: find.byType(TextButton))
        .last,
  );
  await tester.pumpAndSettle();
  final now = DateTime.now();
  return DateTime(now.year, now.month - 1, 15);
}

/// Today's calendar day.
DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Whether [date] is the calendar day of [expected].
bool sameDay(DateTime? date, DateTime expected) =>
    isDay(date, expected.year, expected.month, expected.day);

/// The text of [date] in the app's date format.
String dateText(DateTime date) => formatDate(date);
