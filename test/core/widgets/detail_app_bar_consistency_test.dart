import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala_api/api.dart';

import '../../features/complaints/ui/complaint_ui_helpers.dart';
import '../../features/tenants/ui/tenant_ui_helpers.dart';
import '../../helpers/fakes.dart';
import '../../helpers/layout.dart';

Future<void> _pumpActivation(WidgetTester tester) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    buildTestApp(invitations: FakeInvitationRepository()),
  );
  await tester.pumpAndSettle();
  goTo(tester, '/aktivasi');
  await tester.pumpAndSettle();
}

FakePropertyRepository _properties() => FakePropertyRepository(
  properties: [makeProperty(id: 'p1', name: 'Kos Melati')],
);

FakeRoomRepository _rooms() => FakeRoomRepository(rooms: [makeRoom()]);

FakeTenantRepository _tenants() =>
    FakeTenantRepository(tenants: sampleTenants());

FakeComplaintRepository _complaints() =>
    FakeComplaintRepository(complaints: [makeComplaint()]);

Future<void> _property(WidgetTester tester, String path) =>
    pumpPropertyApp(tester, _properties(), path: path);

Future<void> _room(WidgetTester tester, String path) =>
    pumpRoomApp(tester, _rooms(), path: path);

Future<void> _tenant(WidgetTester tester, String path) =>
    pumpTenantApp(tester, _tenants(), path: path);

/// Screens whose bar has a back button.
final _withBack = <String, Future<void> Function(WidgetTester)>{
  'property detail': (t) => _property(t, '/properti/p1'),
  'property form': (t) => _property(t, '/properti/tambah'),
  'property edit form': (t) => _property(t, '/properti/p1/ubah'),
  'room list': (t) => _room(t, '/properti/p1/kamar'),
  'room detail': (t) => _room(t, '/properti/p1/kamar/r1'),
  'room form': (t) => _room(t, '/properti/p1/kamar/tambah'),
  'tenant list': (t) => _tenant(t, '/properti/p1/penyewa'),
  'tenant detail': (t) => _tenant(t, '/properti/p1/penyewa/t1'),
  'tenant form': (t) => _tenant(t, '/properti/p1/penyewa/tambah'),
  'invitation share': (t) => _tenant(t, '/properti/p1/penyewa/t2/undangan'),
  'invitation qr': (t) => _tenant(t, '/properti/p1/penyewa/t2/undangan/qr'),
  'complaint form': (t) =>
      pumpComplaintApp(t, _complaints(), path: '/penyewa/keluhan/baru'),
  'tenant complaint detail': (t) =>
      pumpComplaintApp(t, _complaints(), path: '/penyewa/keluhan/c1'),
  'management complaint detail': (t) => pumpComplaintApp(
    t,
    _complaints(),
    role: UserRole.owner,
    path: '/keluhan/c1',
  ),
  'register': (t) => pumpRegister(t, FakeAuthRepository()),
  'activation': _pumpActivation,
};

/// Screens whose bar has no back button: they are not on top of another page.
final _withoutBack = <String, Future<void> Function(WidgetTester)>{
  'verify email': (t) => pumpVerify(t, FakeAuthRepository()),
  'manager single property': (t) => pumpPropertyApp(
    t,
    FakePropertyRepository(
      properties: [makeProperty(id: 'p1', name: 'Kos Melati')],
    ),
    role: UserRole.manager,
    path: '/properti',
  ),
};

final _screens = <String, Future<void> Function(WidgetTester)>{
  ..._withBack,
  ..._withoutBack,
};

/// The height of the title and subtitle texts of the bar laid out one under the
/// other, and the vertical centre of that block.
({double height, double centre}) _block(WidgetTester tester, Finder bar) {
  final widget = tester.widget<DetailAppBar>(bar);
  final first = tester.getRect(
    find.descendant(of: bar, matching: find.text(widget.title)),
  );
  final last = widget.subtitle == null
      ? first
      : tester.getRect(
          find.descendant(of: bar, matching: find.text(widget.subtitle!)),
        );
  return (
    height: last.bottom - first.top,
    centre: (first.top + last.bottom) / 2,
  );
}

