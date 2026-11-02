import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/router.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'cash_payment_ui_helpers.dart';

Uri _uri(WidgetTester tester) => currentUri(tester);

void main() {
  setUpAll(initializeIndonesianDates);

  group('entry on the payment overview', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('is offered to a $role', (tester) async {
        await pumpReview(tester, cashRepositories(), role: role);

        expect(actionButton(cashLabel), findsOneWidget);
      });
    }

    testWidgets('sits next to the entry for awaiting verification', (
      tester,
    ) async {
      await pumpReview(tester, cashRepositories());

      expect(actionButton(cashLabel), findsOneWidget);
      expect(verificationEntry(), findsOneWidget);
    });

    testWidgets('has a target of at least 48 dp', (tester) async {
      await pumpReview(tester, cashRepositories());

      expectTargetSize(tester, cashLabel);
    });

    testWidgets('opens the page of the property shown', (tester) async {
      await openCashFlow(tester);

      expect(_uri(tester).path, '/pembayaran/tunai');
      expect(_uri(tester).queryParameters['properti'], 'p1');
      expect(_uri(tester).queryParameters.containsKey('tagihan'), isFalse);
      expect(inAppBar(cashLabel), findsOneWidget);
    });

    testWidgets('opens the page of the property that was chosen', (
      tester,
    ) async {
      await pumpReview(tester, cashRepositories());
      await chooseProperty(tester, current: 'Kos Melati', target: 'Kos Mawar');

      await press(tester, actionButton(cashLabel));

      expect(_uri(tester).queryParameters['properti'], 'p2');
      expect(find.text('Lina'), findsOneWidget);
      expect(find.text('Rina Putri'), findsNothing);
    });

    testWidgets('opens a page that covers the bottom navigation bar', (
      tester,
    ) async {
      await pumpReview(tester, cashRepositories());
      expect(find.byType(NavigationBar), findsOneWidget);

      await press(tester, actionButton(cashLabel));

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Kembali returns to the overview and sends nothing', (
      tester,
    ) async {
      final repos = await openCashFlow(tester);

      await pressBack(tester);

      expect(_uri(tester).path, overviewPath);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(repos.management.cashCalls, 0);
    });

    testWidgets('stays offered when the overview of the day fails to load', (
      tester,
    ) async {
      final repos = cashRepositories();
      repos.management.overviewScript.always = const ApiFailure.network();

      await pumpReview(tester, repos);

      expect(find.text('Coba lagi'), findsOneWidget);
      expect(actionButton(cashLabel), findsOneWidget);
    });

    testWidgets('stays offered when the property has no tenants', (
      tester,
    ) async {
      final repos = (
        management: FakeManagementRentBillRepository(
          items: {'p1': <PaymentOverviewItem>[], 'p2': mawarItems()},
        ),
        rentBills: FakeRentBillRepository(),
      );

      await pumpReview(tester, repos);

      expect(actionButton(cashLabel), findsOneWidget);
    });

    testWidgets('is not offered while the properties load', (tester) async {
      final properties = twoProperties();
      properties.listScript.gate = Completer<void>();

      await pumpReview(
        tester,
        cashRepositories(),
        properties: properties,
        settle: false,
      );

      expect(actionButton(cashLabel), findsNothing);
    });

    testWidgets('is not offered when the properties fail to load', (
      tester,
    ) async {
      final properties = twoProperties();
      properties.listScript.always = const ApiFailure.network();

      await pumpReview(tester, cashRepositories(), properties: properties);

      expect(actionButton(cashLabel), findsNothing);
    });

    testWidgets('is not offered when there is no property', (tester) async {
      await pumpReview(
        tester,
        cashRepositories(),
        properties: FakePropertyRepository(properties: []),
      );

      expect(actionButton(cashLabel), findsNothing);
    });
  });

  group('the page of the flow', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('opens for a $role from a link', (tester) async {
        await pumpReview(
          tester,
          cashRepositories(),
          role: role,
          path: cashPath('p1'),
        );

        expect(_uri(tester).path, '/pembayaran/tunai');
        expect(inAppBar(cashLabel), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      });
    }

    testWidgets('says the property is missing without a property in the link', (
      tester,
    ) async {
      await pumpReview(tester, cashRepositories(), path: '/pembayaran/tunai');

      expect(inAppBar(cashLabel), findsOneWidget);
      expect(find.text('Properti tidak ditemukan.'), findsOneWidget);
      expect(find.text('Rina Putri'), findsNothing);
    });

    const location = '/pembayaran/tunai';
    const verifiedIn = SignedIn(role: UserRole.owner, emailVerified: true);

    test('is allowed for an Owner', () {
      expect(redirectFor(verifiedIn, location), isNull);
    });

    test('is allowed for a Manager', () {
      expect(
        redirectFor(
          const SignedIn(role: UserRole.manager, emailVerified: true),
          location,
        ),
        isNull,
      );
    });

    test('sends a Tenant to the tenant home', () {
      expect(
        redirectFor(
          const SignedIn(role: UserRole.tenant, emailVerified: true),
          location,
        ),
        '/penyewa/beranda',
      );
    });

    test('sends an Admin to the admin page', () {
      expect(
        redirectFor(
          const SignedIn(role: UserRole.admin, emailVerified: true),
          location,
        ),
        '/admin',
      );
    });

    test('sends a signed-out user to the sign-in page', () {
      expect(redirectFor(const SignedOut(), location), '/masuk');
    });

    test('sends a user without a verified email to the verification', () {
      expect(
        redirectFor(
          const SignedIn(role: UserRole.owner, emailVerified: false),
          location,
        ),
        '/verifikasi-email',
      );
    });

    test('waits for the session to load', () {
      expect(redirectFor(const SessionLoading(), location), '/memuat');
    });
  });

  group('action on the bill', () {
    for (final role in [UserRole.owner, UserRole.manager]) {
      testWidgets('is offered to a $role on an unpaid bill', (tester) async {
        await pumpReview(
          tester,
          cashRepositories(),
          role: role,
          path: billPath('b1'),
        );

        expect(statusBadge('Belum Bayar'), findsOneWidget);
        expect(actionButton(cashLabel), findsOneWidget);
      });
    }

    testWidgets('is offered on a rejected bill', (tester) async {
      await pumpReview(tester, cashRepositories(), path: billPath('b3'));

      expect(statusBadge('Ditolak'), findsWidgets);
      expect(actionButton(cashLabel), findsOneWidget);
    });

    testWidgets('comes without the review actions', (tester) async {
      await pumpReview(tester, cashRepositories(), path: billPath('b1'));

      expectNoReviewActions();
    });

    testWidgets('is not offered on a bill awaiting verification', (
      tester,
    ) async {
      await pumpReview(tester, cashRepositories(), path: billPath('b2'));

      expect(statusBadge('Menunggu Verifikasi'), findsOneWidget);
      expect(actionButton(cashLabel), findsNothing);
    });

    testWidgets('is not offered on a bill paid in cash', (tester) async {
      await pumpReview(tester, cashRepositories(), path: billPath('b4'));

      expect(statusBadge('Lunas'), findsWidgets);
      expect(actionButton(cashLabel), findsNothing);
    });

    testWidgets('is not offered on a bill paid by transfer', (tester) async {
      final repos = cashRepositories(
        bills: [
          makeRentBill(
            id: 'b9',
            status: PaymentStatus.paid,
            method: PaymentMethod.transfer,
            paidOn: DateTime.utc(2026, 11, 4),
          ),
        ],
      );

      await pumpReview(tester, repos, path: billPath('b9'));

      expect(statusBadge('Lunas'), findsWidgets);
      expect(actionButton(cashLabel), findsNothing);
    });

    testWidgets('is not offered while the bill loads', (tester) async {
      final repos = cashRepositories();
      repos.rentBills.getScript.gate = Completer<void>();

      await pumpReview(tester, repos, path: billPath('b1'), settle: false);

      expect(actionButton(cashLabel), findsNothing);
    });

    testWidgets('is not offered when the bill fails to load', (tester) async {
      final repos = cashRepositories();
      repos.rentBills.getScript.always = const ApiFailure.network();

      await pumpReview(tester, repos, path: billPath('b1'));

      expect(actionButton(cashLabel), findsNothing);
    });

    testWidgets('has a target of at least 48 dp', (tester) async {
      await pumpReview(tester, cashRepositories(), path: billPath('b1'));

      expectTargetSize(tester, cashLabel);
    });

    testWidgets('opens the flow of that bill', (tester) async {
      await openCashFlowFromBill(tester, 'b1');

      expect(_uri(tester).path, '/pembayaran/tunai');
      expect(_uri(tester).queryParameters['properti'], 'p1');
      expect(_uri(tester).queryParameters['tagihan'], 'b1');
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('opens the flow with the property of the bill', (tester) async {
      await openCashFlowFromBill(tester, 'c2');

      expect(_uri(tester).queryParameters['properti'], 'p2');
      expect(_uri(tester).queryParameters['tagihan'], 'c2');
    });

    testWidgets('Kembali returns to the bill and sends nothing', (
      tester,
    ) async {
      final repos = await openCashFlowFromBill(tester, 'b1');

      await pressBack(tester);

      expect(_uri(tester).path, billPath('b1'));
      expect(statusBadge('Belum Bayar'), findsOneWidget);
      expect(actionButton(cashLabel), findsOneWidget);
      expect(repos.management.cashCalls, 0);
    });
  });

  group('accessibility of the entries', () {
    final states = <String, Future<void> Function(WidgetTester, bool)>{
      'the overview': (tester, large) async {
        await pumpReview(tester, cashRepositories(), largeText: large);
      },
      'an unpaid bill': (tester, large) async {
        await pumpReview(
          tester,
          cashRepositories(),
          path: billPath('b1'),
          largeText: large,
        );
      },
      'a rejected bill': (tester, large) async {
        await pumpReview(
          tester,
          cashRepositories(),
          path: billPath('b3'),
          largeText: large,
        );
      },
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines on ${entry.key}', (tester) async {
        await entry.value(tester, false);

        expect(actionButton(cashLabel), findsOneWidget);
        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text size on ${entry.key}', (tester) async {
        await entry.value(tester, true);

        expect(tester.takeException(), isNull);
        expect(actionButton(cashLabel), findsOneWidget);
      });
    }
  });
}
