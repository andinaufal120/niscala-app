import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/subscription/ui/downgrade_screen.dart';
import 'package:niscala/features/subscription/ui/subscription_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'subscription_ui_helpers.dart';

const _save = 'Simpan penurunan paket';
const _renewalNote =
    'Perpanjangan dikelola di Google Play: ubah atau batalkan langganan di '
    'sana.';
const _explanation =
    'Penurunan paket berlaku setelah periode berjalan berakhir pada '
    '15 Des 2026. Yang tidak dipilih hanya bisa dilihat, tidak bisa diubah.';
const _noPaidPlan = 'Tidak ada langganan berbayar yang bisa diturunkan.';
const _scheduled = 'Penurunan paket dijadwalkan';

const _pickThreeProperties = 'Pilih 3 properti yang tetap bisa diubah';
const _pickOneProperty = 'Pilih 1 properti yang tetap bisa diubah';
const _keptProperties = 'Properti yang tetap bisa diubah';
const _pickFifteenRooms = 'Pilih 15 kamar yang tetap bisa diubah';

const _wrongProperties3 = 'Pilih tepat 3 properti.';
const _wrongProperties1 = 'Pilih tepat 1 properti.';
const _wrongRooms = 'Pilih tepat 15 kamar.';

FakeSubscriptionRepository _pro() => FakeSubscriptionRepository(
  subscription: makeActiveSubscription(planCode: PlanCode.pro),
);

FakeSubscriptionRepository _basic() => FakeSubscriptionRepository(
  subscription: makeActiveSubscription(planCode: PlanCode.basic),
);

/// Twenty rooms in Kos Melati (101 to 120), eight in Kos Mawar (201 to 208),
/// fifteen in Kos Anggrek (301 to 315), sixteen in Kos Dahlia (401 to 416).
FakeRoomRepository _rooms() => FakeRoomRepository(
  rooms: [
    ...roomsOf('p1', 20),
    ...roomsOf('p2', 8, base: 200),
    ...roomsOf('p3', 15, base: 300),
    ...roomsOf('p4', 16, base: 400),
  ],
);

Future<void> _openDirect(
  WidgetTester tester,
  FakeSubscriptionRepository subscriptions,
  String plan, {
  FakePropertyRepository? properties,
  FakeRoomRepository? rooms,
  bool settle = true,
  bool largeText = false,
}) => pumpSubscriptionApp(
  tester,
  subscriptions,
  path: downgradePath(plan),
  properties: properties,
  rooms: rooms,
  settle: settle,
  largeText: largeText,
);

/// Opens the downgrade page the way the owner does: from the subscription
/// screen, through the lower plans.
Future<void> _openFromSubscription(
  WidgetTester tester,
  FakeSubscriptionRepository subscriptions,
  String button, {
  FakePropertyRepository? properties,
  FakeRoomRepository? rooms,
}) async {
  await pumpSubscriptionApp(
    tester,
    subscriptions,
    properties: properties,
    rooms: rooms,
  );
  final lower = subscriptions.subscriptionResult.planCode == PlanCode.pro
      ? 2
      : 1;
  await tap(tester, find.text('Lihat paket lebih rendah ($lower)'));
  await tap(tester, find.text(button));
  expect(find.byType(DowngradeScreen), findsOneWidget);
}

Future<void> _submit(WidgetTester tester) => tap(tester, find.text(_save));

void _expectNoSchedule(FakeSubscriptionRepository subscriptions) {
  expect(subscriptions.scheduleCalls, 0);
  expect(subscriptions.scheduled, isEmpty);
}

