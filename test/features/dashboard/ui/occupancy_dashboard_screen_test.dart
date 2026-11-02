import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/dashboard/ui/occupancy_dashboard_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/layout.dart';
import '../../auth/ui/auth_ui_helpers.dart';

const _summaryHeading = 'Ringkasan semua properti';
const _retry = 'Coba lagi';
const _loadingLabel = 'Memuat';
const _occupied = 'Terisi';
const _vacant = 'Kosong';

const _failure = ApiFailure(code: 'INTERNAL_ERROR');

// The figures below are deliberately unrelated to the rooms listed, and the
// summary is not the sum of the properties, so that any figure computed by the
// screen instead of read from the response shows up.
PropertyOccupancy _melati() => makePropertyOccupancy(
  id: 'p1',
  name: 'Kos Melati',
  occupiedRoomCount: 37,
  vacantRoomCount: 12,
  roomCount: 49,
  occupancyPercentage: 88,
  rooms: [
    makeOccupancyRoom(id: 'r1', number: 'A1'),
    makeOccupancyRoom(id: 'r2', number: 'A2', occupancy: Occupancy.vacant),
    makeOccupancyRoom(id: 'r3', number: 'A3', occupancy: Occupancy.vacant),
  ],
);

PropertyOccupancy _mawar() => makePropertyOccupancy(
  id: 'p2',
  name: 'Kos Mawar',
  occupiedRoomCount: 41,
  vacantRoomCount: 15,
  roomCount: 56,
  occupancyPercentage: 23,
  rooms: [
    makeOccupancyRoom(id: 'r4', number: 'B1', occupancy: Occupancy.vacant),
    makeOccupancyRoom(id: 'r5', number: 'B2'),
  ],
);

OccupancySummary _summary({int propertyCount = 2}) => makeOccupancySummary(
  propertyCount: propertyCount,
  occupiedRoomCount: 90,
  vacantRoomCount: 27,
  roomCount: 105,
  occupancyPercentage: 64,
);

FakeDashboardRepository _two() => FakeDashboardRepository(
  dashboard: makeOccupancyDashboard(
    items: [_melati(), _mawar()],
    summary: _summary(),
  ),
);

FakeDashboardRepository _one() => FakeDashboardRepository(
  dashboard: makeOccupancyDashboard(
    items: [_melati()],
    summary: _summary(propertyCount: 1),
  ),
);

