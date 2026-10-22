import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/rent_bills/data/receipt_picker.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../rooms/ui/room_ui_helpers.dart';

export '../../rooms/ui/room_ui_helpers.dart';

const paymentsPath = '/penyewa/pembayaran';

String uploadPath(String id) => '/penyewa/pembayaran/unggah/$id';

String receiptPath(String id) => '/penyewa/pembayaran/bukti/$id';

/// Shows the app signed in as [role] and opens [path] on top of the home
/// route, with [rentBills] and [picker] behind the rent bill screens.
///
/// With [settle] false only a few frames are pumped, so a held `gate` keeps
/// the screen in its loading state. With [largeText] the display is 360 x 640
/// dp at text scale 2.0 and the test fails on any overflow.
Future<void> pumpRentBillApp(
  WidgetTester tester,
  FakeRentBillRepository rentBills, {
  FakeReceiptPicker? picker,
  UserRole role = UserRole.tenant,
  String path = paymentsPath,
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    rentBills: rentBills,
    receiptPicker: picker,
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  await tester.pumpAndSettle();
  goTo(tester, path);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

DateTime day(int month, int dayOfMonth) =>
    DateTime.utc(2026, month, dayOfMonth);

/// Five bills of one tenant, newest period first, with distinct amounts:
/// - b1 Rp800.000 unpaid, current, uploadable (Nov 2026, due 5 Nov 2026),
/// - b2 Rp810.000 awaiting verification (Okt 2026),
/// - b3 Rp820.000 unpaid, 12 days overdue, not uploadable (Sep 2026),
/// - b4 Rp830.000 paid (Agu 2026),
/// - b5 Rp840.000 paid (Jul 2026).
List<RentBill> sampleBills() => [
  makeRentBill(id: 'b1'),
  makeRentBill(
    id: 'b2',
    amount: 810000,
    status: PaymentStatus.awaitingVerification,
    periodStart: day(10, 1),
    periodEnd: day(10, 31),
    dueDate: day(10, 5),
    isCurrent: false,
  ),
  makeRentBill(
    id: 'b3',
    amount: 820000,
    daysOverdue: 12,
    periodStart: day(9, 1),
    periodEnd: day(9, 30),
    dueDate: day(9, 5),
    isCurrent: false,
  ),
  makeRentBill(
    id: 'b4',
    amount: 830000,
    status: PaymentStatus.paid,
    periodStart: day(8, 1),
    periodEnd: day(8, 31),
    dueDate: day(8, 5),
    isCurrent: false,
  ),
  makeRentBill(
    id: 'b5',
    amount: 840000,
    status: PaymentStatus.paid,
    periodStart: day(7, 1),
    periodEnd: day(7, 31),
    dueDate: day(7, 5),
    isCurrent: false,
  ),
];

FakeRentBillRepository sampleRepo() =>
    FakeRentBillRepository(bills: sampleBills());

/// The card of the bill whose amount text is [amount], such as 'Rp800.000'.
Finder billCard(String amount) =>
    find.ancestor(of: find.text(amount), matching: find.byType(Card));

/// [matching] inside the card of the bill with the amount text [amount].
Finder inBill(String amount, Finder matching) =>
    find.descendant(of: billCard(amount), matching: matching);

/// The title of a tab-root header.
Finder headerTitleText() => find.descendant(
  of: find.byType(ScreenHeader),
  matching: find.byWidgetPredicate(
    (w) => w is Text && (w.data ?? '').isNotEmpty,
  ),
);

/// A file with the given leading bytes, padded to [length] bytes.
ReceiptFile _file(String name, List<int> header, int length) {
  final bytes = Uint8List(length < header.length ? header.length : length);
  bytes.setAll(0, header);
  return ReceiptFile(name: name, bytes: bytes);
}

const _jpegHeader = [0xFF, 0xD8, 0xFF, 0xE0];
const _pngHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

ReceiptFile jpegFile({String name = 'bukti.jpg', int length = 2048}) =>
    _file(name, _jpegHeader, length);

ReceiptFile pngFile({String name = 'bukti.png', int length = 2048}) =>
    _file(name, _pngHeader, length);

/// A PDF document, which is not an accepted receipt type.
ReceiptFile pdfFile({String name = 'bukti.pdf'}) =>
    _file(name, '%PDF-1.4'.codeUnits, 2048);

/// A PDF document renamed to look like a JPEG.
ReceiptFile pdfNamedJpg() => pdfFile(name: 'bukti.jpg');

/// A HEIC photo, which many Android cameras save.
ReceiptFile heicFile({String name = 'bukti.heic'}) =>
    _file(name, [0x00, 0x00, 0x00, 0x18, ...'ftypheic'.codeUnits], 2048);

/// A GIF image, which is not an accepted receipt type.
ReceiptFile gifFile({String name = 'bukti.gif'}) =>
    _file(name, 'GIF89a'.codeUnits, 2048);

const maxReceiptBytes = 5 * 1024 * 1024;

/// Records the text that the app puts on the clipboard.
List<String> captureClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}
