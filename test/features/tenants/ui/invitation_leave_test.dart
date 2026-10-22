import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_list_screen.dart';
import 'package:niscala/features/tenants/ui/invitation_qr_screen.dart';
import 'package:niscala/features/tenants/ui/invitation_share_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_detail_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_form_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_list_screen.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import '../../../helpers/transitions.dart';
import 'tenant_ui_helpers.dart';

const _tick = Duration(milliseconds: 100);
const _list = '/properti/p1/penyewa';

FakeTenantRepository _repo() => FakeTenantRepository(tenants: sampleTenants());

Finder get _share => find.byType(InvitationShareScreen);
Finder get _qr => find.byType(InvitationQrScreen);
Finder get _tenantList => find.byType(TenantListScreen);

/// Taps [finder] without waiting for the page transition to finish.
Future<void> _tapNow(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
}

/// Adds a tenant through the form, which ends on the share screen.
Future<void> _createTenant(WidgetTester tester, {String query = ''}) async {
  await pumpTenantApp(tester, _repo(), path: '$_list/tambah$query');
  await choose(tester, 'Kamar (wajib)', 'Kamar 09');
  await typeInto(tester, 'Nama lengkap (wajib)', 'Rina Putri');
  await typeInto(tester, 'Nomor telepon (wajib)', '0812-5520-4471');
  await tapVisible(tester, find.text('Simpan Penyewa'));
}

/// A way to arrive on an invitation screen.
typedef _Entrance = ({
  String name,
  Future<void> Function(WidgetTester) show,
  Finder page,
});

/// A way to leave the invitation screen that [page] finds.
typedef _Exit = ({String name, Future<void> Function(WidgetTester) leave});

final _shareEntrances = <_Entrance>[
  (
    name: 'a link to the share screen',
    show: (tester) =>
        pumpTenantApp(tester, _repo(), path: '$_list/t2/undangan'),
    page: _share,
  ),
  (
    name: 'a link to the share screen of a new tenant',
    show: (tester) =>
        pumpTenantApp(tester, _repo(), path: '$_list/t2/undangan?baru=1'),
    page: _share,
  ),
  (name: 'adding a tenant', show: _createTenant, page: _share),
  (
    name: 'adding a tenant for a chosen room',
    show: (tester) => _createTenant(tester, query: '?kamar=r2'),
    page: _share,
  ),
];

final _shareExits = <_Exit>[
  (name: 'Selesai', leave: (tester) => _tapNow(tester, find.text('Selesai'))),
  (
    name: 'the close button',
    leave: (tester) => _tapNow(tester, find.byTooltip('Tutup')),
  ),
];

final _qrEntrances = <_Entrance>[
  (
    name: 'a link to the QR screen',
    show: (tester) =>
        pumpTenantApp(tester, _repo(), path: '$_list/t2/undangan/qr'),
    page: _qr,
  ),
  (
    name: 'the share screen',
    show: (tester) async {
      await pumpTenantApp(tester, _repo(), path: '$_list/t2/undangan');
      await tapVisible(tester, find.text('Tampilkan kode QR'));
    },
    page: _qr,
  ),
  (
    name: 'adding a tenant and then the share screen',
    show: (tester) async {
      await _createTenant(tester);
      await tapVisible(tester, find.text('Tampilkan kode QR'));
    },
    page: _qr,
  ),
];

final _qrExits = <_Exit>[
  (name: 'Tutup', leave: (tester) => _tapNow(tester, find.text('Tutup'))),
];

/// Every screen of the invitation flow that closes to the tenant list.
final _cases = <({_Entrance entrance, _Exit exit})>[
  for (final entrance in _shareEntrances)
    for (final exit in _shareExits) (entrance: entrance, exit: exit),
  for (final entrance in _qrEntrances)
    for (final exit in _qrExits) (entrance: entrance, exit: exit),
];

/// The paths reached by pressing the system back button until the app stays.
Future<List<String>> _backPaths(WidgetTester tester) async {
  final paths = <String>[];
  for (var i = 0; i < 6; i++) {
    final before = currentPath(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final after = currentPath(tester);
    if (after == before) break;
    paths.add(after);
  }
  return paths;
}

void main() {
  for (final c in _cases) {
    group('${c.exit.name} after ${c.entrance.name}', () {
      final page = c.entrance.page;

      testWidgets('slides the page out to the right', (tester) async {
        await c.entrance.show(tester);
        expect(page, findsOneWidget);

        await c.exit.leave(tester);
        await tester.pump();
        await tester.pump(_tick);

        expectMidSlide(tester, page);
      });

      testWidgets('keeps moving the page to the right while it leaves', (
        tester,
      ) async {
        await c.entrance.show(tester);

        await c.exit.leave(tester);
        await tester.pump();
        await tester.pump(_tick);
        final early = leftOf(tester, page);
        await tester.pump(_tick);

        expect(leftOf(tester, page), greaterThan(early));
      });

      testWidgets('ends on the tenant list at rest', (tester) async {
        await c.entrance.show(tester);

        await c.exit.leave(tester);
        await tester.pumpAndSettle();

        expect(currentPath(tester), _list);
        expect(_tenantList, findsOneWidget);
        expectAtRest(tester, _tenantList);
        expect(_share, findsNothing);
        expect(_qr, findsNothing);
        expect(find.byType(TenantDetailScreen), findsNothing);
        expect(find.byType(TenantFormScreen), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('shows no intermediate offset without animations', (
        tester,
      ) async {
        useReducedMotion(tester);
        await c.entrance.show(tester);

        await c.exit.leave(tester);
        await tester.pump();
        await tester.pump(_tick);

        if (page.evaluate().isNotEmpty) expectAtRest(tester, page);
        await tester.pumpAndSettle();
        expect(currentPath(tester), _list);
        expectAtRest(tester, _tenantList);
      });

      testWidgets('leaves the invitation out of the history', (tester) async {
        await c.entrance.show(tester);
        await c.exit.leave(tester);
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(currentPath(tester), '/properti/p1');
        expect(find.byType(PropertyDetailScreen), findsOneWidget);
        expectAtRest(tester, find.byType(PropertyDetailScreen));
        expect(_share, findsNothing);
        expect(_qr, findsNothing);
        expect(_tenantList, findsNothing);
      });

      testWidgets('never returns to an invitation screen on back', (
        tester,
      ) async {
        await c.entrance.show(tester);
        await c.exit.leave(tester);
        await tester.pumpAndSettle();

        final paths = await _backPaths(tester);

        expect(paths, isNotEmpty);
        expect(paths.first, '/properti/p1');
        for (final path in paths) {
          expect(path, isNot(contains('undangan')), reason: '$paths');
          expect(path, isNot(contains('tambah')), reason: '$paths');
        }
        expect(_share, findsNothing);
        expect(_qr, findsNothing);
      });

      testWidgets('leaves the Properti tab selected and the bar back', (
        tester,
      ) async {
        await c.entrance.show(tester);
        await c.exit.leave(tester);
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.byType(PropertyListScreen), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          3,
        );
      });
    });
  }

  group('the QR screen back button', () {
    testWidgets('still returns to the share screen', (tester) async {
      await pumpTenantApp(tester, _repo(), path: '$_list/t2/undangan/qr');

      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '$_list/t2/undangan');
      expect(_share, findsOneWidget);
    });
  });
}