void main() {
  setUpAll(loadAppFont);

  testWidgets('every detail bar fits its wrapped title and subtitle without a '
      'band at 200 percent text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final entry in _screens.entries) {
      await tester.pumpWidget(const SizedBox());
      await entry.value(tester);

      final bar = find.byType(DetailAppBar);
      expect(bar, findsOneWidget, reason: '${entry.key} has a DetailAppBar');
      expect(tester.takeException(), isNull, reason: '${entry.key} overflow');
      final block = _block(tester, bar);
      final barRect = tester.getRect(bar);
      expect(
        barRect.height,
        greaterThanOrEqualTo(56),
        reason: '${entry.key} bar is at least 56 dp',
      );
      expect(
        barRect.height,
        lessThanOrEqualTo(block.height + 24),
        reason: '${entry.key} bar is not taller than its text plus padding',
      );
      expect(
        barRect.height,
        greaterThanOrEqualTo(block.height + 16 - 0.5),
        reason: '${entry.key} bar fits its text plus padding',
      );
      expect(
        block.centre,
        closeTo(barRect.center.dy, 1),
        reason: '${entry.key} title block is centred',
      );
      expect(
        barRect.top,
        lessThanOrEqualTo(block.centre - block.height / 2 + 0.5),
        reason: '${entry.key} text is not clipped at the top',
      );
      expect(
        barRect.bottom,
        greaterThanOrEqualTo(block.centre + block.height / 2 - 0.5),
        reason: '${entry.key} text is not clipped at the bottom',
      );

      final widget = tester.widget<DetailAppBar>(bar);
      for (final text in [widget.title, ?widget.subtitle]) {
        final finder = find.descendant(of: bar, matching: find.text(text));
        expect(finder, findsOneWidget, reason: '${entry.key} "$text"');
        final label = tester.widget<Text>(finder);
        expect(
          label.overflow,
          isNot(TextOverflow.ellipsis),
          reason: '${entry.key} "$text" overflow',
        );
        expect(label.maxLines, isNull, reason: '${entry.key} "$text" lines');
        expect(
          tester.renderObject<RenderParagraph>(finder).didExceedMaxLines,
          isFalse,
          reason: '${entry.key} "$text" is cut',
        );
      }
    }
  });

  testWidgets('every screen with an app bar uses the shared detail bar', (
    tester,
  ) async {
    final heights = <String, double>{};
    final lefts = <String, double>{};

    for (final entry in _screens.entries) {
      await tester.pumpWidget(const SizedBox());
      await entry.value(tester);

      final bar = find.byType(DetailAppBar);
      expect(bar, findsOneWidget, reason: '${entry.key} has a DetailAppBar');
      expect(
        find.byType(AppBar),
        findsOneWidget,
        reason: '${entry.key} builds no app bar of its own',
      );
      expect(
        find.descendant(of: bar, matching: find.byType(AppBar)),
        findsOneWidget,
        reason: '${entry.key}: the only app bar is the one in DetailAppBar',
      );

      final title = tester.widget<DetailAppBar>(bar).title;
      final titleText = find.descendant(of: bar, matching: find.text(title));
      expect(titleText, findsOneWidget, reason: '${entry.key} title');

      final block = _block(tester, bar);
      heights[entry.key] = tester.getSize(bar).height;
      expect(
        heights[entry.key],
        closeTo(math.max(56, block.height + 16), 0.5),
        reason: '${entry.key} bar height',
      );
      lefts[entry.key] = tester.getTopLeft(titleText).dx;
    }

    final withBack = {for (final name in _withBack.keys) name: lefts[name]!};
    final reference = withBack.values.first;
    for (final entry in withBack.entries) {
      expect(
        entry.value,
        closeTo(reference, 0.5),
        reason: '${entry.key} title left edge with a back button ($withBack)',
      );
      expect(
        entry.value,
        greaterThan(NiscalaSpacing.gutter + 24),
        reason: '${entry.key} leaves room for its back button',
      );
    }

    for (final name in _withoutBack.keys) {
      expect(
        lefts[name],
        closeTo(NiscalaSpacing.gutter, 0.5),
        reason: '$name has no back button, so its title starts at the gutter',
      );
    }
  });

  testWidgets('a bar with a back button shows one and a bar without shows '
      'none', (tester) async {
    for (final entry in _screens.entries) {
      await tester.pumpWidget(const SizedBox());
      await entry.value(tester);
      final bar = find.byType(DetailAppBar);
      final backs = find.descendant(
        of: bar,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is BackButton ||
              (widget is Icon && widget.icon == Icons.arrow_back),
        ),
      );

      if (_withBack.containsKey(entry.key)) {
        expect(backs, findsAtLeastNWidgets(1), reason: entry.key);
      } else {
        expect(backs, findsNothing, reason: entry.key);
      }
    }
  });

  testWidgets('a title without a back button starts where a tab header title '
      'starts', (tester) async {
    await pumpPropertyApp(
      tester,
      FakePropertyRepository(
        properties: [
          makeProperty(id: 'p1', name: 'Kos Melati'),
          makeProperty(id: 'p2', name: 'Kos Mawar'),
        ],
      ),
    );
    final header = tester
        .getTopLeft(
          find.descendant(
            of: find.byType(ScreenHeader),
            matching: find.text('Properti'),
          ),
        )
        .dx;

    for (final entry in _withoutBack.entries) {
      await tester.pumpWidget(const SizedBox());
      await entry.value(tester);
      final bar = find.byType(DetailAppBar);
      final title = tester.widget<DetailAppBar>(bar).title;

      expect(
        tester
            .getTopLeft(find.descendant(of: bar, matching: find.text(title)))
            .dx,
        closeTo(header, 0.5),
        reason: entry.key,
      );
    }
  });
}
