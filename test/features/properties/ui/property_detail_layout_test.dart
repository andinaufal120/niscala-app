import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/features/properties/ui/property_form_screen.dart';
import 'package:niscala/features/rooms/ui/room_list_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/layout.dart';
import '../../rooms/ui/room_ui_helpers.dart';
import 'property_ui_helpers.dart';

Property _melati({bool editable = true, List<ManagerRef>? managers}) =>
    makeProperty(
      id: 'p1',
      name: 'Kos Melati',
      address: 'Jl. Melati 1, Bandung',
      roomCount: 12,
      occupiedRoomCount: 5,
      bankAccount: bankAccount,
      managers: managers ?? [managerSari, managerDewi],
      editable: editable,
    );

Future<void> _open(
  WidgetTester tester, {
  UserRole role = UserRole.owner,
  Property? property,
  bool narrow = false,
  bool largeText = false,
  FakePropertyRepository? repo,
}) async {
  await pumpPropertyApp(
    tester,
    repo ?? FakePropertyRepository(properties: [property ?? _melati()]),
    role: role,
    path: '/properti/p1',
    largeText: largeText,
  );
  if (narrow) await useNarrowScreen(tester);
}

Finder _appBarUbah() => find.descendant(
  of: find.byType(AppBar),
  matching: find.widgetWithText(TextButton, 'Ubah'),
);

Finder _cardOf(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Card)).first;

/// The widest widget around the title of a manage row that does not also hold
/// [other], so that it holds the whole row and nothing else.
Finder _rowOf(String title, String other) {
  Element? row;
  find.text(title).evaluate().single.visitAncestorElements((ancestor) {
    final holdsOther = find
        .descendant(
          of: find.byElementPredicate((e) => e == ancestor),
          matching: find.text(other),
        )
        .evaluate()
        .isNotEmpty;
    if (holdsOther || ancestor.widget is Scrollable) return false;
    row = ancestor;
    return true;
  });
  expect(row, isNotNull);
  return find.byElementPredicate((e) => e == row);
}

void _expectManageRow(
  WidgetTester tester, {
  required String title,
  required String other,
  required String subtitle,
}) {
  final row = _rowOf(title, other);
  final label = find.text(title);

  expect(
    find.ancestor(of: label, matching: find.bySubtype<ButtonStyleButton>()),
    findsNothing,
    reason: '"$title" is a card row, not a button',
  );
  expect(
    find.ancestor(of: label, matching: find.byType(InkWell)),
    findsWidgets,
  );

  final icons = find.descendant(of: row, matching: find.byType(Icon));
  final chevron = find.descendant(
    of: row,
    matching: find.byIcon(Icons.chevron_right),
  );
  expect(chevron, findsOneWidget);
  expect(
    icons,
    findsAtLeastNWidgets(2),
    reason: 'a leading icon and a chevron',
  );
  final leading = icons.first;
  expect(
    tester.widget<Icon>(leading).icon,
    isNot(Icons.chevron_right),
    reason: 'the leading icon comes first',
  );
  expect(
    tester.getRect(leading).right,
    lessThanOrEqualTo(tester.getRect(label).left + 1),
  );
  expect(
    tester.getRect(chevron).left,
    greaterThanOrEqualTo(tester.getRect(label).right - 1),
  );

  expect(
    styleOf(tester, label).fontWeight!.value,
    greaterThanOrEqualTo(FontWeight.w700.value),
  );

  final handle = tester.ensureSemantics();
  try {
    final node = tester.getSemantics(label);
    expect(node.label, startsWith(title));
    expect(node.label, contains(subtitle));
    expect(node.label, isNot(contains(other)));
    expect(
      tester.getSemantics(find.text(subtitle)).id,
      node.id,
      reason: 'the subtitle is read together with the title',
    );
    expect(node, isSemantics(isButton: true));
    expect(node.rect.height, greaterThanOrEqualTo(48));
    expect(node.rect.width, greaterThanOrEqualTo(48));
  } finally {
    handle.dispose();
  }
}

