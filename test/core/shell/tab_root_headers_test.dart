import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala_api/api.dart';

import '../../features/auth/ui/auth_ui_helpers.dart';
import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';
import '../../helpers/layout.dart';

/// Every tab root: its role, its path and the title of its header.
const _roots = <(String, UserRole, String, String)>[
  ('property list', UserRole.owner, '/properti', 'Properti'),
  ('management complaint list', UserRole.owner, '/keluhan', 'Keluhan'),
  (
    'tenant complaint list',
    UserRole.tenant,
    '/penyewa/keluhan',
    'Keluhan Saya',
  ),
  ('management home', UserRole.owner, '/beranda', 'Beranda'),
  ('management payments', UserRole.owner, '/pembayaran', 'Pembayaran'),
  ('management account', UserRole.owner, '/akun', 'Akun'),
  ('manager account', UserRole.manager, '/akun', 'Akun'),
  ('tenant home', UserRole.tenant, '/penyewa/beranda', 'Beranda'),
  ('tenant payments', UserRole.tenant, '/penyewa/pembayaran', 'Pembayaran'),
  ('tenant account', UserRole.tenant, '/penyewa/akun', 'Akun'),
];

typedef _Header = ({
  ScreenHeader widget,
  double height,
  Offset title,
  double subtitleHeight,
});

Future<void> _open(WidgetTester tester, UserRole role, String path) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    buildTestApp(store: InMemorySessionStore(storedSession(role: role))),
  );
  await tester.pumpAndSettle();
  goTo(tester, path);
  await tester.pumpAndSettle();
}

Finder _titleOf(String title) =>
    find.descendant(of: find.byType(ScreenHeader), matching: find.text(title));

