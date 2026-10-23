import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import '../../rooms/ui/room_ui_helpers.dart';

export '../../rooms/ui/room_ui_helpers.dart';

/// Records the texts handed to the invitation sharer.
class ShareRecorder {
  final texts = <String>[];

  Future<void> call(String text) async => texts.add(text);
}

/// Replaces the platform clipboard for one test and records what is copied.
class ClipboardRecorder {
  ClipboardRecorder(WidgetTester tester) {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
  }

  final copied = <String>[];
}

/// Room 08 is occupied (tenant t1), 09 and 10 are vacant and editable, 11 is
/// vacant but view-only.
List<Room> tenantRooms() => [
  occupiedRoom(id: 'r1', number: '08'),
  vacantRoom(id: 'r2', number: '09', baseRate: 650000),
  vacantRoom(id: 'r3', number: '10', baseRate: 900000),
  vacantRoom(id: 'r4', number: '11', baseRate: 500000, editable: false),
];

/// Three tenants: Budi (active, monthly, room 08), Sari (not activated,
/// quarterly, room 12) and Dewi (active, weekly, no end date, room 13).
List<Tenant> sampleTenants() => [
  makeTenant(
    id: 't1',
    name: 'Budi Santoso',
    accountStatus: TenantAccountStatus.active,
  ),
  makeTenant(
    id: 't2',
    name: 'Sari Wulandari',
    roomId: 'r5',
    roomNumber: '12',
    billingCycle: BillingCycle.quarterly,
  ),
  makeTenant(
    id: 't3',
    name: 'Dewi Lestari',
    roomId: 'r6',
    roomNumber: '13',
    accountStatus: TenantAccountStatus.active,
    billingCycle: BillingCycle.weekly,
    noEndDate: true,
  ),
];

/// Shows the app signed in as [role] and opens [path] on top of the home
/// route, with [tenants] behind the tenant screens, [rooms] behind the rooms
/// they link to and [properties] behind the property name shown in headers.
///
/// With [settle] false only a few frames are pumped, so a held `gate` keeps
/// the screen in its loading state. With [largeText] the display is 360 x 640
/// dp at text scale 2.0 and the test fails on any overflow. Sharing goes to
/// [sharer].
Future<void> pumpTenantApp(
  WidgetTester tester,
  FakeTenantRepository tenants, {
  FakeRoomRepository? rooms,
  FakePropertyRepository? properties,
  UserRole role = UserRole.owner,
  String path = '/properti/p1/penyewa',
  bool settle = true,
  bool largeText = false,
  ShareRecorder? sharer,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    properties: properties ?? propertiesWithMelati(),
    rooms: rooms ?? FakeRoomRepository(rooms: tenantRooms()),
    tenants: tenants,
    invitationSharer: sharer?.call,
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

/// The [LabeledField] editable field labelled [label], for labels that repeat
/// once per emergency contact block.
Finder labeledFieldAt(String label, int index) => fieldLabeled(label).at(index);

/// The text of the [index]th [LabeledField] labelled [label].
String labeledTextAt(WidgetTester tester, String label, [int index = 0]) =>
    tester.widget<TextField>(labeledFieldAt(label, index)).controller!.text;

/// Types [text] into the [index]th [LabeledField] labelled [label].
Future<void> typeLabeledAt(
  WidgetTester tester,
  String label,
  int index,
  String text,
) async {
  await tester.enterText(labeledFieldAt(label, index), text);
  await tester.pump();
}

/// The `errorText` shown by the [index]th [LabeledField] labelled [label].
String? labeledInputError(WidgetTester tester, String label, [int index = 0]) =>
    tester
        .widget<InputDecorator>(
          find.descendant(
            of: labeledField(label).at(index),
            matching: find.byType(InputDecorator),
          ),
        )
        .decoration
        .errorText;

/// Opens the dropdown labelled [label] and taps the entry [option].
Future<void> choose(WidgetTester tester, String label, String option) async {
  await openDropdown(tester, label);
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

/// Opens the dropdown labelled [label] and leaves its entries showing.
Future<void> openDropdown(WidgetTester tester, String label) async {
  await tapVisible(tester, fieldLabeled(label));
}

/// Opens the date field labelled [label], taps [day] of the month shown and
/// confirms.
Future<void> pickDate(WidgetTester tester, String label, int day) async {
  await tapVisible(tester, fieldLabeled(label));
  await tester.tap(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text('$day'),
    ),
  );
  await tester.pumpAndSettle();
  final ok = MaterialLocalizations.of(
    tester.element(find.byType(DatePickerDialog)),
  ).okButtonLabel;
  await tester.tap(find.text(ok));
  await tester.pumpAndSettle();
}

/// Opens the date field labelled [label] and dismisses the picker with its
/// cancel button.
Future<void> openAndCancelDatePicker(WidgetTester tester, String label) async {
  await tapVisible(tester, fieldLabeled(label));
  final cancel = MaterialLocalizations.of(
    tester.element(find.byType(DatePickerDialog)),
  ).cancelButtonLabel;
  await tester.tap(find.text(cancel));
  await tester.pumpAndSettle();
}

/// Whether the button holding [label] is disabled.
bool isDisabled(WidgetTester tester, String label) =>
    tester.widget<ButtonStyleButton>(buttonLabelled(label)).onPressed == null;

/// Expects the semantics node of the widget found by [finder] to be at least
/// 48 dp square.
void expectFinderTargetSize(WidgetTester tester, Finder finder) {
  final handle = tester.ensureSemantics();
  try {
    final rect = tester.getSemantics(finder).rect;
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(rect.width, greaterThanOrEqualTo(48));
  } finally {
    handle.dispose();
  }
}