void main() {
  group('the page', () {
    testWidgets('is titled for Basic as a heading', (tester) async {
      await _openDirect(tester, _pro(), 'basic');

      expect(find.byType(DowngradeScreen), findsOneWidget);
      expect(find.text('Turunkan ke Paket Basic'), findsOneWidget);
      expectHeading(tester, 'Turunkan ke Paket Basic');
    });

    testWidgets('is titled for Gratis', (tester) async {
      await _openDirect(tester, _pro(), 'free');

      expect(find.text('Turunkan ke Paket Gratis'), findsOneWidget);
      expect(find.text('Turunkan ke Paket Basic'), findsNothing);
    });

    testWidgets('covers the bottom navigation', (tester) async {
      await _openDirect(tester, _pro(), 'basic');

      expect(find.byType(NavigationBar), findsNothing);
      expect(currentPath(tester), '$subscriptionPath/turunkan');
    });

    testWidgets('says when the downgrade takes effect', (tester) async {
      await _openDirect(tester, _pro(), 'basic');

      expect(find.text(_explanation), findsOneWidget);
    });

    testWidgets('takes the date from the end of the paid period', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository(
        subscription: makeActiveSubscription(
          planCode: PlanCode.pro,
          endDate: DateTime.utc(2027, 3, 2),
        ),
      );
      await _openDirect(tester, subscriptions, 'basic');

      expect(
        find.text(
          'Penurunan paket berlaku setelah periode berjalan berakhir pada '
          '2 Mar 2027. Yang tidak dipilih hanya bisa dilihat, tidak bisa '
          'diubah.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('points to Google Play for renewal', (tester) async {
      await _openDirect(tester, _pro(), 'basic');

      expect(find.text(_renewalNote), findsOneWidget);
    });

    testWidgets('has Simpan penurunan paket and Batal', (tester) async {
      await _openDirect(tester, _pro(), 'basic');

      expect(find.text(_save), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('loads the subscription, the plans and the properties', (
      tester,
    ) async {
      final subscriptions = _pro();
      final properties = ownerPropertiesForPlans();
      await _openDirect(tester, subscriptions, 'basic', properties: properties);

      expect(subscriptions.subscriptionCalls, greaterThanOrEqualTo(1));
      expect(subscriptions.plansCalls, greaterThanOrEqualTo(1));
      expect(properties.listCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('changes nothing by only opening', (tester) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'basic');

      _expectNoSchedule(subscriptions);
      expect(subscriptions.cancelCalls, 0);
      expect(subscriptions.createOrderCalls, 0);
    });

    testWidgets('never shows an English term or null', (tester) async {
      await _openDirect(tester, _pro(), 'free', rooms: _rooms());

      for (final term in ['Downgrade', 'Keep', 'Subscription', 'null']) {
        expect(find.textContaining(term), findsNothing, reason: term);
      }
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final subscriptions = _pro()..subscriptionScript.gate = Completer<void>();
      await _openDirect(tester, subscriptions, 'basic', settle: false);

      expectLoading(tester);
      expect(find.text(_save), findsNothing);
    });

    testWidgets('keeps loading while the properties are missing', (
      tester,
    ) async {
      final properties = ownerPropertiesForPlans()
        ..listScript.gate = Completer<void>();
      await _openDirect(
        tester,
        _pro(),
        'basic',
        properties: properties,
        settle: false,
      );

      expectLoading(tester);
      expect(find.text(_save), findsNothing);
    });

    testWidgets('keeps loading while the plans are missing', (tester) async {
      final subscriptions = _pro()..plansScript.gate = Completer<void>();
      await _openDirect(tester, subscriptions, 'basic', settle: false);

      expectLoading(tester);
    });

    testWidgets('shows the form once loading finishes', (tester) async {
      final gate = Completer<void>();
      final subscriptions = _pro()..subscriptionScript.gate = gate;
      await _openDirect(tester, subscriptions, 'basic', settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text(_save), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows the failure of the subscription with a retry', (
      tester,
    ) async {
      final subscriptions = _pro()
        ..subscriptionScript.always = const ApiFailure.network();
      await _openDirect(tester, subscriptions, 'basic');

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.text(_save), findsNothing);
    });

    testWidgets('shows the failure of the plans', (tester) async {
      final subscriptions = _pro()
        ..plansScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _openDirect(tester, subscriptions, 'basic');

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
    });

    testWidgets('shows the failure of the property list', (tester) async {
      final properties = ownerPropertiesForPlans()
        ..listScript.always = const ApiFailure.network();
      await _openDirect(tester, _pro(), 'basic', properties: properties);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(find.text(_save), findsNothing);
    });

    testWidgets('Coba lagi loads the properties again', (tester) async {
      final properties = ownerPropertiesForPlans()
        ..listScript.queue.add(const ApiFailure.network());
      await _openDirect(tester, _pro(), 'basic', properties: properties);
      expect(properties.listCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(properties.listCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(_save), findsOneWidget);
    });

    testWidgets('Coba lagi loads the subscription again', (tester) async {
      final subscriptions = _pro()
        ..subscriptionScript.queue.add(const ApiFailure.network());
      await _openDirect(tester, subscriptions, 'basic');
      expect(subscriptions.subscriptionCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(subscriptions.subscriptionCalls, 2);
      expect(find.text(_save), findsOneWidget);
    });
  });

  group('a free subscription', () {
    testWidgets('says there is nothing to downgrade and shows no form', (
      tester,
    ) async {
      await _openDirect(tester, FakeSubscriptionRepository(), 'basic');

      expect(find.text(_noPaidPlan), findsOneWidget);
      expect(find.text(_save), findsNothing);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text(_explanation), findsNothing);
      expect(find.text(_renewalNote), findsNothing);
    });

    testWidgets('keeps the title and sends nothing', (tester) async {
      final subscriptions = FakeSubscriptionRepository();
      await _openDirect(tester, subscriptions, 'free');

      expect(find.text('Turunkan ke Paket Gratis'), findsOneWidget);
      _expectNoSchedule(subscriptions);
    });
  });

  group('Basic with more properties than the plan allows', () {
    testWidgets('asks for exactly the limit of properties as a heading', (
      tester,
    ) async {
      await _openDirect(tester, _pro(), 'basic');

      expect(find.text(_pickThreeProperties), findsOneWidget);
      expectHeading(tester, _pickThreeProperties);
      expect(find.text(_keptProperties), findsNothing);
    });

    testWidgets('lists every property with its room count in a checkbox', (
      tester,
    ) async {
      await _openDirect(tester, _pro(), 'basic');

      expect(find.byType(CheckboxListTile), findsNWidgets(4));
      for (final name in propertyNames) {
        expect(tileOf(name), findsOneWidget, reason: name);
      }
      for (final entry in {
        'Kos Melati': '12',
        'Kos Mawar': '8',
        'Kos Anggrek': '5',
        'Kos Dahlia': '3',
      }.entries) {
        expect(
          find.descendant(
            of: tileOf(entry.key),
            matching: find.textContaining(entry.value),
          ),
          findsAtLeastNWidgets(1),
          reason: entry.key,
        );
      }
    });

    testWidgets('lists the properties in the order returned', (tester) async {
      await _openDirect(tester, _pro(), 'basic');

      final tops = [
        for (final name in propertyNames) tester.getTopLeft(find.text(name)).dy,
      ];
      expect(tops, [...tops]..sort());
    });

    testWidgets('shows no error before anything is submitted', (tester) async {
      await _openDirect(tester, _pro(), 'basic');

      expect(find.textContaining('Pilih tepat'), findsNothing);
    });

    testWidgets('asks for no rooms and loads none', (tester) async {
      final rooms = _rooms();
      await _openDirect(tester, _pro(), 'basic', rooms: rooms);

      expect(find.textContaining('kamar yang tetap bisa diubah'), findsNothing);
      expect(rooms.calls, isEmpty);
    });

    testWidgets('ticking three properties schedules the downgrade to Basic', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'basic');
      await checkOnly(tester, propertyNames, [
        'Kos Melati',
        'Kos Anggrek',
        'Kos Dahlia',
      ]);

      await _submit(tester);

      expect(subscriptions.scheduled, hasLength(1));
      final call = subscriptions.scheduled.single;
      expect(call.planCode, PlanCode.basic);
      expect(call.keptPropertyIds, unorderedEquals(['p1', 'p3', 'p4']));
      expect(call.keptRoomIds, isEmpty);
    });

    testWidgets('a checked box is a checked checkbox and can be unchecked', (
      tester,
    ) async {
      await _openDirect(tester, _pro(), 'basic');
      await setChecked(tester, 'Kos Mawar', true);
      expect(isChecked(tester, 'Kos Mawar'), isTrue);

      await setChecked(tester, 'Kos Mawar', false);

      expect(isChecked(tester, 'Kos Mawar'), isFalse);
    });

    testWidgets('two properties are refused next to the list', (tester) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'basic');
      await checkOnly(tester, propertyNames, ['Kos Melati', 'Kos Mawar']);

      await _submit(tester);

      expect(find.text(_wrongProperties3), findsOneWidget);
      _expectNoSchedule(subscriptions);
      expect(currentPath(tester), '$subscriptionPath/turunkan');
      final error = tester.getTopLeft(find.text(_wrongProperties3)).dy;
      expect(error, greaterThan(tester.getTopLeft(find.text('Kos Melati')).dy));
      expect(error, lessThan(tester.getTopLeft(find.text(_save)).dy));
    });

    testWidgets('no property is refused', (tester) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'basic');
      await checkOnly(tester, propertyNames, []);

      await _submit(tester);

      expect(find.text(_wrongProperties3), findsOneWidget);
      _expectNoSchedule(subscriptions);
    });

    testWidgets('four properties are refused: the extra box is not blocked', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'basic');
      await checkOnly(tester, propertyNames, propertyNames);
      for (final name in propertyNames) {
        expect(isChecked(tester, name), isTrue, reason: name);
      }

      await _submit(tester);

      expect(find.text(_wrongProperties3), findsOneWidget);
      _expectNoSchedule(subscriptions);
    });

    testWidgets('a refused count can be corrected and submitted', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'basic');
      await checkOnly(tester, propertyNames, ['Kos Melati']);
      await _submit(tester);

      await checkOnly(tester, propertyNames, [
        'Kos Melati',
        'Kos Mawar',
        'Kos Anggrek',
      ]);
      await _submit(tester);

      expect(subscriptions.scheduleCalls, 1);
      expect(
        subscriptions.scheduled.single.keptPropertyIds,
        unorderedEquals(['p1', 'p2', 'p3']),
      );
    });
  });

  group('Basic with as many or fewer properties as the plan allows', () {
    for (final count in [3, 2, 1]) {
      testWidgets(
        'with $count properties all are selected and need no choice',
        (tester) async {
          final subscriptions = _pro();
          await _openDirect(
            tester,
            subscriptions,
            'basic',
            properties: firstOwnerProperties(count),
          );

          expect(find.text(_keptProperties), findsOneWidget);
          expectHeading(tester, _keptProperties);
          expect(find.text(_pickThreeProperties), findsNothing);
          for (final name in propertyNames.take(count)) {
            expect(isChecked(tester, name), isTrue, reason: name);
          }
          expect(find.byType(CheckboxListTile), findsNWidgets(count));
        },
      );

      testWidgets('with $count properties the owner submits them all', (
        tester,
      ) async {
        final subscriptions = _pro();
        await _openDirect(
          tester,
          subscriptions,
          'basic',
          properties: firstOwnerProperties(count),
        );

        await _submit(tester);

        expect(find.textContaining('Pilih tepat'), findsNothing);
        expect(subscriptions.scheduleCalls, 1);
        expect(subscriptions.scheduled.single.planCode, PlanCode.basic);
        expect(
          subscriptions.scheduled.single.keptPropertyIds,
          unorderedEquals(['p1', 'p2', 'p3'].take(count)),
        );
        expect(subscriptions.scheduled.single.keptRoomIds, isEmpty);
      });
    }

    testWidgets('an owner with one property keeps it', (tester) async {
      final subscriptions = _pro();
      await _openDirect(
        tester,
        subscriptions,
        'basic',
        properties: firstOwnerProperties(1),
      );

      await _submit(tester);

      expect(subscriptions.scheduled.single.keptPropertyIds, ['p1']);
    });
  });

  group('Gratis', () {
    testWidgets('asks for one property and, before one is chosen, no rooms', (
      tester,
    ) async {
      final rooms = _rooms();
      await _openDirect(tester, _pro(), 'free', rooms: rooms);
      await checkOnly(tester, propertyNames, []);

      expect(find.text(_pickOneProperty), findsOneWidget);
      expectHeading(tester, _pickOneProperty);
      expect(find.text(_pickFifteenRooms), findsNothing);
    });

    testWidgets('choosing a property with more rooms asks for fifteen', (
      tester,
    ) async {
      final rooms = _rooms();
      await _openDirect(tester, _pro(), 'free', rooms: rooms);

      await checkOnly(tester, propertyNames, ['Kos Melati']);

      expect(find.text(_pickFifteenRooms), findsOneWidget);
      expectHeading(tester, _pickFifteenRooms);
      expect(rooms.calls, contains('list:p1'));
    });

    testWidgets('lists the rooms of the chosen property with their state', (
      tester,
    ) async {
      await _openDirect(tester, _pro(), 'free', rooms: _rooms());

      await checkOnly(tester, propertyNames, ['Kos Melati']);

      for (final label in roomLabels(20)) {
        expect(tileOf(label), findsOneWidget, reason: label);
      }
      expect(find.text('Kamar 101, terisi'), findsOneWidget);
      expect(find.text('Kamar 102, kosong'), findsOneWidget);
      expect(find.text('Kamar 201, terisi'), findsNothing);
    });

    testWidgets('fifteen rooms schedule the downgrade to Gratis', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'free', rooms: _rooms());
      await checkOnly(tester, propertyNames, ['Kos Melati']);
      await checkOnly(tester, roomLabels(20), roomLabels(20).take(15).toList());

      await _submit(tester);

      expect(subscriptions.scheduled, hasLength(1));
      final call = subscriptions.scheduled.single;
      expect(call.planCode, PlanCode.free);
      expect(call.keptPropertyIds, ['p1']);
      expect(call.keptRoomIds, unorderedEquals(roomIds('p1', 15)));
    });

    testWidgets('fourteen rooms are refused next to the rooms', (tester) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'free', rooms: _rooms());
      await checkOnly(tester, propertyNames, ['Kos Melati']);
      await checkOnly(tester, roomLabels(20), roomLabels(20).take(14).toList());

      await _submit(tester);

      expect(find.text(_wrongRooms), findsOneWidget);
      _expectNoSchedule(subscriptions);
      expect(currentPath(tester), '$subscriptionPath/turunkan');
      final error = tester.getTopLeft(find.text(_wrongRooms)).dy;
      expect(
        error,
        greaterThan(tester.getTopLeft(find.text(_pickFifteenRooms)).dy),
      );
      expect(error, lessThan(tester.getTopLeft(find.text(_save)).dy));
    });

    testWidgets('sixteen rooms are refused: the extra box is not blocked', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'free', rooms: _rooms());
      await checkOnly(tester, propertyNames, ['Kos Melati']);
      await checkOnly(tester, roomLabels(20), roomLabels(20).take(16).toList());

      await _submit(tester);

      expect(find.text(_wrongRooms), findsOneWidget);
      _expectNoSchedule(subscriptions);
    });

    testWidgets('no room is refused', (tester) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'free', rooms: _rooms());
      await checkOnly(tester, propertyNames, ['Kos Melati']);
      await checkOnly(tester, roomLabels(20), []);

      await _submit(tester);

      expect(find.text(_wrongRooms), findsOneWidget);
      _expectNoSchedule(subscriptions);
    });

    testWidgets('two properties are refused and nothing is sent', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'free', rooms: _rooms());
      await checkOnly(tester, propertyNames, ['Kos Melati', 'Kos Mawar']);

      await _submit(tester);

      expect(find.text(_wrongProperties1), findsOneWidget);
      _expectNoSchedule(subscriptions);
    });

    testWidgets('no property is refused and nothing is sent', (tester) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'free', rooms: _rooms());
      await checkOnly(tester, propertyNames, []);

      await _submit(tester);

      expect(find.text(_wrongProperties1), findsOneWidget);
      _expectNoSchedule(subscriptions);
    });

    testWidgets('a property with fifteen rooms or fewer selects them all', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'free', rooms: _rooms());

      await checkOnly(tester, propertyNames, ['Kos Mawar']);

      for (final label in roomLabels(8, base: 200)) {
        expect(isChecked(tester, label), isTrue, reason: label);
      }
      await _submit(tester);
      expect(find.textContaining('Pilih tepat'), findsNothing);
      final call = subscriptions.scheduled.single;
      expect(call.keptPropertyIds, ['p2']);
      expect(call.keptRoomIds, unorderedEquals(roomIds('p2', 8)));
    });

    testWidgets('a property with exactly fifteen rooms selects them all', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'free', rooms: _rooms());

      await checkOnly(tester, propertyNames, ['Kos Anggrek']);

      for (final label in roomLabels(15, base: 300)) {
        expect(isChecked(tester, label), isTrue, reason: label);
      }
      await _submit(tester);
      expect(
        subscriptions.scheduled.single.keptRoomIds,
        unorderedEquals(roomIds('p3', 15)),
      );
    });

    testWidgets('a property with sixteen rooms asks to choose fifteen', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'free', rooms: _rooms());
      await checkOnly(tester, propertyNames, ['Kos Dahlia']);
      await checkOnly(tester, roomLabels(16, base: 400), []);

      expect(find.text(_pickFifteenRooms), findsOneWidget);
      await _submit(tester);

      expect(find.text(_wrongRooms), findsOneWidget);
      _expectNoSchedule(subscriptions);
    });

    testWidgets('a property without rooms sends no rooms', (tester) async {
      final subscriptions = _pro();
      await _openDirect(
        tester,
        subscriptions,
        'free',
        rooms: FakeRoomRepository(),
      );
      await checkOnly(tester, propertyNames, ['Kos Anggrek']);

      await _submit(tester);

      final call = subscriptions.scheduled.single;
      expect(call.keptPropertyIds, ['p3']);
      expect(call.keptRoomIds, isEmpty);
    });

    testWidgets('switching the property replaces the rooms to choose from', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openDirect(tester, subscriptions, 'free', rooms: _rooms());
      await checkOnly(tester, propertyNames, ['Kos Melati']);
      await checkOnly(tester, roomLabels(20), roomLabels(20).take(15).toList());

      await checkOnly(tester, propertyNames, ['Kos Mawar']);

      expect(find.text('Kamar 101, terisi'), findsNothing);
      expect(find.text('Kamar 201, terisi'), findsOneWidget);
      await _submit(tester);
      final call = subscriptions.scheduled.single;
      expect(call.keptPropertyIds, ['p2']);
      expect(call.keptRoomIds, unorderedEquals(roomIds('p2', 8)));
    });

    testWidgets('a single property is selected and its rooms asked at once', (
      tester,
    ) async {
      final rooms = _rooms();
      await _openDirect(
        tester,
        _pro(),
        'free',
        properties: firstOwnerProperties(1),
        rooms: rooms,
      );

      expect(find.text(_keptProperties), findsOneWidget);
      expect(find.text(_pickOneProperty), findsNothing);
      expect(isChecked(tester, 'Kos Melati'), isTrue);
      expect(find.text(_pickFifteenRooms), findsOneWidget);
      expect(rooms.calls, contains('list:p1'));
    });

    testWidgets('a single property with few rooms is submitted as it is', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openDirect(
        tester,
        subscriptions,
        'free',
        properties: FakePropertyRepository(
          properties: [makeProperty(id: 'p2', name: 'Kos Mawar', roomCount: 8)],
        ),
        rooms: _rooms(),
      );

      await _submit(tester);

      final call = subscriptions.scheduled.single;
      expect(call.planCode, PlanCode.free);
      expect(call.keptPropertyIds, ['p2']);
      expect(call.keptRoomIds, unorderedEquals(roomIds('p2', 8)));
    });

    testWidgets('a Basic owner can downgrade to Gratis too', (tester) async {
      final subscriptions = _basic();
      await _openDirect(tester, subscriptions, 'free', rooms: _rooms());
      await checkOnly(tester, propertyNames, ['Kos Mawar']);

      await _submit(tester);

      expect(subscriptions.scheduled.single.planCode, PlanCode.free);
    });
  });

  group('after saving', () {
    testWidgets('reloads the subscription after the downgrade is scheduled', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openFromSubscription(
        tester,
        subscriptions,
        'Turunkan ke Basic',
        properties: firstOwnerProperties(3),
      );

      await _submit(tester);

      expect(subscriptions.scheduleCalls, 1);
      expect(subscriptions.calls.last, 'subscription');
      expect(
        subscriptions.calls.indexOf('scheduleDowngrade'),
        lessThan(subscriptions.calls.lastIndexOf('subscription')),
      );
    });

    testWidgets('returns to the subscription screen with a SnackBar', (
      tester,
    ) async {
      await _openFromSubscription(
        tester,
        _pro(),
        'Turunkan ke Basic',
        properties: firstOwnerProperties(3),
      );

      await _submit(tester);

      expect(currentPath(tester), subscriptionPath);
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      expect(find.byType(DowngradeScreen), findsNothing);
      expect(snackBar(_scheduled), findsOneWidget);
    });

    testWidgets('the subscription screen then shows the scheduled downgrade', (
      tester,
    ) async {
      await _openFromSubscription(
        tester,
        _pro(),
        'Turunkan ke Basic',
        properties: firstOwnerProperties(3),
      );

      await _submit(tester);

      expect(
        find.text('Turun ke paket Basic mulai 16 Des 2026'),
        findsOneWidget,
      );
      expect(find.text('Batalkan penurunan paket'), findsOneWidget);
    });

    testWidgets('a downgrade to Gratis also returns with the SnackBar', (
      tester,
    ) async {
      final subscriptions = _basic();
      await _openFromSubscription(
        tester,
        subscriptions,
        'Turunkan ke Gratis',
        properties: firstOwnerProperties(1),
        rooms: _rooms(),
      );
      await checkOnly(tester, roomLabels(20), roomLabels(20).take(15).toList());

      await _submit(tester);

      expect(subscriptions.scheduled.single.keptRoomIds, hasLength(15));
      expect(currentPath(tester), subscriptionPath);
      expect(snackBar(_scheduled), findsOneWidget);
      expect(
        find.text('Turun ke paket Gratis mulai 16 Des 2026'),
        findsOneWidget,
      );
    });

    testWidgets('schedules exactly once', (tester) async {
      final subscriptions = _pro();
      await _openFromSubscription(
        tester,
        subscriptions,
        'Turunkan ke Basic',
        properties: firstOwnerProperties(3),
      );

      await _submit(tester);

      expect(subscriptions.scheduleCalls, 1);
      expect(subscriptions.cancelCalls, 0);
    });
  });

  group('Batal', () {
    testWidgets('goes back to the subscription screen and changes nothing', (
      tester,
    ) async {
      final subscriptions = _pro();
      await _openFromSubscription(tester, subscriptions, 'Turunkan ke Basic');

      await tap(tester, find.text('Batal'));

      expect(currentPath(tester), subscriptionPath);
      expect(find.byType(SubscriptionScreen), findsOneWidget);
      expect(find.byType(DowngradeScreen), findsNothing);
      _expectNoSchedule(subscriptions);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Kembali goes back too', (tester) async {
      await _openFromSubscription(tester, _pro(), 'Turunkan ke Basic');

      await pressBack(tester);

      expect(currentPath(tester), subscriptionPath);
    });
  });

  group('errors of the API', () {
    final cases = {
      'KEPT_PROPERTIES_INVALID':
          'Pilihan properti tidak sesuai dengan paket tujuan.',
      'KEPT_ROOMS_INVALID': 'Pilihan kamar tidak sesuai dengan paket tujuan.',
      'SUBSCRIPTION_NOT_A_DOWNGRADE':
          'Paket tujuan harus lebih rendah dari paket Anda saat ini.',
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} shows its text and keeps the page', (
        tester,
      ) async {
        final subscriptions = _pro()
          ..scheduleScript.always = ApiFailure(
            code: entry.key,
            statusCode: 422,
          );
        await _openDirect(
          tester,
          subscriptions,
          'basic',
          properties: firstOwnerProperties(3),
        );

        await _submit(tester);

        expect(find.text(entry.value), findsOneWidget);
        expect(currentPath(tester), '$subscriptionPath/turunkan');
        expect(find.text(_save), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(subscriptions.scheduleCalls, 1);
      });
    }

    testWidgets('any other code shows the mapped message', (tester) async {
      final subscriptions = _pro()
        ..scheduleScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _openDirect(
        tester,
        subscriptions,
        'basic',
        properties: firstOwnerProperties(3),
      );

      await _submit(tester);

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
    });

    testWidgets('a network failure shows its message', (tester) async {
      final subscriptions = _pro()
        ..scheduleScript.always = const ApiFailure.network();
      await _openDirect(
        tester,
        subscriptions,
        'basic',
        properties: firstOwnerProperties(3),
      );

      await _submit(tester);

      expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
    });

    testWidgets('an unknown code shows the generic message', (tester) async {
      final subscriptions = _pro()
        ..scheduleScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _openDirect(
        tester,
        subscriptions,
        'basic',
        properties: firstOwnerProperties(3),
      );

      await _submit(tester);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('the subscription is not reloaded after a failure', (
      tester,
    ) async {
      final subscriptions = _pro()
        ..scheduleScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _openDirect(
        tester,
        subscriptions,
        'basic',
        properties: firstOwnerProperties(3),
      );
      final before = subscriptions.subscriptionCalls;

      await _submit(tester);

      expect(subscriptions.subscriptionCalls, before);
    });

    testWidgets('the owner can save again after a failure', (tester) async {
      final subscriptions = _pro()
        ..scheduleScript.queue.add(const ApiFailure(code: 'INTERNAL_ERROR'));
      await _openFromSubscription(
        tester,
        subscriptions,
        'Turunkan ke Basic',
        properties: firstOwnerProperties(3),
      );
      await _submit(tester);
      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);

      await _submit(tester);

      expect(subscriptions.scheduleCalls, 2);
      expect(currentPath(tester), subscriptionPath);
      expect(snackBar(_scheduled), findsOneWidget);
    });

    testWidgets('keeps the choice of the owner after a failure', (
      tester,
    ) async {
      final subscriptions = _pro()
        ..scheduleScript.always = const ApiFailure(
          code: 'KEPT_PROPERTIES_INVALID',
        );
      await _openDirect(tester, subscriptions, 'basic');
      await checkOnly(tester, propertyNames, [
        'Kos Melati',
        'Kos Mawar',
        'Kos Dahlia',
      ]);

      await _submit(tester);

      expect(isChecked(tester, 'Kos Melati'), isTrue);
      expect(isChecked(tester, 'Kos Mawar'), isTrue);
      expect(isChecked(tester, 'Kos Anggrek'), isFalse);
      expect(isChecked(tester, 'Kos Dahlia'), isTrue);
    });
  });

  group('while saving', () {
    testWidgets('disables the button and shows progress', (tester) async {
      final subscriptions = _pro()..scheduleScript.gate = Completer<void>();
      await _openDirect(
        tester,
        subscriptions,
        'basic',
        properties: firstOwnerProperties(3),
      );

      await tester.ensureVisible(find.text(_save));
      await tester.tap(find.text(_save));
      await tester.pump();

      expectBusy(tester);
    });

    testWidgets('ignores a second tap', (tester) async {
      final subscriptions = _pro()..scheduleScript.gate = Completer<void>();
      await _openDirect(
        tester,
        subscriptions,
        'basic',
        properties: firstOwnerProperties(3),
      );
      await tester.ensureVisible(find.text(_save));
      await tester.tap(find.text(_save));
      await tester.pump();

      await tester.tap(busyButton(), warnIfMissed: false);
      await tester.pump();

      expect(subscriptions.scheduleCalls, 1);
    });

    testWidgets('returns to the subscription screen when saving is done', (
      tester,
    ) async {
      final gate = Completer<void>();
      final subscriptions = _pro()..scheduleScript.gate = gate;
      await _openFromSubscription(
        tester,
        subscriptions,
        'Turunkan ke Basic',
        properties: firstOwnerProperties(3),
      );
      await tester.ensureVisible(find.text(_save));
      await tester.tap(find.text(_save));
      await tester.pump();

      gate.complete();
      await tester.pumpAndSettle();

      expect(subscriptions.scheduleCalls, 1);
      expect(currentPath(tester), subscriptionPath);
      expect(snackBar(_scheduled), findsOneWidget);
    });

    testWidgets('enables the button again after a failure', (tester) async {
      final gate = Completer<void>();
      final subscriptions = _pro()
        ..scheduleScript.gate = gate
        ..scheduleScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _openDirect(
        tester,
        subscriptions,
        'basic',
        properties: firstOwnerProperties(3),
      );
      await tester.ensureVisible(find.text(_save));
      await tester.tap(find.text(_save));
      await tester.pump();

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.ancestor(of: find.text(_save), matching: anyButton()),
            )
            .onPressed,
        isNotNull,
      );
    });
  });

  group('accessibility', () {
    final states =
        <
          String,
          ({
            FakeSubscriptionRepository Function() subscriptions,
            String plan,
            FakePropertyRepository Function() properties,
            Future<void> Function(WidgetTester) prepare,
          })
        >{
          'properties to choose for Basic': (
            subscriptions: _pro,
            plan: 'basic',
            properties: ownerPropertiesForPlans,
            prepare: (tester) async {},
          ),
          'every property selected for Basic': (
            subscriptions: _pro,
            plan: 'basic',
            properties: () => firstOwnerProperties(3),
            prepare: (tester) async {},
          ),
          'a wrong property count for Basic': (
            subscriptions: _pro,
            plan: 'basic',
            properties: ownerPropertiesForPlans,
            prepare: (tester) async {
              await checkOnly(tester, propertyNames, ['Kos Melati']);
              await _submit(tester);
            },
          ),
          'rooms to choose for Gratis': (
            subscriptions: _pro,
            plan: 'free',
            properties: ownerPropertiesForPlans,
            prepare: (tester) async {
              await checkOnly(tester, propertyNames, ['Kos Melati']);
            },
          ),
          'a wrong room count for Gratis': (
            subscriptions: _pro,
            plan: 'free',
            properties: ownerPropertiesForPlans,
            prepare: (tester) async {
              await checkOnly(tester, propertyNames, ['Kos Melati']);
              await checkOnly(tester, roomLabels(20), []);
              await _submit(tester);
            },
          ),
          'an error of the API': (
            subscriptions: () => _pro()
              ..scheduleScript.always = const ApiFailure(
                code: 'KEPT_ROOMS_INVALID',
              ),
            plan: 'basic',
            properties: () => firstOwnerProperties(3),
            prepare: (tester) async {
              await _submit(tester);
            },
          ),
          'a free subscription': (
            subscriptions: FakeSubscriptionRepository.new,
            plan: 'basic',
            properties: ownerPropertiesForPlans,
            prepare: (tester) async {},
          ),
        };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines with ${entry.key}', (tester) async {
        await _openDirect(
          tester,
          entry.value.subscriptions(),
          entry.value.plan,
          properties: entry.value.properties(),
          rooms: _rooms(),
        );
        await entry.value.prepare(tester);

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text with ${entry.key}', (tester) async {
        await _openDirect(
          tester,
          entry.value.subscriptions(),
          entry.value.plan,
          properties: entry.value.properties(),
          rooms: _rooms(),
          largeText: true,
        );
        await entry.value.prepare(tester);

        expect(tester.takeException(), isNull);
        expect(find.byType(DowngradeScreen), findsOneWidget);
      });
    }

    testWidgets('meets the guidelines while loading', (tester) async {
      final subscriptions = _pro()..subscriptionScript.gate = Completer<void>();
      await _openDirect(tester, subscriptions, 'basic', settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a failure', (tester) async {
      final subscriptions = _pro()
        ..subscriptionScript.always = const ApiFailure.network();
      await _openDirect(tester, subscriptions, 'basic');

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text with a failure', (tester) async {
      final subscriptions = _pro()
        ..subscriptionScript.always = const ApiFailure.network();
      await _openDirect(tester, subscriptions, 'basic', largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorView), findsOneWidget);
    });

    testWidgets('fits at large text while saving', (tester) async {
      final subscriptions = _pro()..scheduleScript.gate = Completer<void>();
      await _openDirect(
        tester,
        subscriptions,
        'basic',
        properties: firstOwnerProperties(3),
        largeText: true,
      );
      await tester.ensureVisible(find.text(_save));
      await tester.tap(find.text(_save));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the checkboxes expose their state and a target of 48 dp', (
      tester,
    ) async {
      await _openDirect(tester, _pro(), 'basic');
      await setChecked(tester, 'Kos Melati', true);
      await setChecked(tester, 'Kos Mawar', false);

      final handle = tester.ensureSemantics();
      try {
        final checked = tester.getSemantics(tileOf('Kos Melati'));
        final unchecked = tester.getSemantics(tileOf('Kos Mawar'));
        expect(checked, isSemantics(hasCheckedState: true, isChecked: true));
        expect(unchecked, isSemantics(hasCheckedState: true, isChecked: false));
        expect(checked.label, contains('Kos Melati'));
        expect(checked.rect.height, greaterThanOrEqualTo(48));
      } finally {
        handle.dispose();
      }
    });
  });
}