void main() {
  setUpAll(loadAppFont);

  for (final (name, role, path, title) in _roots) {
    testWidgets('$name has a ScreenHeader titled $title and no app bar', (
      tester,
    ) async {
      await _open(tester, role, path);

      expect(find.byType(ScreenHeader), findsOneWidget);
      expect(_titleOf(title), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('$name announces its title as a header', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _open(tester, role, path);

        expect(
          tester.getSemantics(_titleOf(title)),
          isSemantics(label: title, isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });
  }

  group('the header does not shift when its action comes or goes', () {
    Future<_Header> measure(
      WidgetTester tester,
      Widget app,
      String path,
      String title, {
      required bool largeText,
    }) async {
      await tester.pumpWidget(const SizedBox());
      if (largeText) {
        await pumpAtLargeText(tester, app);
      } else {
        useTallScreen(tester);
        await tester.pumpWidget(app);
      }
      await tester.pumpAndSettle();
      goTo(tester, path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final header = find.byType(ScreenHeader);
      final widget = tester.widget<ScreenHeader>(header);
      final subtitle = widget.subtitle;
      return (
        widget: widget,
        height: tester.getSize(header).height,
        title: tester.getTopLeft(_titleOf(title)),
        subtitleHeight: subtitle == null
            ? 0.0
            : tester
                  .getSize(
                    find.descendant(of: header, matching: find.text(subtitle)),
                  )
                  .height,
      );
    }

    /// The header height does not depend on the action. The screens' own
    /// subtitles may differ in text and so wrap differently, so the height of
    /// the subtitle itself is left out.
    void expectSame(_Header a, _Header b) {
      expect(
        b.height - b.subtitleHeight,
        closeTo(a.height - a.subtitleHeight, 0.5),
        reason: 'header height without the subtitle',
      );
      expect(b.title.dx, closeTo(a.title.dx, 0.5), reason: 'title left');
      expect(b.title.dy, closeTo(a.title.dy, 0.5), reason: 'title top');
    }

    /// Pressing where the hidden action sits does nothing and the action is
    /// not exposed to assistive technology.
    Future<void> expectInert(WidgetTester tester, String label) async {
      final handle = tester.ensureSemantics();
      try {
        expect(find.bySemanticsLabel(label), findsNothing);
        final path = currentPath(tester);
        await tester.tapAt(tester.getCenter(find.text(label)));
        await tester.pumpAndSettle();
        expect(currentPath(tester), path);
      } finally {
        handle.dispose();
      }
    }

    for (final largeText in [false, true]) {
      final scale = largeText ? '200' : '100';

      testWidgets('property list: owner (Tambah) and manager (hidden Tambah) '
          'at $scale percent text', (tester) async {
        FakePropertyRepository repo() => FakePropertyRepository(
          properties: [
            makeProperty(id: 'p1', name: 'Kos Melati'),
            makeProperty(id: 'p2', name: 'Kos Mawar'),
          ],
        );
        final owner = await measure(
          tester,
          buildTestApp(
            store: InMemorySessionStore(storedSession(role: UserRole.owner)),
            properties: repo(),
          ),
          '/properti',
          'Properti',
          largeText: largeText,
        );
        expect(owner.widget.action, isNotNull);
        expect(owner.widget.actionVisible, isTrue);
        expect(find.text('Tambah'), findsOneWidget);
        final manager = await measure(
          tester,
          buildTestApp(
            store: InMemorySessionStore(storedSession(role: UserRole.manager)),
            properties: repo(),
          ),
          '/properti',
          'Properti',
          largeText: largeText,
        );
        expect(manager.widget.action, isNotNull);
        expect(manager.widget.actionVisible, isFalse);
        await expectInert(tester, 'Tambah');

        expectSame(owner, manager);
      });

      testWidgets('tenant complaint list: empty (hidden Ajukan) and filled '
          '(Ajukan) at $scale percent text', (tester) async {
        final empty = await measure(
          tester,
          buildTestApp(
            store: InMemorySessionStore(storedSession(role: UserRole.tenant)),
            complaints: FakeComplaintRepository(),
          ),
          '/penyewa/keluhan',
          'Keluhan Saya',
          largeText: largeText,
        );
        expect(empty.widget.action, isNotNull);
        expect(empty.widget.actionVisible, isFalse);
        await expectInert(tester, 'Ajukan');
        final filled = await measure(
          tester,
          buildTestApp(
            store: InMemorySessionStore(storedSession(role: UserRole.tenant)),
            complaints: FakeComplaintRepository(complaints: [makeComplaint()]),
          ),
          '/penyewa/keluhan',
          'Keluhan Saya',
          largeText: largeText,
        );
        expect(filled.widget.action, isNotNull);
        expect(filled.widget.actionVisible, isTrue);
        expect(find.text('Ajukan'), findsOneWidget);

        expectSame(empty, filled);
      });
    }
  });

  testWidgets('every tab root header has the same padding and title style', (
    tester,
  ) async {
    final tops = <String, double>{};
    final lefts = <String, double>{};
    final sizes = <String, double>{};
    final weights = <String, FontWeight?>{};
    final colors = <String, Color?>{};
    final plainHeights = <String, double>{};

    for (final (name, role, path, title) in _roots) {
      await tester.pumpWidget(const SizedBox());
      await _open(tester, role, path);

      final header = find.byType(ScreenHeader);
      final text = _titleOf(title);
      final widget = tester.widget<ScreenHeader>(header);
      final style = styleOf(tester, text);
      tops[name] = tester.getTopLeft(text).dy - tester.getTopLeft(header).dy;
      lefts[name] = tester.getTopLeft(text).dx;
      sizes[name] = style.fontSize!;
      weights[name] = style.fontWeight;
      colors[name] = style.color;

      if (widget.action == null) {
        final subtitle = widget.subtitle;
        final subtitleHeight = subtitle == null
            ? 0.0
            : tester
                  .getSize(
                    find.descendant(of: header, matching: find.text(subtitle)),
                  )
                  .height;
        plainHeights[name] = tester.getSize(header).height - subtitleHeight;
      }
    }

    void expectSame<T>(Map<String, T> values, String what) {
      final reference = values.values.first;
      for (final entry in values.entries) {
        if (reference is double) {
          expect(
            entry.value as double,
            closeTo(reference, 0.5),
            reason: '${entry.key} $what ($values)',
          );
        } else {
          expect(entry.value, reference, reason: '${entry.key} $what');
        }
      }
    }

    expectSame(tops, 'title top padding');
    expectSame(lefts, 'title left edge');
    expectSame(sizes, 'title font size');
    expectSame(weights, 'title font weight');
    expectSame(colors, 'title colour');
    expectSame(plainHeights, 'header height without the subtitle line');
    expect(sizes.values.first, 22);
    expect(weights.values.first, FontWeight.w800);
  });
}