Future<void> _open(
  WidgetTester tester, {
  FakeDashboardRepository? dashboard,
  UserRole role = UserRole.owner,
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    dashboard: dashboard ?? _two(),
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // A held request keeps a spinner on screen, which never settles.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

double _top(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

/// The label of the occupancy badge that sits in the chip of the room
/// [number]: the exact label text found nearest above the room number.
String? _badgeOfRoom(WidgetTester tester, String number) {
  final numberFinder = find.textContaining(number);
  expect(numberFinder, findsOneWidget, reason: 'room $number');
  String? label;
  tester.element(numberFinder).visitAncestorElements((ancestor) {
    for (final candidate in [_occupied, _vacant]) {
      final inside = find.descendant(
        of: find.byWidget(ancestor.widget),
        matching: find.text(candidate),
      );
      if (inside.evaluate().isNotEmpty) {
        label = candidate;
        return false;
      }
    }
    return true;
  });
  return label;
}

Finder _percent(String value) => find.textContaining('$value%');

void main() {
  setUpAll(loadAppFont);

  group('header', () {
    testWidgets('is a tab root header titled Beranda without an app bar', (
      tester,
    ) async {
      await _open(tester);

      expect(find.byType(OccupancyDashboardScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ScreenHeader),
          matching: find.text('Beranda'),
        ),
        findsOneWidget,
      );
      expect(find.byType(AppBar), findsNothing);
    });

    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('is shown to a $role', (tester) async {
        final dashboard = _two();
        await _open(tester, role: role, dashboard: dashboard);

        expect(find.byType(OccupancyDashboardScreen), findsOneWidget);
        expect(find.text('Kos Melati'), findsOneWidget);
        expect(dashboard.calls, 1);
      });
    }

    testWidgets('is kept while loading', (tester) async {
      final dashboard = FakeDashboardRepository()
        ..script.gate = Completer<void>();
      await _open(tester, dashboard: dashboard, settle: false);

      expect(
        find.descendant(
          of: find.byType(ScreenHeader),
          matching: find.text('Beranda'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('is kept when the request fails', (tester) async {
      final dashboard = FakeDashboardRepository()..script.always = _failure;
      await _open(tester, dashboard: dashboard);

      expect(
        find.descendant(
          of: find.byType(ScreenHeader),
          matching: find.text('Beranda'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('is kept when there is no property', (tester) async {
      await _open(tester, dashboard: FakeDashboardRepository());

      expect(
        find.descendant(
          of: find.byType(ScreenHeader),
          matching: find.text('Beranda'),
        ),
        findsOneWidget,
      );
    });
  });

  group('loading', () {
    testWidgets('shows a labelled progress indicator and nothing else', (
      tester,
    ) async {
      final dashboard = _two()..script.gate = Completer<void>();
      final handle = tester.ensureSemantics();
      try {
        await _open(tester, dashboard: dashboard, settle: false);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.bySemanticsLabel(_loadingLabel), findsOneWidget);
        expect(find.text(_summaryHeading), findsNothing);
        expect(find.text('Kos Melati'), findsNothing);
        expect(find.byType(ErrorView), findsNothing);
        expect(find.byType(EmptyState), findsNothing);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('requests the dashboard once', (tester) async {
      final dashboard = _two();
      await _open(tester, dashboard: dashboard);

      expect(dashboard.calls, 1);
    });
  });

  group('error', () {
    testWidgets('shows the message of the error code with a retry', (
      tester,
    ) async {
      final dashboard = _two()..script.always = _failure;
      await _open(tester, dashboard: dashboard);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
      expect(find.text(_retry), findsOneWidget);
      expect(find.text('Kos Melati'), findsNothing);
      expect(find.text(_summaryHeading), findsNothing);
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('shows the Indonesian message of a forbidden response', (
      tester,
    ) async {
      final dashboard = _two()
        ..script.always = const ApiFailure(code: 'FORBIDDEN', statusCode: 403);
      await _open(tester, dashboard: dashboard);

      expect(find.text(messageOfCode('FORBIDDEN')), findsOneWidget);
      expect(find.text('English text'), findsNothing);
    });

    testWidgets('shows the message of a network failure', (tester) async {
      final dashboard = _two()..script.always = const ApiFailure.network();
      await _open(tester, dashboard: dashboard);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text(_retry), findsOneWidget);
    });

    testWidgets('retry fetches the dashboard again and shows it', (
      tester,
    ) async {
      final dashboard = _two()..script.always = _failure;
      await _open(tester, dashboard: dashboard);
      expect(dashboard.calls, 1);

      dashboard.script.always = null;
      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();

      expect(dashboard.calls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('Kos Mawar'), findsOneWidget);
    });

    testWidgets('keeps the error when the retry fails again', (tester) async {
      final dashboard = _two()..script.always = _failure;
      await _open(tester, dashboard: dashboard);

      await tester.tap(find.text(_retry));
      await tester.pumpAndSettle();

      expect(dashboard.calls, 2);
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(_retry), findsOneWidget);
    });

    testWidgets('shows a spinner while the retry is in flight', (tester) async {
      final dashboard = _two()..script.always = _failure;
      await _open(tester, dashboard: dashboard);

      dashboard.script
        ..always = null
        ..gate = Completer<void>();
      await tester.tap(find.text(_retry));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });
  });

  group('empty', () {
    testWidgets('explains that there is no property, without any figure', (
      tester,
    ) async {
      await _open(tester, dashboard: FakeDashboardRepository());

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.textContaining('Belum ada properti'), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(_summaryHeading), findsNothing);
      expect(find.text(_occupied), findsNothing);
      expect(find.text(_vacant), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('shows no figure even when the summary reports some', (
      tester,
    ) async {
      final dashboard = FakeDashboardRepository(
        dashboard: makeOccupancyDashboard(summary: _summary()),
      );
      await _open(tester, dashboard: dashboard);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(_summaryHeading), findsNothing);
      expect(find.textContaining('90'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('offers no retry', (tester) async {
      await _open(tester, dashboard: FakeDashboardRepository());

      expect(find.text(_retry), findsNothing);
    });
  });

  group('summary', () {
    testWidgets('is shown first when there are several properties', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text(_summaryHeading), findsOneWidget);
      expect(
        _top(tester, find.text(_summaryHeading)),
        lessThan(_top(tester, find.text('Kos Melati'))),
      );
      expect(
        _top(tester, find.text(_summaryHeading)),
        lessThan(_top(tester, find.text('Kos Mawar'))),
      );
    });

    testWidgets('has a heading announced as a header', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await _open(tester);

        expect(
          tester.getSemantics(find.text(_summaryHeading)),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('shows the occupied, vacant and room counts and the '
        'percentage as returned', (tester) async {
      await _open(tester);

      expect(find.textContaining('90'), findsOneWidget);
      expect(find.textContaining('27'), findsOneWidget);
      expect(find.textContaining('105'), findsOneWidget);
      expect(_percent('64'), findsOneWidget);
    });

    testWidgets('does not add up the figures of the properties', (
      tester,
    ) async {
      await _open(tester);

      // 37 + 41 occupied, 12 + 15 vacant, 49 + 56 rooms would be 78, 27, 105;
      // the summary says 90 occupied, so 78 must not appear.
      expect(find.textContaining('78'), findsNothing);
    });

    testWidgets('is shown when the summary counts several properties but '
        'the list holds one', (tester) async {
      final dashboard = FakeDashboardRepository(
        dashboard: makeOccupancyDashboard(
          items: [_melati()],
          summary: _summary(propertyCount: 2),
        ),
      );
      await _open(tester, dashboard: dashboard);

      expect(find.text(_summaryHeading), findsOneWidget);
      expect(find.text('Kos Melati'), findsOneWidget);
    });

    testWidgets('is left out with exactly one property', (tester) async {
      await _open(tester, dashboard: _one());

      expect(find.text(_summaryHeading), findsNothing);
      expect(find.textContaining('105'), findsNothing);
      expect(_percent('64'), findsNothing);
      expect(find.text('Kos Melati'), findsOneWidget);
    });
  });

  group('property cards', () {
    testWidgets('show one card per property in the order of the API', (
      tester,
    ) async {
      await _open(tester);

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('Kos Mawar'), findsOneWidget);
      expect(
        _top(tester, find.text('Kos Melati')),
        lessThan(_top(tester, find.text('Kos Mawar'))),
      );
    });

    testWidgets('keep the order of the API rather than sorting by name', (
      tester,
    ) async {
      final dashboard = FakeDashboardRepository(
        dashboard: makeOccupancyDashboard(
          items: [_mawar(), _melati()],
          summary: _summary(),
        ),
      );
      await _open(tester, dashboard: dashboard);

      expect(
        _top(tester, find.text('Kos Mawar')),
        lessThan(_top(tester, find.text('Kos Melati'))),
      );
    });

    testWidgets('show the occupied and vacant labels', (tester) async {
      await _open(tester, dashboard: _one());

      expect(find.textContaining(_occupied), findsWidgets);
      expect(find.textContaining(_vacant), findsWidgets);
    });

    testWidgets('show the counts and the percentage as returned', (
      tester,
    ) async {
      await _open(tester, dashboard: _one());

      expect(find.textContaining('37'), findsOneWidget);
      expect(find.textContaining('12'), findsOneWidget);
      expect(_percent('88'), findsOneWidget);
    });

    testWidgets('show the figures of each property under its own card', (
      tester,
    ) async {
      await _open(tester);

      final melati = _top(tester, find.text('Kos Melati'));
      final mawar = _top(tester, find.text('Kos Mawar'));
      expect(_top(tester, find.textContaining('37')), greaterThan(melati));
      expect(_top(tester, find.textContaining('37')), lessThan(mawar));
      expect(_top(tester, find.textContaining('41')), greaterThan(mawar));
      expect(_top(tester, _percent('88')), lessThan(mawar));
      expect(_top(tester, _percent('23')), greaterThan(mawar));
    });

    testWidgets('do not compute figures from the rooms listed', (tester) async {
      await _open(tester, dashboard: _one());

      // The rooms listed are one occupied and two vacant: 1, 2 and 33%.
      expect(find.textContaining('33%'), findsNothing);
      expect(find.textContaining('34%'), findsNothing);
    });

    testWidgets('show a property without rooms with its returned figures', (
      tester,
    ) async {
      final dashboard = FakeDashboardRepository(
        dashboard: makeOccupancyDashboard(
          items: [
            makePropertyOccupancy(
              name: 'Kos Baru',
              occupiedRoomCount: 0,
              vacantRoomCount: 0,
              occupancyPercentage: 0,
              rooms: const [],
            ),
          ],
          summary: makeOccupancySummary(
            occupiedRoomCount: 0,
            vacantRoomCount: 0,
            occupancyPercentage: 0,
          ),
        ),
      );
      await _open(tester, dashboard: dashboard);

      expect(find.text('Kos Baru'), findsOneWidget);
      expect(_percent('0'), findsOneWidget);
      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('show a fully occupied property at 100%', (tester) async {
      final dashboard = FakeDashboardRepository(
        dashboard: makeOccupancyDashboard(
          items: [
            makePropertyOccupancy(
              occupiedRoomCount: 2,
              vacantRoomCount: 0,
              occupancyPercentage: 100,
              rooms: [
                makeOccupancyRoom(id: 'r1', number: 'A1'),
                makeOccupancyRoom(id: 'r2', number: 'A2'),
              ],
            ),
          ],
          summary: makeOccupancySummary(
            occupiedRoomCount: 2,
            vacantRoomCount: 0,
            occupancyPercentage: 100,
          ),
        ),
      );
      await _open(tester, dashboard: dashboard);

      expect(_percent('100'), findsOneWidget);
    });

    testWidgets('show many properties', (tester) async {
      final dashboard = FakeDashboardRepository(
        dashboard: makeOccupancyDashboard(
          items: [
            for (var i = 1; i <= 5; i++)
              makePropertyOccupancy(
                id: 'p$i',
                name: 'Kos Nomor $i',
                rooms: [makeOccupancyRoom(id: 'r$i', number: 'K$i')],
              ),
          ],
          summary: _summary(propertyCount: 5),
        ),
      );
      await _open(tester, dashboard: dashboard);

      for (var i = 1; i <= 5; i++) {
        expect(find.text('Kos Nomor $i'), findsOneWidget);
      }
    });
  });

  group('room chips', () {
    testWidgets('show the room number of every room', (tester) async {
      await _open(tester);

      for (final number in ['A1', 'A2', 'A3', 'B1', 'B2']) {
        expect(find.textContaining(number), findsOneWidget, reason: number);
      }
    });

    testWidgets('show Terisi for an occupied room and Kosong for a vacant '
        'room', (tester) async {
      await _open(tester);

      expect(_badgeOfRoom(tester, 'A1'), _occupied);
      expect(_badgeOfRoom(tester, 'A2'), _vacant);
      expect(_badgeOfRoom(tester, 'A3'), _vacant);
      expect(_badgeOfRoom(tester, 'B1'), _vacant);
      expect(_badgeOfRoom(tester, 'B2'), _occupied);
    });

    testWidgets('keep the order of the rooms returned', (tester) async {
      await _open(tester, dashboard: _one());

      final a1 = tester.getTopLeft(find.textContaining('A1').first);
      final a2 = tester.getTopLeft(find.textContaining('A2').first);
      final a3 = tester.getTopLeft(find.textContaining('A3').first);
      // Reading order: top to bottom, then left to right.
      bool before(Offset a, Offset b) =>
          a.dy < b.dy - 0.5 || ((a.dy - b.dy).abs() <= 0.5 && a.dx < b.dx);
      expect(before(a1, a2), isTrue);
      expect(before(a2, a3), isTrue);
    });

    testWidgets('show each room under the card of its own property', (
      tester,
    ) async {
      await _open(tester);

      final mawar = _top(tester, find.text('Kos Mawar'));
      expect(_top(tester, find.textContaining('A1')), lessThan(mawar));
      expect(_top(tester, find.textContaining('A3')), lessThan(mawar));
      expect(_top(tester, find.textContaining('B1')), greaterThan(mawar));
    });

    testWidgets('state the occupancy in words, not by colour alone', (
      tester,
    ) async {
      final dashboard = FakeDashboardRepository(
        dashboard: makeOccupancyDashboard(
          items: [
            makePropertyOccupancy(
              rooms: [
                makeOccupancyRoom(id: 'r1', number: 'A1'),
                makeOccupancyRoom(
                  id: 'r2',
                  number: 'A2',
                  occupancy: Occupancy.vacant,
                ),
              ],
            ),
          ],
          summary: makeOccupancySummary(propertyCount: 1),
        ),
      );
      await _open(tester, dashboard: dashboard);

      expect(_badgeOfRoom(tester, 'A1'), isNotNull);
      expect(_badgeOfRoom(tester, 'A2'), isNotNull);
    });

    testWidgets('are not tappable', (tester) async {
      await _open(tester);

      expect(find.byType(ActionChip), findsNothing);
      expect(find.byType(InputChip), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
    });
  });

  group('content left out on purpose', () {
    testWidgets('names no English glossary term', (tester) async {
      await _open(tester);

      for (final term in [
        'Occupied',
        'Vacant',
        'Occupancy',
        'Dashboard',
        'Summary',
        'Property',
        'Room',
      ]) {
        expect(find.textContaining(term), findsNothing, reason: term);
      }
    });
  });

  group('layout', () {
    testWidgets('scrolls with many rooms at 200 percent text without '
        'overflow', (tester) async {
      final dashboard = FakeDashboardRepository(
        dashboard: makeOccupancyDashboard(
          items: [
            makePropertyOccupancy(
              id: 'p1',
              name: 'Kos Melati Indah Permai Asri Sentosa',
              occupiedRoomCount: 37,
              vacantRoomCount: 12,
              occupancyPercentage: 88,
              rooms: [
                for (var i = 1; i <= 16; i++)
                  makeOccupancyRoom(
                    id: 'r$i',
                    number: 'A$i',
                    occupancy: i.isEven ? Occupancy.vacant : Occupancy.occupied,
                  ),
              ],
            ),
            _mawar(),
          ],
          summary: _summary(),
        ),
      );
      await _open(tester, dashboard: dashboard, largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Kos Mawar'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.textContaining('B2'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits the error state at 200 percent text', (tester) async {
      final dashboard = _two()..script.always = _failure;
      await _open(tester, dashboard: dashboard, largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.text(_retry), findsOneWidget);
    });

    testWidgets('fits the empty state at 200 percent text', (tester) async {
      await _open(
        tester,
        dashboard: FakeDashboardRepository(),
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(EmptyState), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('loaded with several properties', (tester) async {
      await _open(tester);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('loaded with one property', (tester) async {
      await _open(tester, dashboard: _one());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('loaded with a property without rooms', (tester) async {
      final dashboard = FakeDashboardRepository(
        dashboard: makeOccupancyDashboard(
          items: [
            makePropertyOccupancy(
              occupiedRoomCount: 0,
              vacantRoomCount: 0,
              occupancyPercentage: 0,
              rooms: const [],
            ),
          ],
          summary: makeOccupancySummary(
            occupiedRoomCount: 0,
            vacantRoomCount: 0,
            occupancyPercentage: 0,
          ),
        ),
      );
      await _open(tester, dashboard: dashboard);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('empty', (tester) async {
      await _open(tester, dashboard: FakeDashboardRepository());

      await expectMeetsA11yGuidelines(tester);
    });

    // The contrast check mis-samples a single-line centered message, so the
    // error state uses the network failure, whose message wraps.
    testWidgets('with a failing request', (tester) async {
      final dashboard = _two()..script.always = const ApiFailure.network();
      await _open(tester, dashboard: dashboard);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('while loading', (tester) async {
      final dashboard = _two()..script.gate = Completer<void>();
      await _open(tester, dashboard: dashboard, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });
  });

  group('router', () {
    testWidgets('builds the dashboard at the management home path', (
      tester,
    ) async {
      await _open(tester);

      expect(currentPath(tester), '/beranda');
      expect(find.byType(OccupancyDashboardScreen), findsOneWidget);
    });
  });
}
