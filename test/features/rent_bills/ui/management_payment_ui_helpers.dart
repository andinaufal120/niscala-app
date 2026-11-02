import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'rent_bill_ui_helpers.dart';

export 'rent_bill_ui_helpers.dart';

const overviewPath = '/pembayaran';

String historyPath(String tenantId, String propertyId) =>
    '/pembayaran/penyewa/$tenantId?properti=$propertyId';

String billPath(String billId) => '/pembayaran/tagihan/$billId';

/// Makes the Indonesian date formats available to [formatDate].
Future<void> initializeIndonesianDates() => initializeDateFormatting('id');

/// The full location the app is on, query included.
Uri currentUri(WidgetTester tester) =>
    containerOf(tester)
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri;

/// Two properties of the caller: `p1` Kos Melati and `p2` Kos Mawar.
FakePropertyRepository twoProperties() => FakePropertyRepository(
  properties: [
    makeProperty(id: 'p1', name: 'Kos Melati'),
    makeProperty(id: 'p2', name: 'Kos Mawar'),
  ],
);

/// A single property of the caller: `p1` Kos Melati.
FakePropertyRepository oneProperty() => FakePropertyRepository(
  properties: [makeProperty(id: 'p1', name: 'Kos Melati')],
);

RentBillSummary _summary({
  required String id,
  required String tenantId,
  required String tenantName,
  required String roomNumber,
  required int amount,
  PaymentStatus status = PaymentStatus.unpaid,
  int daysOverdue = 0,
  String propertyId = 'p1',
}) => rentBillSummaryOf(
  makeRentBill(
    id: id,
    propertyId: propertyId,
    tenantId: tenantId,
    tenantName: tenantName,
    roomNumber: roomNumber,
    amount: amount,
    status: status,
    daysOverdue: daysOverdue,
  ),
);

/// Six tenants of Kos Melati in the order the API returns them, with distinct
/// amounts:
/// - t1 Budi Santoso, room 08, Rp800.000 unpaid,
/// - t2 Dewi Lestari, room 12, Rp810.000 awaiting verification,
/// - t3 Rina Putri, room 15, Rp830.000 rejected, 3 days overdue,
/// - t4 Sari Wulandari, room 09, Rp840.000 paid,
/// - t5 Tono, room 10, no bill on the date,
/// - t6 Wati, room 11, Rp850.000 unpaid, 12 days overdue.
List<PaymentOverviewItem> melatiItems() => [
  makeOverviewItem(
    tenantId: 't1',
    tenantName: 'Budi Santoso',
    roomNumber: '08',
    bill: _summary(
      id: 'b1',
      tenantId: 't1',
      tenantName: 'Budi Santoso',
      roomNumber: '08',
      amount: 800000,
    ),
  ),
  makeOverviewItem(
    tenantId: 't2',
    tenantName: 'Dewi Lestari',
    roomNumber: '12',
    bill: _summary(
      id: 'b2',
      tenantId: 't2',
      tenantName: 'Dewi Lestari',
      roomNumber: '12',
      amount: 810000,
      status: PaymentStatus.awaitingVerification,
    ),
  ),
  makeOverviewItem(
    tenantId: 't3',
    tenantName: 'Rina Putri',
    roomNumber: '15',
    bill: _summary(
      id: 'b3',
      tenantId: 't3',
      tenantName: 'Rina Putri',
      roomNumber: '15',
      amount: 830000,
      status: PaymentStatus.rejected,
      daysOverdue: 3,
    ),
  ),
  makeOverviewItem(
    tenantId: 't4',
    tenantName: 'Sari Wulandari',
    roomNumber: '09',
    bill: _summary(
      id: 'b4',
      tenantId: 't4',
      tenantName: 'Sari Wulandari',
      roomNumber: '09',
      amount: 840000,
      status: PaymentStatus.paid,
    ),
  ),
  makeOverviewItem(tenantId: 't5', tenantName: 'Tono', roomNumber: '10'),
  makeOverviewItem(
    tenantId: 't6',
    tenantName: 'Wati',
    roomNumber: '11',
    bill: _summary(
      id: 'b6',
      tenantId: 't6',
      tenantName: 'Wati',
      roomNumber: '11',
      amount: 850000,
      daysOverdue: 12,
    ),
  ),
];

