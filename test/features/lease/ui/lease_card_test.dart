import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/lease/ui/lease_card.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../auth/ui/auth_ui_helpers.dart';

const _akunPath = '/penyewa/akun';
const _heading = 'Kamar & masa sewa';
const _retry = 'Coba lagi';

/// Shows the app signed in as a tenant on the Akun tab, with [leases] behind
/// the lease card.
///
/// With [settle] false only a few frames are pumped, so a held gate keeps the
/// card in its loading state. With [largeText] the display is 360 x 640 dp at
/// text scale 2.0 and the test fails on any overflow.
Future<void> pumpLeaseApp(
  WidgetTester tester,
  FakeLeaseRepository leases, {
  UserRole role = UserRole.tenant,
  String path = _akunPath,
  Future<void> Function()? logout,
  bool settle = true,
  bool largeText = false,
}) async {
  final app = buildTestApp(
    store: InMemorySessionStore(storedSession(role: role)),
    leases: leases,
    logout: logout,
  );
  if (largeText) {
    await pumpAtLargeText(tester, app);
  } else {
    useTallScreen(tester);
    await tester.pumpWidget(app);
  }
  // A held request keeps a spinner on the landing page, which never settles.
  Future<void> pumpFrames() async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  if (settle) {
    await tester.pumpAndSettle();
    goTo(tester, path);
    await tester.pumpAndSettle();
  } else {
    await pumpFrames();
    goTo(tester, path);
    await pumpFrames();
  }
}

Finder _inCard(Finder matching, {bool skipOffstage = true}) => find.descendant(
  of: find.byType(LeaseCard),
  matching: matching,
  skipOffstage: skipOffstage,
);

Finder _textInCard(String text) => _inCard(find.text(text));

