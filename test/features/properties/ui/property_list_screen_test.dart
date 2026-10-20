import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_form_screen.dart';
import 'package:niscala/features/properties/ui/property_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'property_ui_helpers.dart';

const _ownerEmpty =
    'Belum ada properti. Tambahkan kos pertama Anda untuk mulai mengelola '
    'kamar dan penyewa.';
const _managerEmpty =
    'Belum ada properti yang ditugaskan. Minta Pemilik Kost menugaskan Anda '
    'ke sebuah properti.';

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

/// The title of the tab-root header, which is a [ScreenHeader] and not an app
/// bar.
Finder headerTitle(String title) =>
    find.descendant(of: find.byType(ScreenHeader), matching: find.text(title));

/// Expects that a user cannot perceive or use an action named [label]: it is
/// not in the semantics tree, and pressing where it would sit changes nothing.
/// The action may still be laid out invisibly to keep the header stable.
///
/// With [settle] false, only a few frames are pumped after each press, for
/// states that animate forever such as loading.
Future<void> expectActionUnavailable(
  WidgetTester tester,
  String label, {
  bool settle = true,
}) async {
  final handle = tester.ensureSemantics();
  try {
    expect(find.bySemanticsLabel(label), findsNothing);
    final path = currentPath(tester);
    for (var i = 0; i < find.text(label).evaluate().length; i++) {
      await tester.tapAt(tester.getCenter(find.text(label).at(i)));
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    expect(currentPath(tester), path);
    expect(find.byType(PropertyFormScreen), findsNothing);
  } finally {
    handle.dispose();
  }
}

/// Expects the header to carry no action at all, so that it reserves no width
/// for one.
void expectNoHeaderAction(WidgetTester tester) {
  final header = tester.widget<ScreenHeader>(find.byType(ScreenHeader));
  expect(header.action, isNull);
  expect(find.text('Tambah'), findsNothing);
}

/// Expects the header to carry an action that is laid out but hidden.
Future<void> expectHiddenHeaderAction(
  WidgetTester tester, {
  bool settle = true,
}) async {
  final header = tester.widget<ScreenHeader>(find.byType(ScreenHeader));
  expect(header.action, isNotNull);
  expect(header.actionVisible, isFalse);
  await expectActionUnavailable(tester, 'Tambah', settle: settle);
}

void main() {
  group('header action by state', () {
    testWidgets('an owner has a visible action when properties are listed', (
      tester,
    ) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      final header = tester.widget<ScreenHeader>(find.byType(ScreenHeader));
      expect(header.action, isNotNull);
      expect(header.actionVisible, isTrue);
    });

    testWidgets('an owner has a hidden action while loading', (tester) async {
      final repo = FakePropertyRepository(properties: _two())
        ..listScript.gate = Completer<void>();
      await pumpPropertyApp(tester, repo, settle: false);
      await tester.pump(const Duration(milliseconds: 100));

      await expectHiddenHeaderAction(tester, settle: false);
    });

    testWidgets('an owner has a hidden action when loading failed', (
      tester,
    ) async {
      final repo = FakePropertyRepository()
        ..listScript.always = const ApiFailure.network();
      await pumpPropertyApp(tester, repo);

      await expectHiddenHeaderAction(tester);
    });

    testWidgets('an owner has a hidden action when there are no properties', (
      tester,
    ) async {
      await pumpPropertyApp(tester, FakePropertyRepository());

      await expectHiddenHeaderAction(tester);
    });

    testWidgets('a manager has no action with listed properties', (
      tester,
    ) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(properties: _two()),
        role: UserRole.manager,
      );

      expectNoHeaderAction(tester);
    });

    testWidgets('a manager has no action while loading', (tester) async {
      final repo = FakePropertyRepository(properties: _two())
        ..listScript.gate = Completer<void>();
      await pumpPropertyApp(
        tester,
        repo,
        settle: false,
        role: UserRole.manager,
      );

      expectNoHeaderAction(tester);
    });

    testWidgets('a manager has no action when loading failed', (tester) async {
      final repo = FakePropertyRepository()
        ..listScript.always = const ApiFailure.network();
      await pumpPropertyApp(tester, repo, role: UserRole.manager);

      expectNoHeaderAction(tester);
    });

    testWidgets('a manager has no action when there are no properties', (
      tester,
    ) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(),
        role: UserRole.manager,
      );

      expectNoHeaderAction(tester);
    });
  });

  group('header', () {
    testWidgets('shows the title Properti in the tab header', (tester) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(headerTitle('Properti'), findsOneWidget);
    });

    testWidgets('tells an owner the list holds all their properties', (
      tester,
    ) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      expect(find.text('Semua properti milik Anda'), findsOneWidget);
      expect(find.text('Properti yang ditugaskan kepada Anda'), findsNothing);
    });

    testWidgets('tells a manager the list holds the assigned properties', (
      tester,
    ) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(properties: _two()),
        role: UserRole.manager,
      );

      expect(find.text('Properti yang ditugaskan kepada Anda'), findsOneWidget);
      expect(find.text('Semua properti milik Anda'), findsNothing);
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: _two())
        ..listScript.gate = Completer<void>();
      await pumpPropertyApp(tester, repo, settle: false);

      expectLoading(tester);
      expect(find.text('Kos Melati'), findsNothing);
      expect(find.text(_ownerEmpty), findsNothing);
    });

    testWidgets('shows the items once loading finishes', (tester) async {
      final gate = Completer<void>();
      final repo = FakePropertyRepository(properties: _two())
        ..listScript.gate = gate;
      await pumpPropertyApp(tester, repo, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: _two())
        ..listScript.always = const ApiFailure.network();
      await pumpPropertyApp(tester, repo);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(errorMessage('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text('Kos Melati'), findsNothing);
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final repo = FakePropertyRepository()
        ..listScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpPropertyApp(tester, repo);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the list again', (tester) async {
      final repo = FakePropertyRepository(properties: _two())
        ..listScript.queue.add(const ApiFailure.network());
      await pumpPropertyApp(tester, repo);
      expect(repo.listCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(repo.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Kos Melati'), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final repo = FakePropertyRepository()
        ..listScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await pumpPropertyApp(tester, repo);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage('INTERNAL_ERROR')), findsOneWidget);
      expect(repo.listCalls, 2);
    });
  });

  group('empty', () {
    testWidgets('invites an owner to add the first property', (tester) async {
      await pumpPropertyApp(tester, FakePropertyRepository());

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(_ownerEmpty), findsOneWidget);
      expect(find.text('Tambah Properti Pertama'), findsOneWidget);
    });

    testWidgets('Tambah Properti Pertama opens the add form', (tester) async {
      await pumpPropertyApp(tester, FakePropertyRepository());

      await tester.tap(find.text('Tambah Properti Pertama'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/tambah');
      expect(find.byType(PropertyFormScreen), findsOneWidget);
    });

    testWidgets('tells a manager to ask the owner and offers no action', (
      tester,
    ) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(),
        role: UserRole.manager,
      );

      expect(find.text(_managerEmpty), findsOneWidget);
      expect(find.text(_ownerEmpty), findsNothing);
      expect(find.text('Tambah Properti Pertama'), findsNothing);
      expectNoHeaderAction(tester);
      await expectActionUnavailable(tester, 'Tambah Properti Pertama');
    });
  });

  group('items', () {
    testWidgets('shows one entry per property in the order returned', (
      tester,
    ) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('Kos Mawar'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Kos Melati')).dy,
        lessThan(tester.getTopLeft(find.text('Kos Mawar')).dy),
      );
    });

    testWidgets('shows the address and the room counts', (tester) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      expect(find.text('Jl. Melati 1, Bandung'), findsOneWidget);
      expect(find.text('Jl. Mawar 2, Jakarta'), findsOneWidget);
      expect(find.text('10 kamar · 4 terisi'), findsOneWidget);
      expect(find.text('6 kamar · 6 terisi'), findsOneWidget);
    });

    testWidgets('shows the names of the managers joined by commas', (
      tester,
    ) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      expect(find.text('Pengelola: Sari, Dewi'), findsOneWidget);
    });

    testWidgets('says there is no manager when none is assigned', (
      tester,
    ) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      expect(find.text('Belum ada pengelola'), findsOneWidget);
    });

    testWidgets('marks a view-only property with Hanya lihat', (tester) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(properties: _two(secondEditable: false)),
      );

      expect(find.text('Hanya lihat'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(StatusBadge),
          matching: find.text('Hanya lihat'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows no Hanya lihat badge when every property is editable', (
      tester,
    ) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      expect(find.text('Hanya lihat'), findsNothing);
    });

    testWidgets('reads each property as a single merged item', (tester) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      final label = semanticsLabelOf(tester, 'Kos Melati');
      expect(label, contains('Kos Melati'));
      expect(label, contains('Jl. Melati 1, Bandung'));
      expect(label, contains('10 kamar · 4 terisi'));
      expect(label, contains('Pengelola: Sari, Dewi'));
      expect(label, isNot(contains('Kos Mawar')));
    });

    testWidgets('includes Hanya lihat in the merged reading', (tester) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(properties: _two(secondEditable: false)),
      );

      expect(semanticsLabelOf(tester, 'Kos Mawar'), contains('Hanya lihat'));
    });

    testWidgets('tapping a property opens its detail', (tester) async {
      final repo = FakePropertyRepository(properties: _two());
      await pumpPropertyApp(tester, repo);

      await tester.tap(find.text('Kos Mawar'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p2');
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
      expect(
        tester
            .widget<PropertyDetailScreen>(find.byType(PropertyDetailScreen))
            .propertyId,
        'p2',
      );
    });

    testWidgets('Kembali on the detail returns to the list', (tester) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));
      await tester.tap(find.text('Kos Melati'));
      await tester.pumpAndSettle();

      await pressBack(tester);

      expect(currentPath(tester), '/properti');
      expect(find.byType(PropertyListScreen), findsOneWidget);
      expect(find.text('Kos Mawar'), findsOneWidget);
    });
  });

  group('add button', () {
    testWidgets('an owner sees Tambah, at least 48 dp, that opens the form', (
      tester,
    ) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      expect(find.text('Tambah'), findsOneWidget);
      expectTargetSize(tester, 'Tambah');

      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/tambah');
      expect(find.byType(PropertyFormScreen), findsOneWidget);
      expect(
        tester
            .widget<PropertyFormScreen>(find.byType(PropertyFormScreen))
            .propertyId,
        isNull,
      );
    });

    testWidgets('a manager never sees Tambah', (tester) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(properties: _two()),
        role: UserRole.manager,
      );

      expect(find.text('Tambah Properti Pertama'), findsNothing);
      expectNoHeaderAction(tester);
    });
  });

  group('single property', () {
    testWidgets('an owner with one property still sees the list', (
      tester,
    ) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(properties: [_two().first]),
      );

      expect(find.byType(PropertyDetailScreen), findsNothing);
      expect(headerTitle('Properti'), findsOneWidget);
      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('Tambah'), findsOneWidget);
    });

    testWidgets('a manager with one property sees its detail directly', (
      tester,
    ) async {
      final repo = FakePropertyRepository(properties: [_two().first]);
      await pumpPropertyApp(tester, repo, role: UserRole.manager);

      final detail = tester.widget<PropertyDetailScreen>(
        find.byType(PropertyDetailScreen),
      );
      expect(detail.propertyId, 'p1');
      expect(detail.showBack, isFalse);
      expect(appBarTitle('Rincian Properti'), findsOneWidget);
      expect(backButton(), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.text('Properti yang ditugaskan kepada Anda'), findsNothing);
      expect(repo.calls, contains('get:p1'));
    });

    testWidgets('a manager with two properties sees the list', (tester) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(properties: _two()),
        role: UserRole.manager,
      );

      expect(find.byType(PropertyDetailScreen), findsNothing);
      expect(find.text('Kos Melati'), findsOneWidget);
      expect(find.text('Kos Mawar'), findsOneWidget);
    });

    testWidgets('a manager list shows Kembali on a property detail', (
      tester,
    ) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(properties: _two()),
        role: UserRole.manager,
      );

      await tester.tap(find.text('Kos Melati'));
      await tester.pumpAndSettle();

      expect(backButton(), findsOneWidget);
      expect(
        tester
            .widget<PropertyDetailScreen>(find.byType(PropertyDetailScreen))
            .showBack,
        isTrue,
      );
    });
  });

  group('structure', () {
    testWidgets('is a tab root with a ScreenHeader and no app bar', (
      tester,
    ) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      expect(find.byType(ScreenHeader), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PropertyListScreen),
          matching: find.byType(AppBar),
        ),
        findsNothing,
      );
    });

    testWidgets('announces the header title as the page heading', (
      tester,
    ) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(headerTitle('Properti')),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      'an owner sees Tambah as a filled primary action in the header',
      (tester) async {
        await pumpPropertyApp(
          tester,
          FakePropertyRepository(properties: _two()),
        );

        final action = find.descendant(
          of: find.byType(ScreenHeader),
          matching: find.text('Tambah'),
        );
        expect(action, findsOneWidget);
        expect(
          find.ancestor(of: action, matching: find.byType(FilledButton)),
          findsOneWidget,
        );
      },
    );

    testWidgets('a manager gets a header without an action', (tester) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(properties: _two()),
        role: UserRole.manager,
      );

      expect(find.byType(ScreenHeader), findsOneWidget);
      expectNoHeaderAction(tester);
    });

    testWidgets('every property row is a card holding one property', (
      tester,
    ) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      expect(
        find.descendant(
          of: find.byType(PropertyListScreen),
          matching: find.byType(Card),
        ),
        findsNWidgets(2),
      );
      for (final name in ['Kos Melati', 'Kos Mawar']) {
        expect(
          find.ancestor(of: find.text(name), matching: find.byType(Card)),
          findsOneWidget,
        );
      }
    });

    testWidgets(
      'each card has a 16 dp radius, a divider border and no shadow',
      (tester) async {
        await pumpPropertyApp(
          tester,
          FakePropertyRepository(properties: _two()),
        );

        expectCardLook(
          tester,
          find.descendant(
            of: find.byType(PropertyListScreen),
            matching: find.byType(Card),
          ),
        );
      },
    );

    testWidgets('a card holds the whole row of its property', (tester) async {
      await pumpPropertyApp(tester, FakePropertyRepository(properties: _two()));

      final melati = find.ancestor(
        of: find.text('Kos Melati'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(
          of: melati,
          matching: find.text('Jl. Melati 1, Bandung'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: melati, matching: find.text('10 kamar · 4 terisi')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: melati,
          matching: find.text('Pengelola: Sari, Dewi'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: melati, matching: find.text('Kos Mawar')),
        findsNothing,
      );
    });

    testWidgets('the view-only badge sits inside its property card', (
      tester,
    ) async {
      await pumpPropertyApp(
        tester,
        FakePropertyRepository(properties: _two(secondEditable: false)),
      );

      final mawar = find.ancestor(
        of: find.text('Kos Mawar'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: mawar, matching: find.text('Hanya lihat')),
        findsOneWidget,
      );
    });
  });

  group('accessibility', () {
    final states =
        <String, ({FakePropertyRepository Function() repo, UserRole role})>{
          'loaded for an owner': (
            repo: () => FakePropertyRepository(properties: _two()),
            role: UserRole.owner,
          ),
          'loaded for a manager': (
            repo: () => FakePropertyRepository(properties: _two()),
            role: UserRole.manager,
          ),
          'with a view-only property': (
            repo: () =>
                FakePropertyRepository(properties: _two(secondEditable: false)),
            role: UserRole.owner,
          ),
          'empty for an owner': (
            repo: () => FakePropertyRepository(),
            role: UserRole.owner,
          ),
          'empty for a manager': (
            repo: () => FakePropertyRepository(),
            role: UserRole.manager,
          ),
          'failed': (
            repo: () =>
                FakePropertyRepository()
                  ..listScript.always = const ApiFailure.network(),
            role: UserRole.owner,
          ),
          'single property for a manager': (
            repo: () => FakePropertyRepository(properties: [_two().first]),
            role: UserRole.manager,
          ),
        };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines when ${entry.key}', (tester) async {
        await pumpPropertyApp(
          tester,
          entry.value.repo(),
          role: entry.value.role,
        );

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size when ${entry.key}', (tester) async {
        await pumpPropertyApp(
          tester,
          entry.value.repo(),
          role: entry.value.role,
          largeText: true,
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets the guidelines while loading', (tester) async {
      final repo = FakePropertyRepository()..listScript.gate = Completer();
      await pumpPropertyApp(tester, repo, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size while loading', (tester) async {
      final repo = FakePropertyRepository()..listScript.gate = Completer();
      await pumpPropertyApp(tester, repo, settle: false, largeText: true);

      expect(tester.takeException(), isNull);
    });
  });
}