/// Two tenants of Kos Mawar: u1 Agus Salim, room B1, Rp900.000 paid, and u2
/// Lina, room B2, Rp910.000 unpaid.
List<PaymentOverviewItem> mawarItems() => [
  makeOverviewItem(
    tenantId: 'u1',
    tenantName: 'Agus Salim',
    roomNumber: 'B1',
    bill: _summary(
      id: 'c1',
      propertyId: 'p2',
      tenantId: 'u1',
      tenantName: 'Agus Salim',
      roomNumber: 'B1',
      amount: 900000,
      status: PaymentStatus.paid,
    ),
  ),
  makeOverviewItem(
    tenantId: 'u2',
    tenantName: 'Lina',
    roomNumber: 'B2',
    bill: _summary(
      id: 'c2',
      propertyId: 'p2',
      tenantId: 'u2',
      tenantName: 'Lina',
      roomNumber: 'B2',
      amount: 910000,
    ),
  ),
];

/// The payment overview of both properties.
FakeManagementRentBillRepository sampleOverview() =>
    FakeManagementRentBillRepository(
      items: {'p1': melatiItems(), 'p2': mawarItems()},
    );

/// Shows the app signed in as [role] and opens [path] on top of the home
/// route, with [management] behind the payment overview and history, [rentBills]
/// behind the bill detail and [properties] behind the property chooser.
///
/// With [settle] false only a few frames are pumped, so a held `gate` keeps
/// the screen in its loading state. With [largeText] the display is 360 x 640
/// dp at text scale 2.0 and the test fails on any overflow.
Future<void> pumpManagementPayments(
  WidgetTester tester, {
  FakeManagementRentBillRepository? management,
  FakeRentBillRepository? rentBills,
  FakePropertyRepository? properties,
  UserRole role = UserRole.owner,
  String path = overviewPath,
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    managementRentBills: management ?? sampleOverview(),
    rentBills: rentBills,
    properties: properties ?? twoProperties(),
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

/// The card of the tenant row whose name text is [name].
Finder tenantRow(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(Card));

/// [matching] inside the row of the tenant named [name].
Finder inRow(String name, Finder matching) =>
    find.descendant(of: tenantRow(name), matching: matching);

/// The text of today in the app's date format.
String todayText() => formatDate(DateTime.now());

/// The date title of a tab-root header.
Finder pembayaranHeader() => find.descendant(
  of: find.byType(ScreenHeader),
  matching: find.text('Pembayaran'),
);

/// Whether [date] is the calendar day [year]-[month]-[day].
bool isDay(DateTime? date, int year, int month, int day) =>
    date != null && date.year == year && date.month == month && date.day == day;

/// Whether [date] is null (today is meant) or today's calendar day.
bool isTodayOrNull(DateTime? date) {
  if (date == null) return true;
  final now = DateTime.now();
  return isDay(date, now.year, now.month, now.day);
}

/// Opens the date picker from the date control showing [shown], goes to the
/// previous month, picks the 15th and confirms. Returns the day picked.
Future<DateTime> pickDateInPreviousMonth(
  WidgetTester tester,
  String shown,
) async {
  await tester.tap(find.text(shown));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.chevron_left));
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

/// Chooses the property named [target] in the chooser that currently shows
/// [current].
Future<void> chooseProperty(
  WidgetTester tester, {
  required String current,
  required String target,
}) async {
  await tester.tap(find.text(current).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(target).last);
  await tester.pumpAndSettle();
}