void main() {
  group('with an active lease', () {
    testWidgets('shows the card on the tenant Akun tab', (tester) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
      );

      expect(currentPath(tester), _akunPath);
      expect(find.byType(LeaseCard), findsOneWidget);
    });

    testWidgets('fetches the lease once', (tester) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease());
      await pumpLeaseApp(tester, leases);

      expect(leases.calls, 1);
    });

    testWidgets('shows the heading, announced as a header', (tester) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
      );

      expect(_textInCard(_heading), findsOneWidget);
      final handle = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(_textInCard(_heading)),
          isSemantics(isHeader: true),
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('shows the property name, room number and address', (
      tester,
    ) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
      );

      expect(_textInCard('Kos Melati'), findsOneWidget);
      expect(_textInCard('Kamar 08'), findsOneWidget);
      expect(_textInCard('Jl. Melati 1, Bandung'), findsOneWidget);
    });

    testWidgets('shows the start and end dates', (tester) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
      );

      expect(_textInCard('1 Jan 2026 - 31 Des 2026'), findsOneWidget);
    });

    testWidgets('shows other dates in the same format', (tester) async {
      final lease = makeCurrentLease(
        startDate: DateTime.utc(2026, 10, 18),
        endDate: DateTime.utc(2027, 5, 9),
      );
      await pumpLeaseApp(tester, FakeLeaseRepository(lease: lease));

      expect(_textInCard('18 Okt 2026 - 9 Mei 2027'), findsOneWidget);
    });

    testWidgets('shows a lease without an end date as open ended', (
      tester,
    ) async {
      final lease = makeCurrentLease(noEndDate: true);
      await pumpLeaseApp(tester, FakeLeaseRepository(lease: lease));

      expect(_textInCard('1 Jan 2026 - Tanpa batas'), findsOneWidget);
    });

    testWidgets('shows a lease without a start date as not yet set', (
      tester,
    ) async {
      final lease = makeCurrentLease(noStartDate: true);
      await pumpLeaseApp(tester, FakeLeaseRepository(lease: lease));

      expect(_textInCard('Belum ditentukan - 31 Des 2026'), findsOneWidget);
    });

    testWidgets('shows a lease without dates and never prints null', (
      tester,
    ) async {
      final lease = makeCurrentLease(noStartDate: true, noEndDate: true);
      await pumpLeaseApp(tester, FakeLeaseRepository(lease: lease));

      expect(_textInCard('Belum ditentukan - Tanpa batas'), findsOneWidget);
      expect(_inCard(find.textContaining('null')), findsNothing);
    });

    testWidgets('shows the rent per month', (tester) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
      );

      expect(_textInCard('Rp750.000 / bulan'), findsOneWidget);
    });

    const units = {
      BillingCycle.weekly: 'minggu',
      BillingCycle.monthly: 'bulan',
      BillingCycle.quarterly: '3 bulan',
      BillingCycle.semiannual: '6 bulan',
      BillingCycle.annual: '12 bulan',
    };
    for (final entry in units.entries) {
      testWidgets('shows the rent per ${entry.value} for ${entry.key.value}', (
        tester,
      ) async {
        final lease = makeCurrentLease(billingCycle: entry.key, rent: 2100000);
        await pumpLeaseApp(tester, FakeLeaseRepository(lease: lease));

        expect(_textInCard('Rp2.100.000 / ${entry.value}'), findsOneWidget);
      });
    }

    testWidgets('shows the dimensions with a decimal comma', (tester) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
      );

      expect(_textInCard('3,5 × 4 m'), findsOneWidget);
    });

    testWidgets('shows no dimensions when there are none', (tester) async {
      final lease = makeCurrentLease(noDimensions: true);
      await pumpLeaseApp(tester, FakeLeaseRepository(lease: lease));

      expect(_inCard(find.textContaining('×')), findsNothing);
      expect(
        _inCard(
          find.byWidgetPredicate(
            (w) => w is Text && RegExp(r'\d\s*m$').hasMatch(w.data ?? ''),
          ),
        ),
        findsNothing,
      );
      expect(_textInCard('Rp750.000 / bulan'), findsOneWidget);
    });

    testWidgets('shows no dimensions when only the length is known', (
      tester,
    ) async {
      final lease = makeCurrentLease(lengthM: 3.5, widthM: null);
      await pumpLeaseApp(tester, FakeLeaseRepository(lease: lease));

      expect(_inCard(find.textContaining('×')), findsNothing);
    });

    testWidgets('shows no dimensions when only the width is known', (
      tester,
    ) async {
      final lease = makeCurrentLease(lengthM: null, widthM: 4);
      await pumpLeaseApp(tester, FakeLeaseRepository(lease: lease));

      expect(_inCard(find.textContaining('×')), findsNothing);
    });

    testWidgets('shows every facility', (tester) async {
      final lease = makeCurrentLease(
        facilities: ['wifi', 'kamar mandi dalam', 'kasur'],
      );
      await pumpLeaseApp(tester, FakeLeaseRepository(lease: lease));

      expect(_inCard(find.textContaining('wifi')), findsOneWidget);
      expect(_inCard(find.textContaining('kamar mandi dalam')), findsOneWidget);
      expect(_inCard(find.textContaining('kasur')), findsOneWidget);
    });

    testWidgets('shows no facilities section for an empty list', (
      tester,
    ) async {
      final lease = makeCurrentLease(facilities: const []);
      await pumpLeaseApp(tester, FakeLeaseRepository(lease: lease));

      expect(_inCard(find.textContaining('Fasilitas')), findsNothing);
      expect(_textInCard('Kos Melati'), findsOneWidget);
    });

    testWidgets('shows neither the empty message nor an error', (tester) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
      );

      expect(_inCard(find.textContaining('Hubungi')), findsNothing);
      expect(_inCard(find.byType(ErrorView)), findsNothing);
      expect(_inCard(find.byType(CircularProgressIndicator)), findsNothing);
    });

    testWidgets('shows only Indonesian copy for the structure', (tester) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
      );

      for (final english in ['Lease', 'Room', 'Tenant', 'Facilities']) {
        expect(_inCard(find.textContaining(english)), findsNothing);
      }
    });

    testWidgets('sits above the Keluar button', (tester) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
      );

      expect(
        tester.getRect(find.byType(LeaseCard)).bottom,
        lessThanOrEqualTo(tester.getTopLeft(find.text('Keluar')).dy),
      );
    });

    testWidgets('keeps the Akun header and the Keluar button', (tester) async {
      var logouts = 0;
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
        logout: () async => logouts++,
      );

      expect(find.text('Akun'), findsWidgets);
      await tester.tap(find.text('Keluar'));
      await tester.pump();

      expect(logouts, 1);
    });
  });

  group('without a lease', () {
    testWidgets('tells the tenant to contact management', (tester) async {
      await pumpLeaseApp(tester, FakeLeaseRepository());

      expect(_textInCard(_heading), findsOneWidget);
      expect(
        _inCard(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data ?? '').toLowerCase().contains('hubungi pengelola'),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows no lease field', (tester) async {
      await pumpLeaseApp(tester, FakeLeaseRepository());

      expect(_inCard(find.textContaining('Rp')), findsNothing);
      expect(
        _inCard(
          find.byWidgetPredicate(
            (w) => w is Text && RegExp(r'^Kamar \d').hasMatch(w.data ?? ''),
          ),
        ),
        findsNothing,
      );
      expect(_inCard(find.textContaining('×')), findsNothing);
      expect(_inCard(find.textContaining('null')), findsNothing);
      expect(_inCard(find.byType(ErrorView)), findsNothing);
      expect(_inCard(find.byType(CircularProgressIndicator)), findsNothing);
    });

    testWidgets('keeps the Keluar button', (tester) async {
      await pumpLeaseApp(tester, FakeLeaseRepository());

      expect(find.text('Keluar'), findsOneWidget);
    });
  });

  group('while loading', () {
    testWidgets('shows a progress indicator labelled Memuat', (tester) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.gate = Completer<void>();
      await pumpLeaseApp(tester, leases, settle: false);

      expect(_inCard(find.byType(CircularProgressIndicator)), findsOneWidget);
      final handle = tester.ensureSemantics();
      try {
        expect(find.bySemanticsLabel('Memuat'), findsAtLeastNWidgets(1));
      } finally {
        handle.dispose();
      }
      expect(_textInCard('Kos Melati'), findsNothing);
      expect(_inCard(find.textContaining('Hubungi')), findsNothing);
    });

    testWidgets('shows the lease once loading finishes', (tester) async {
      final gate = Completer<void>();
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.gate = gate;
      await pumpLeaseApp(tester, leases, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(_textInCard('Kos Melati'), findsOneWidget);
      expect(_inCard(find.byType(CircularProgressIndicator)), findsNothing);
    });

    testWidgets('shows the empty message once loading finishes', (
      tester,
    ) async {
      final gate = Completer<void>();
      final leases = FakeLeaseRepository()..script.gate = gate;
      await pumpLeaseApp(tester, leases, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(_inCard(find.byType(CircularProgressIndicator)), findsNothing);
      expect(_inCard(find.textContaining('Hubungi')), findsOneWidget);
    });

    testWidgets('keeps the Keluar button usable', (tester) async {
      var logouts = 0;
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.gate = Completer<void>();
      await pumpLeaseApp(
        tester,
        leases,
        settle: false,
        logout: () async => logouts++,
      );

      await tester.tap(find.text('Keluar'));
      await tester.pump();

      expect(logouts, 1);
    });
  });

  group('when loading fails', () {
    testWidgets('shows the Indonesian message of the failure and a retry', (
      tester,
    ) async {
      final leases = FakeLeaseRepository()
        ..script.always = const ApiFailure.network();
      await pumpLeaseApp(tester, leases);

      expect(_inCard(find.byType(ErrorView)), findsOneWidget);
      expect(_textInCard(messageOfCode('NETWORK_ERROR')), findsOneWidget);
      expect(
        messageOfCode('NETWORK_ERROR'),
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
      expect(_textInCard(_retry), findsOneWidget);
      expect(_textInCard('Kos Melati'), findsNothing);
      expect(_inCard(find.textContaining('Hubungi')), findsNothing);
    });

    testWidgets('maps a server error to its Indonesian message', (
      tester,
    ) async {
      final leases = FakeLeaseRepository()
        ..script.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await pumpLeaseApp(tester, leases);

      expect(
        _textInCard('Terjadi kesalahan pada server. Coba lagi.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final leases = FakeLeaseRepository()
        ..script.always = const ApiFailure(code: 'SOMETHING_NEW');
      await pumpLeaseApp(tester, leases);

      expect(_textInCard('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('does not retry in the background', (tester) async {
      final leases = FakeLeaseRepository()
        ..script.always = const ApiFailure.network();
      await pumpLeaseApp(tester, leases);

      await tester.pump(const Duration(seconds: 30));

      expect(leases.calls, 1);
    });

    testWidgets('fetches again and shows the lease when retry is tapped', (
      tester,
    ) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.queue.add(const ApiFailure.network());
      await pumpLeaseApp(tester, leases);
      expect(_inCard(find.byType(ErrorView)), findsOneWidget);

      await tester.tap(_textInCard(_retry));
      await tester.pumpAndSettle();

      expect(leases.calls, 2);
      expect(_inCard(find.byType(ErrorView)), findsNothing);
      expect(_textInCard('Kos Melati'), findsOneWidget);
    });

    testWidgets('shows the empty message when retry finds no lease', (
      tester,
    ) async {
      final leases = FakeLeaseRepository()
        ..script.queue.add(const ApiFailure.network());
      await pumpLeaseApp(tester, leases);

      await tester.tap(_textInCard(_retry));
      await tester.pumpAndSettle();

      expect(_inCard(find.byType(ErrorView)), findsNothing);
      expect(_inCard(find.textContaining('Hubungi')), findsOneWidget);
    });

    testWidgets('shows the error again when retry fails again', (tester) async {
      final leases = FakeLeaseRepository()
        ..script.always = const ApiFailure.network();
      await pumpLeaseApp(tester, leases);

      await tester.tap(_textInCard(_retry));
      await tester.pumpAndSettle();

      expect(leases.calls, 2);
      expect(_inCard(find.byType(ErrorView)), findsOneWidget);
    });

    testWidgets('shows a progress indicator while retrying', (tester) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.queue.add(const ApiFailure.network());
      await pumpLeaseApp(tester, leases);
      leases.script.gate = Completer<void>();

      await tester.tap(_textInCard(_retry));
      await tester.pump();

      expect(_inCard(find.byType(CircularProgressIndicator)), findsOneWidget);
      expect(_inCard(find.byType(ErrorView)), findsNothing);
    });

    testWidgets('keeps the Keluar button usable', (tester) async {
      var logouts = 0;
      final leases = FakeLeaseRepository()
        ..script.always = const ApiFailure.network();
      await pumpLeaseApp(tester, leases, logout: () async => logouts++);

      await tester.tap(find.text('Keluar'));
      await tester.pump();

      expect(logouts, 1);
    });
  });

  group('accessibility', () {
    testWidgets('meets the guidelines with an active lease', (tester) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
      );

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines with a lease that has no extras', (
      tester,
    ) async {
      final lease = makeCurrentLease(
        noStartDate: true,
        noEndDate: true,
        noDimensions: true,
        facilities: const [],
      );
      await pumpLeaseApp(tester, FakeLeaseRepository(lease: lease));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines without a lease', (tester) async {
      await pumpLeaseApp(tester, FakeLeaseRepository());

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.gate = Completer<void>();
      await pumpLeaseApp(tester, leases, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines after an error', (tester) async {
      final leases = FakeLeaseRepository()
        ..script.always = const ApiFailure.network();
      await pumpLeaseApp(tester, leases);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('reads the card content before the Keluar button', (
      tester,
    ) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
      );

      expect(
        tester.getTopLeft(_textInCard(_heading)).dy,
        lessThan(tester.getTopLeft(find.text('Keluar')).dy),
      );
    });
  });

  group('at large text size', () {
    testWidgets('fits an active lease', (tester) async {
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: makeCurrentLease()),
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Kos Melati', skipOffstage: false), findsOneWidget);
    });

    testWidgets('fits a lease with long text', (tester) async {
      final lease = makeCurrentLease(
        propertyName: 'Kos Melati Indah Permai Sejahtera Bersama Selamanya',
        address:
            'Jalan Raya Melati Nomor 123 RT 04 RW 05 Kelurahan Sukamaju '
            'Kecamatan Cibeunying Kidul Kota Bandung Jawa Barat 40121',
        roomNumber: 'A-12 Lantai Dua Sayap Timur',
        facilities: [
          for (var i = 1; i <= 15; i++) 'fasilitas panjang nomor $i abcdefg',
        ],
      );
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: lease),
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('Cibeunying Kidul', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('fasilitas panjang nomor 15', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('fits a lease without dates, dimensions and facilities', (
      tester,
    ) async {
      final lease = makeCurrentLease(
        noStartDate: true,
        noEndDate: true,
        noDimensions: true,
        facilities: const [],
      );
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: lease),
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits the empty message', (tester) async {
      await pumpLeaseApp(tester, FakeLeaseRepository(), largeText: true);

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits the error with its retry button', (tester) async {
      final leases = FakeLeaseRepository()
        ..script.always = const ApiFailure.network();
      await pumpLeaseApp(tester, leases, largeText: true);

      expect(tester.takeException(), isNull);
      expect(
        _inCard(find.text(_retry, skipOffstage: false), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('fits the loading state', (tester) async {
      final leases = FakeLeaseRepository(lease: makeCurrentLease())
        ..script.gate = Completer<void>();
      await pumpLeaseApp(tester, leases, largeText: true, settle: false);

      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the Keluar button reachable by scrolling', (
      tester,
    ) async {
      final lease = makeCurrentLease(
        facilities: [for (var i = 1; i <= 15; i++) 'fasilitas panjang $i'],
      );
      await pumpLeaseApp(
        tester,
        FakeLeaseRepository(lease: lease),
        largeText: true,
      );

      await tester.scrollUntilVisible(
        find.text('Keluar'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Keluar'), findsOneWidget);
    });
  });
}
