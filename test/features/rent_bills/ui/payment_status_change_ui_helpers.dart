import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/semantics.dart';
import 'cash_payment_ui_helpers.dart';

export 'cash_payment_ui_helpers.dart';

/// The action on the bill detail that opens the sheet, and what the button
/// says.
const changeLabel = 'Ubah Status';

/// The title of the sheet.
const changeTitle = 'Ubah Status Pembayaran';

/// The full labels of the three inputs of the sheet that are not dates.
const newStatusLabel = 'Status baru (wajib)';
const methodGroupLabel = 'Metode pembayaran (wajib)';
const changeReasonLabel = 'Alasan perubahan (wajib)';

const saveChangeLabel = 'Simpan Perubahan';
const cancelLabel = 'Batal';

/// The texts next to the inputs of the sheet.
const changeReasonRequiredMessage = 'Alasan perubahan wajib diisi.';
const statusRequiredMessage = 'Pilih status baru.';
const methodRequiredMessage = 'Pilih metode pembayaran.';
const statusUnchangedMessage =
    'Status baru harus berbeda dari status saat ini.';
const reasonInvalidMessage = 'Alasan perubahan tidak valid.';
const methodInvalidMessage = 'Metode pembayaran tidak valid.';
const statusInvalidMessage = 'Status tidak valid.';

const changeReason = 'Pembayaran dikoreksi setelah pengecekan mutasi.';

/// The bottom sheet on top, whatever it holds.
Finder changeSheet() => find.byType(BottomSheet);

/// [matching] inside the sheet.
Finder inSheet(Finder matching) =>
    find.descendant(of: changeSheet(), matching: matching);

/// The text [text] inside the sheet.
Finder sheetText(String text) => inSheet(find.text(text));

/// The radio choice labelled [label] inside the sheet: one of the statuses
/// Belum Bayar, Lunas, Ditolak, or one of the methods Transfer, Tunai.
Finder choiceLabelled(String label) => find.ancestor(
  of: sheetText(label),
  matching: find.byWidgetPredicate(
    (widget) => widget is RadioListTile,
    description: 'RadioListTile',
  ),
);

/// The choice of the new status labelled [label].
Finder statusChoice(String label) => choiceLabelled(label);

/// The choice of the payment method labelled [label].
Finder methodChoice(String label) => choiceLabelled(label);

/// The three statuses the sheet can offer, as shown.
const offerableStatuses = ['Belum Bayar', 'Lunas', 'Ditolak'];

/// Expects the choice to be a radio of a mutually exclusive group that
/// announces whether it is selected.
void expectChoiceSemantics(
  WidgetTester tester,
  Finder choice, {
  required bool selected,
}) {
  final handle = tester.ensureSemantics();
  try {
    expect(
      tester.getSemantics(choice),
      isSemantics(
        hasCheckedState: true,
        isChecked: selected,
        isInMutuallyExclusiveGroup: true,
      ),
    );
  } finally {
    handle.dispose();
  }
}

/// Expects the choice to be at least 48 dp square.
void expectChoiceTargetSize(WidgetTester tester, Finder choice) {
  final handle = tester.ensureSemantics();
  try {
    final rect = tester.getSemantics(choice).rect;
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(rect.width, greaterThanOrEqualTo(48));
  } finally {
    handle.dispose();
  }
}

/// The reason field of the sheet.
Finder changeReasonField() => fieldLabeled(changeReasonLabel);

/// The text in the reason field of the sheet.
String typedReason(WidgetTester tester) =>
    labeledTextField(tester, changeReasonLabel).controller!.text;

/// Bills for the status change, in this order:
/// - u1 Budi Santoso, room 08, Rp800.000 unpaid (Kos Melati),
/// - w1 Dewi Lestari, room 12, Rp810.000 awaiting verification,
/// - t1 Sari Wulandari, room 09, Rp840.000 paid by transfer on 4 Nov 2026,
/// - c1 Rina Putri, room 15, Rp830.000 paid in cash on 3 Nov 2026,
/// - j1 Wati, room 11, Rp850.000 rejected with a reason.
///
/// Every id is also the id of the bill route.
List<RentBill> changeBills() => [
  makeRentBill(id: 'u1'),
  makeRentBill(
    id: 'w1',
    tenantId: 't2',
    tenantName: 'Dewi Lestari',
    roomNumber: '12',
    amount: 810000,
    status: PaymentStatus.awaitingVerification,
    hasReceipt: false,
  ),
  makeRentBill(
    id: 't1',
    tenantId: 't4',
    tenantName: 'Sari Wulandari',
    roomNumber: '09',
    amount: 840000,
    status: PaymentStatus.paid,
    method: PaymentMethod.transfer,
    paidOn: DateTime.utc(2026, 11, 4),
  ),
  makeRentBill(
    id: 'c1',
    tenantId: 't3',
    tenantName: 'Rina Putri',
    roomNumber: '15',
    amount: 830000,
    status: PaymentStatus.paid,
    method: PaymentMethod.cash,
    paidOn: DateTime.utc(2026, 11, 3),
  ),
  makeRentBill(
    id: 'j1',
    tenantId: 't6',
    tenantName: 'Wati',
    roomNumber: '11',
    amount: 850000,
    status: PaymentStatus.rejected,
    rejectionReason: 'Foto buram.',
    hasReceipt: false,
  ),
];

/// Both repositories behind the payment screens, holding [changeBills] unless
/// other [bills] are given.
ReviewRepositories changeRepositories({List<RentBill>? bills}) =>
    reviewRepositories(bills: bills ?? changeBills());

/// Shows the bill [billId] as [role].
Future<ReviewRepositories> openBill(
  WidgetTester tester,
  String billId, {
  ReviewRepositories? repos,
  UserRole role = UserRole.owner,
  bool largeText = false,
}) async {
  final shown = repos ?? changeRepositories();
  await pumpReview(
    tester,
    shown,
    role: role,
    path: billPath(billId),
    largeText: largeText,
  );
  return shown;
}

/// Shows the bill [billId] and opens the sheet from the action.
Future<ReviewRepositories> openChangeSheet(
  WidgetTester tester,
  String billId, {
  ReviewRepositories? repos,
  UserRole role = UserRole.owner,
  bool largeText = false,
}) async {
  final shown = await openBill(
    tester,
    billId,
    repos: repos,
    role: role,
    largeText: largeText,
  );
  await press(tester, actionButton(changeLabel));
  return shown;
}

/// Chooses a status in the open sheet.
Future<void> chooseStatus(WidgetTester tester, String label) =>
    press(tester, statusChoice(label));

/// Chooses a payment method in the open sheet.
Future<void> chooseMethod(WidgetTester tester, String label) =>
    press(tester, methodChoice(label));

/// Taps the save button of the sheet.
Future<void> saveChange(WidgetTester tester) =>
    press(tester, actionButton(saveChangeLabel));

/// Chooses [status], types [reason] and saves, in the open sheet. Lunas also
/// chooses [method] and leaves the date at today.
Future<void> submitChange(
  WidgetTester tester, {
  required String status,
  String reason = changeReason,
  String? method,
}) async {
  await chooseStatus(tester, status);
  if (method != null) await chooseMethod(tester, method);
  await typeInto(tester, changeReasonLabel, reason);
  await saveChange(tester);
}

/// Whether [text] is announced by some node of the sheet, as a screen reader
/// reaches it.
bool sheetAnnounces(WidgetTester tester, String text) {
  final handle = tester.ensureSemantics();
  try {
    return nodesAnnouncing(tester, text).isNotEmpty;
  } finally {
    handle.dispose();
  }
}