void main() {
  setUpAll(loadAppFont);

  group('app bar', () {
    testWidgets('an owner finds Ubah as a text button in the app bar', (
      tester,
    ) async {
      await _open(tester);

      expect(_appBarUbah(), findsOneWidget);
      expect(find.text('Ubah'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Ubah'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.bySubtype<FilledButton>(),
        ),
        findsNothing,
      );
    });

    testWidgets('Ubah in the app bar is at least 48 dp', (tester) async {
      await _open(tester);

      final rect = tester.getRect(_appBarUbah());
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.width, greaterThanOrEqualTo(48));
      expectTargetSize(tester, 'Ubah');
    });

    testWidgets('Ubah in the app bar opens the edit form of the property', (
      tester,
    ) async {
      await _open(tester);

      await tester.tap(_appBarUbah());
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/ubah');
      expect(find.byType(PropertyFormScreen), findsOneWidget);
    });

    testWidgets('a view-only property shows no Ubah in the app bar', (
      tester,
    ) async {
      await _open(tester, property: _melati(editable: false));

      expect(_appBarUbah(), findsNothing);
      expect(find.text('Ubah'), findsNothing);
    });

    testWidgets('a manager sees no Ubah in the app bar', (tester) async {
      await _open(tester, role: UserRole.manager);

      expect(_appBarUbah(), findsNothing);
      expect(find.text('Ubah'), findsNothing);
    });

    testWidgets('a failure shows no Ubah in the app bar', (tester) async {
      final repo = FakePropertyRepository(properties: [_melati()])
        ..getScript.always = const ApiFailure.network();
      await _open(tester, repo: repo);

      expect(find.text('Ubah'), findsNothing);
    });
  });

  group('cards', () {
    testWidgets('the name and the address share one card', (tester) async {
      await _open(tester, narrow: true);

      final card = _cardOf('Kos Melati');
      expect(card, findsOneWidget, reason: 'the name sits in a card');
      expect(
        find.descendant(of: card, matching: find.text('Jl. Melati 1, Bandung')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Jumlah kamar')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.text('Rekening transfer sewa'),
        ),
        findsNothing,
      );
      expect(
        tester.getTopLeft(find.text('Kos Melati')).dy,
        lessThan(tester.getTopLeft(find.text('Jl. Melati 1, Bandung')).dy),
      );
    });

    testWidgets('the cards follow in reading order', (tester) async {
      await _open(tester);

      final order = [
        'Kos Melati',
        'Jumlah kamar',
        'Rekening transfer sewa',
        'Kelola Kamar',
        'Kelola Penyewa',
        'Hapus Properti',
      ];
      for (var i = 0; i < order.length - 1; i++) {
        expect(
          tester.getTopLeft(find.text(order[i])).dy,
          lessThan(tester.getTopLeft(find.text(order[i + 1])).dy),
          reason: '${order[i]} should come before ${order[i + 1]}',
        );
      }
      expect(
        tester.getTopLeft(find.text('Pengelola Kost')).dy,
        lessThan(tester.getTopLeft(find.text('Rekening transfer sewa')).dy),
      );
    });

    testWidgets('Jumlah kamar and Pengelola Kost sit side by side at 360 dp', (
      tester,
    ) async {
      await _open(tester, narrow: true);

      expectSectionCard(tester, 'Jumlah kamar');
      expectSectionCard(tester, 'Pengelola Kost');
      final rooms = tester.getRect(sectionCardOf('Jumlah kamar'));
      final managers = tester.getRect(sectionCardOf('Pengelola Kost'));
      expect(rooms.top, closeTo(managers.top, 1));
      expect(rooms.right, lessThanOrEqualTo(managers.left));
    });

    testWidgets('Jumlah kamar shows the count big above the occupancy', (
      tester,
    ) async {
      await _open(tester, narrow: true);

      final card = sectionCardOf('Jumlah kamar');
      final count = find.descendant(of: card, matching: find.text('12'));
      final occupancy = find.descendant(
        of: card,
        matching: find.text('5 terisi · 7 kosong'),
      );
      expect(count, findsOneWidget);
      expect(occupancy, findsOneWidget);
      expect(
        styleOf(tester, count).fontSize!,
        greaterThanOrEqualTo(22),
        reason: 'the count is the large value of the card',
      );
      expect(
        styleOf(tester, occupancy).fontSize!,
        lessThan(styleOf(tester, count).fontSize!),
      );
      expect(
        tester.getTopLeft(count).dy,
        lessThan(tester.getTopLeft(occupancy).dy),
      );
    });

    testWidgets('Pengelola Kost shows the manager names', (tester) async {
      await _open(tester, narrow: true);

      final card = sectionCardOf('Pengelola Kost');
      expect(
        find.descendant(of: card, matching: find.textContaining('Sari')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.textContaining('Dewi')),
        findsOneWidget,
      );
    });

    testWidgets('Pengelola Kost keeps the empty text without managers', (
      tester,
    ) async {
      await _open(tester, narrow: true, property: _melati(managers: []));

      expect(
        find.descendant(
          of: sectionCardOf('Pengelola Kost'),
          matching: find.text('Belum ada pengelola'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the two stat cards fit at 200 % text', (tester) async {
      await _open(tester, largeText: true);

      expect(tester.takeException(), isNull);
      for (final title in ['Jumlah kamar', 'Pengelola Kost']) {
        final rect = tester.getRect(sectionCardOf(title));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
      }
      expect(
        tester
            .getRect(sectionCardOf('Jumlah kamar'))
            .overlaps(tester.getRect(sectionCardOf('Pengelola Kost'))),
        isFalse,
      );
    });

    testWidgets('the rent account card keeps its content', (tester) async {
      await _open(tester, narrow: true);

      final card = sectionCardOf('Rekening transfer sewa');
      expect(
        find.descendant(of: card, matching: find.text('BCA · 1234567890')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('a.n. Budi Santoso')),
        findsOneWidget,
      );
    });
  });

  group('manage rows', () {
    testWidgets('Kelola Kamar is a primary filled card row', (tester) async {
      await _open(tester, narrow: true);

      _expectManageRow(
        tester,
        title: 'Kelola Kamar',
        other: 'Kelola Penyewa',
        subtitle: 'Tambah, ubah, atau hapus kamar',
      );
      expect(
        hasFillAround(find.text('Kelola Kamar'), NiscalaColors.primary),
        isTrue,
      );
    });

    testWidgets('Kelola Penyewa is a white outlined card row', (tester) async {
      await _open(tester, narrow: true);

      _expectManageRow(
        tester,
        title: 'Kelola Penyewa',
        other: 'Kelola Kamar',
        subtitle: 'Daftarkan penyewa, atur masa sewa dan tagihan',
      );
      expect(
        hasFillAround(find.text('Kelola Penyewa'), NiscalaColors.surface),
        isTrue,
      );
      expect(hasBorderAround(find.text('Kelola Penyewa')), isTrue);
      expect(
        hasFillAround(find.text('Kelola Penyewa'), NiscalaColors.primary),
        isFalse,
      );
    });

    testWidgets('Kelola Kamar title is white on the primary fill', (
      tester,
    ) async {
      await _open(tester, narrow: true);

      expect(
        styleOf(tester, find.text('Kelola Kamar')).color,
        NiscalaColors.surface,
      );
    });

    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('Kelola Kamar opens the room list for a $role', (
        tester,
      ) async {
        await _open(tester, role: role);

        await tapVisible(tester, find.text('Kelola Kamar'));

        expect(currentPath(tester), '/properti/p1/kamar');
        expect(find.byType(RoomListScreen), findsOneWidget);
      });

      testWidgets('tapping the helper text opens the room list for a $role', (
        tester,
      ) async {
        await _open(tester, role: role);

        await tapVisible(tester, find.text('Tambah, ubah, atau hapus kamar'));

        expect(currentPath(tester), '/properti/p1/kamar');
      });

      testWidgets('Kelola Penyewa opens the tenant list for a $role', (
        tester,
      ) async {
        await _open(tester, role: role);

        await tapVisible(tester, find.text('Kelola Penyewa'));

        expect(currentPath(tester), '/properti/p1/penyewa');
        expect(find.byType(TenantListScreen), findsOneWidget);
      });
    }

    testWidgets('both rows fit at 200 % text', (tester) async {
      await _open(tester, largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.text('Tambah, ubah, atau hapus kamar'), findsOneWidget);
      expect(
        find.text('Daftarkan penyewa, atur masa sewa dan tagihan'),
        findsOneWidget,
      );
    });
  });

  group('delete action', () {
    testWidgets('Hapus Properti is a full width danger outlined button', (
      tester,
    ) async {
      await _open(tester, narrow: true);

      expectDangerOutlinedButton(
        tester,
        'Hapus Properti',
        reference: _cardOf('Kos Melati'),
      );
    });

    testWidgets('Hapus Properti still asks for confirmation', (tester) async {
      await _open(tester);

      await tapVisible(tester, find.text('Hapus Properti'));

      expect(find.text('Hapus Kos Melati?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('Hapus Properti stays for an owner of a view-only property', (
      tester,
    ) async {
      await _open(tester, property: _melati(editable: false), narrow: true);

      expect(outlinedButtonLabelled('Hapus Properti'), findsOneWidget);
    });

    testWidgets('a manager sees no Hapus Properti', (tester) async {
      await _open(tester, role: UserRole.manager);

      expect(find.text('Hapus Properti'), findsNothing);
    });
  });
}
