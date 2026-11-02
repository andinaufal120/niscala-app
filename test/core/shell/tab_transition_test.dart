import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_list_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_list_screen.dart';
import 'package:niscala/features/dashboard/ui/occupancy_dashboard_screen.dart';
import 'package:niscala/features/home/ui/tenant_home_screen.dart';
import 'package:niscala/features/properties/ui/property_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../helpers/fakes.dart';

Finder filterChip(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate(
    (widget) => widget is ChoiceChip || widget is FilterChip,
  ),
);

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// The opacities of every fade around [finder]'s first match: the transitions
/// and opacity widgets that wrap it.
List<double> _opacitiesAround(WidgetTester tester, Finder finder) {
  final values = <double>[];
  finder.evaluate().first.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is FadeTransition) values.add(widget.opacity.value);
    if (widget is Opacity) values.add(widget.opacity);
    if (widget is AnimatedOpacity) values.add(widget.opacity);
    return true;
  });
  return values;
}

double _visibility(WidgetTester tester, Finder finder) => _opacitiesAround(
  tester,
  finder,
).fold(1.0, (product, value) => product * value);

/// Expects [incoming] to be fading in: some fade around it is strictly between
/// transparent and opaque.
void _expectFadingIn(WidgetTester tester, Finder incoming) {
  expect(incoming, findsOneWidget);
  expect(
    _opacitiesAround(tester, incoming).where((v) => v > 0 && v < 1),
    isNotEmpty,
    reason:
        'the new tab must cross-fade, opacities: '
        '${_opacitiesAround(tester, incoming)}',
  );
}

/// Expects the tab switch to be complete: [incoming] fully opaque, [outgoing]
/// not on show.
void _expectSwitched(WidgetTester tester, Finder incoming, Finder outgoing) {
  expect(incoming, findsOneWidget);
  expect(_visibility(tester, incoming), 1.0);
  if (outgoing.evaluate().isNotEmpty) {
    expect(_visibility(tester, outgoing), 0.0);
  }
}

typedef _Switch = ({
  String name,
  UserRole role,
  String from,
  String to,
  Finder fromScreen,
  Finder toScreen,
});

final _switches = <_Switch>[
  (
    name: 'management Beranda to Akun',
    role: UserRole.owner,
    from: 'Beranda',
    to: 'Akun',
    fromScreen: find.byType(OccupancyDashboardScreen),
    toScreen: find.byType(AccountScreen),
  ),
  (
    name: 'management Beranda to Keluhan',
    role: UserRole.owner,
    from: 'Beranda',
    to: 'Keluhan',
    fromScreen: find.byType(OccupancyDashboardScreen),
    toScreen: find.byType(ManagementComplaintListScreen),
  ),
  (
    name: 'management Beranda to Properti',
    role: UserRole.manager,
    from: 'Beranda',
    to: 'Properti',
    fromScreen: find.byType(OccupancyDashboardScreen),
    toScreen: find.byType(PropertyListScreen),
  ),
  (
    name: 'tenant Beranda to Akun',
    role: UserRole.tenant,
    from: 'Beranda',
    to: 'Akun',
    fromScreen: find.byType(TenantHomeScreen),
    toScreen: find.byType(AccountScreen),
  ),
  (
    name: 'tenant Beranda to Keluhan',
    role: UserRole.tenant,
    from: 'Beranda',
    to: 'Keluhan',
    fromScreen: find.byType(TenantHomeScreen),
    toScreen: find.byType(TenantComplaintListScreen),
  ),
];

Future<void> _pumpShell(
  WidgetTester tester,
  UserRole role, {
  FakeComplaintRepository? complaints,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      store: InMemorySessionStore(storedSession(role: role)),
      complaints: complaints,
    ),
  );
  await tester.pumpAndSettle();
}

void _narrow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Future<void> _switchTo(WidgetTester tester, String label) async {
  await tester.tap(_navLabel(label));
}

Finder get _verticalScroll =>
    find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical);

