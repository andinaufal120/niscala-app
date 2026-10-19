import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/layout.dart';
import 'property_ui_helpers.dart';

List<Property> _two({bool secondEditable = true}) => [
  makeProperty(
    id: 'p1',
    name: 'Kos Melati',
    address: 'Jl. Melati 1, Bandung',
    roomCount: 10,
    occupiedRoomCount: 4,
    managers: [managerSari, managerDewi],
  ),
  makeProperty(
    id: 'p2',
    name: 'Kos Mawar',
    address: 'Jl. Mawar 2, Jakarta',
    roomCount: 6,
    occupiedRoomCount: 6,
    editable: secondEditable,
  ),
];

Future<void> _open(
  WidgetTester tester, {
  bool secondEditable = true,
  bool largeText = false,
}) async {
  await pumpPropertyApp(
    tester,
    FakePropertyRepository(properties: _two(secondEditable: secondEditable)),
    largeText: largeText,
  );
}

Finder _card(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(Card)).first;

Finder _chevronOf(String name) => find.descendant(
  of: _card(name),
  matching: find.byIcon(Icons.chevron_right),
);

Finder _wrapOf(Finder fact) =>
    find.ancestor(of: fact, matching: find.byType(Wrap));

void _expectPill(WidgetTester tester, String text) {
  final fact = find.text(text);
  expect(
    hasRoundedFillAround(fact, NiscalaColors.neutralSoft, 10),
    isTrue,
    reason: '"$text" must sit in a neutral pill with a 10 dp radius',
  );
  final style = styleOf(tester, fact);
  expect(style.fontSize, 12);
  expect(style.fontWeight, FontWeight.w600);
}

void main() {
  setUpAll(loadAppFont);

  group('chevron', () {
    testWidgets('every card ends with a chevron', (tester) async {
      await _open(tester);

      for (final name in ['Kos Melati', 'Kos Mawar']) {
        final chevron = _chevronOf(name);
        expect(chevron, findsOneWidget);
        final card = tester.getRect(_card(name));
        final rect = tester.getRect(chevron);
        expect(rect.center.dx, greaterThan(card.center.dx));
        expect(rect.right, lessThanOrEqualTo(card.right));
        expect(rect.center.dy, greaterThan(card.top));
        expect(rect.center.dy, lessThan(card.bottom));
      }
    });

    testWidgets('the chevron is decorative and read with the card', (
      tester,
    ) async {
      await _open(tester);

      expect(
        tester.widget<Icon>(_chevronOf('Kos Melati')).semanticLabel,
        isNull,
      );
      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(_chevronOf('Kos Melati')).id,
          tester.getSemantics(find.text('Kos Melati')).id,
        );
      } finally {
        handle.dispose();
      }
    });
  });

  group('facts', () {
    testWidgets('show the room counts and the managers as small pills', (
      tester,
    ) async {
      await _open(tester);

      _expectPill(tester, '10 kamar · 4 terisi');
      _expectPill(tester, 'Pengelola: Sari, Dewi');
      _expectPill(tester, '6 kamar · 6 terisi');
    });

    testWidgets('show a pill when no manager is assigned', (tester) async {
      await _open(tester);

      _expectPill(tester, 'Belum ada pengelola');
    });

    testWidgets('sit together in a Wrap under the address', (tester) async {
      await _open(tester);

      final counts = _wrapOf(find.text('10 kamar · 4 terisi'));
      final managers = _wrapOf(find.text('Pengelola: Sari, Dewi'));
      expect(counts, findsOneWidget);
      expect(managers.evaluate().single, counts.evaluate().single);
      expect(
        find.descendant(of: _card('Kos Melati'), matching: counts),
        findsOneWidget,
      );
      expect(
        tester.getRect(counts).top,
        greaterThanOrEqualTo(
          tester.getRect(find.text('Jl. Melati 1, Bandung')).bottom - 1,
        ),
      );
    });

    testWidgets('the view-only badge joins the facts in the same Wrap', (
      tester,
    ) async {
      await _open(tester, secondEditable: false);

      final wrap = _wrapOf(find.text('6 kamar · 6 terisi'));
      expect(wrap, findsOneWidget);
      expect(
        find.descendant(of: wrap, matching: find.text('Belum ada pengelola')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: wrap, matching: find.text('Hanya lihat')),
        findsOneWidget,
      );
    });

    testWidgets('an editable property has no Hanya lihat fact', (tester) async {
      await _open(tester);

      expect(find.text('Hanya lihat'), findsNothing);
    });
  });

  group('semantics and tap', () {
    testWidgets('the card reads name, address and facts as one item', (
      tester,
    ) async {
      await _open(tester, secondEditable: false);

      final handle = tester.ensureSemantics();
      try {
        final node = tester.getSemantics(find.text('Kos Mawar'));
        for (final text in [
          'Jl. Mawar 2, Jakarta',
          '6 kamar · 6 terisi',
          'Belum ada pengelola',
          'Hanya lihat',
        ]) {
          expect(
            tester.getSemantics(find.text(text)).id,
            node.id,
            reason: '"$text" must be read with the card',
          );
        }
        final order = [
          'Kos Mawar',
          'Jl. Mawar 2, Jakarta',
          '6 kamar · 6 terisi',
          'Belum ada pengelola',
        ].map(node.label.indexOf).toList();
        expect(order, everyElement(greaterThanOrEqualTo(0)));
        expect(order, orderedEquals([...order]..sort()));
        expect(node.label, isNot(contains('Kos Melati')));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('tapping a fact opens the detail of the property', (
      tester,
    ) async {
      await _open(tester);

      await tester.tap(find.text('Pengelola: Sari, Dewi'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1');
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
    });

    testWidgets('tapping the chevron opens the detail of the property', (
      tester,
    ) async {
      await _open(tester);

      await tester.tap(_chevronOf('Kos Mawar'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p2');
    });

    testWidgets('the card is a target of at least 48 dp', (tester) async {
      await _open(tester);

      expectTargetSize(tester, 'Kos Melati');
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines with the facts as pills', (tester) async {
      await _open(tester, secondEditable: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('lets the facts wrap at 200 % text', (tester) async {
      await _open(tester, secondEditable: false, largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.text('Pengelola: Sari, Dewi'), findsOneWidget);
    });
  });
}