void main() {
  group('switching tabs', () {
    for (final s in _switches) {
      testWidgets('${s.name} cross-fades the incoming tab', (tester) async {
        await _pumpShell(tester, s.role);

        await _switchTo(tester, s.to);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        _expectFadingIn(tester, s.toScreen);
      });

      testWidgets('${s.name} ends with only the new tab on show', (
        tester,
      ) async {
        await _pumpShell(tester, s.role);
        expect(s.fromScreen, findsOneWidget);

        await _switchTo(tester, s.to);
        await tester.pumpAndSettle();

        _expectSwitched(tester, s.toScreen, s.fromScreen);
        expect(tester.takeException(), isNull);
      });

      testWidgets('${s.name} is complete after one frame without animations', (
        tester,
      ) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await _pumpShell(tester, s.role);
        expect(s.fromScreen, findsOneWidget);

        await _switchTo(tester, s.to);
        await tester.pump();

        _expectSwitched(tester, s.toScreen, s.fromScreen);
      });
    }

    testWidgets('going back fades the first tab in again', (tester) async {
      await _pumpShell(tester, UserRole.owner);
      expect(find.byType(OccupancyDashboardScreen), findsOneWidget);
      await _switchTo(tester, 'Akun');
      await tester.pumpAndSettle();

      await _switchTo(tester, 'Beranda');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      _expectFadingIn(tester, find.byType(OccupancyDashboardScreen));
      await tester.pumpAndSettle();
      _expectSwitched(
        tester,
        find.byType(OccupancyDashboardScreen),
        find.byType(AccountScreen),
      );
    });
  });

  group('branch state', () {
    List<Complaint> many() => [
      for (var i = 0; i < 30; i++)
        makeComplaint(
          id: 'c$i',
          description: 'Keluhan nomor $i',
          status: i == 0 ? ComplaintStatus.done : ComplaintStatus.new_,
        ),
    ];

    testWidgets('management keeps the chosen filter chip', (tester) async {
      await _pumpShell(
        tester,
        UserRole.owner,
        complaints: FakeComplaintRepository(complaints: many()),
      );
      await _switchTo(tester, 'Keluhan');
      await tester.pumpAndSettle();
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      await _switchTo(tester, 'Akun');
      await tester.pumpAndSettle();
      await _switchTo(tester, 'Keluhan');
      await tester.pumpAndSettle();

      expect(tester.widget<ChoiceChip>(filterChip('Selesai')).selected, isTrue);
      expect(tester.widget<ChoiceChip>(filterChip('Semua')).selected, isFalse);
    });

    testWidgets('management keeps the scroll position', (tester) async {
      _narrow(tester);
      await _pumpShell(
        tester,
        UserRole.owner,
        complaints: FakeComplaintRepository(complaints: many()),
      );
      await _switchTo(tester, 'Keluhan');
      await tester.pumpAndSettle();
      await tester.drag(_verticalScroll.first, const Offset(0, -400));
      await tester.pumpAndSettle();
      final before = tester
          .state<ScrollableState>(_verticalScroll.first)
          .position
          .pixels;
      expect(before, greaterThan(0));

      await _switchTo(tester, 'Akun');
      await tester.pumpAndSettle();
      await _switchTo(tester, 'Keluhan');
      await tester.pumpAndSettle();

      expect(
        tester.state<ScrollableState>(_verticalScroll.first).position.pixels,
        before,
      );
    });

    testWidgets('tenant keeps the chosen filter chip', (tester) async {
      await _pumpShell(
        tester,
        UserRole.tenant,
        complaints: FakeComplaintRepository(complaints: many()),
      );
      await _switchTo(tester, 'Keluhan');
      await tester.pumpAndSettle();
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      await _switchTo(tester, 'Akun');
      await tester.pumpAndSettle();
      await _switchTo(tester, 'Keluhan');
      await tester.pumpAndSettle();

      expect(tester.widget<ChoiceChip>(filterChip('Selesai')).selected, isTrue);
      expect(tester.widget<ChoiceChip>(filterChip('Aktif')).selected, isFalse);
    });

    testWidgets('tenant keeps the scroll position', (tester) async {
      _narrow(tester);
      await _pumpShell(
        tester,
        UserRole.tenant,
        complaints: FakeComplaintRepository(complaints: many()),
      );
      await _switchTo(tester, 'Keluhan');
      await tester.pumpAndSettle();
      await tester.drag(_verticalScroll.first, const Offset(0, -400));
      await tester.pumpAndSettle();
      final before = tester
          .state<ScrollableState>(_verticalScroll.first)
          .position
          .pixels;
      expect(before, greaterThan(0));

      await _switchTo(tester, 'Akun');
      await tester.pumpAndSettle();
      await _switchTo(tester, 'Keluhan');
      await tester.pumpAndSettle();

      expect(
        tester.state<ScrollableState>(_verticalScroll.first).position.pixels,
        before,
      );
    });

    testWidgets('the state is kept when switching without animations', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _pumpShell(
        tester,
        UserRole.owner,
        complaints: FakeComplaintRepository(complaints: many()),
      );
      await _switchTo(tester, 'Keluhan');
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.tap(filterChip('Selesai'));
      await tester.pumpAndSettle();

      await _switchTo(tester, 'Akun');
      await tester.pump();
      await _switchTo(tester, 'Keluhan');
      await tester.pump();

      expect(tester.widget<ChoiceChip>(filterChip('Selesai')).selected, isTrue);
    });
  });
}
