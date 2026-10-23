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
import '../../../helpers/transitions.dart';
import 'tenant_ui_helpers.dart';

const _tick = Duration(milliseconds: 100);
const _list = '/properti/p1/penyewa';
const _property = '/properti/p1';

FakeTenantRepository _repo() => FakeTenantRepository(tenants: sampleTenants());

Finder get _share => find.byType(InvitationShareScreen);
Finder get _qr => find.byType(InvitationQrScreen);
Finder get _tenantList => find.byType(TenantListScreen);

/// The invitation screen and the pages below it that a leave removes.
final _flowPages = <Finder>[
  find.byType(TenantDetailScreen, skipOffstage: false),
  find.byType(InvitationShareScreen, skipOffstage: false),
  find.byType(InvitationQrScreen, skipOffstage: false),
  find.byType(TenantFormScreen, skipOffstage: false),
];

/// A deep link to an invitation screen and the way to leave it.
typedef _Case = ({
  String name,
  String path,
  Finder page,
  Finder exit,
  bool dismissesWithTooltip,
});

final _cases = <_Case>[
  (
    name: 'Selesai on the share screen',
    path: '$_list/t2/undangan',
    page: _share,
    exit: find.text('Selesai'),
    dismissesWithTooltip: false,
  ),
  (
    name: 'the close button on the share screen',
    path: '$_list/t2/undangan?baru=1',
    page: _share,
    exit: find.byTooltip('Tutup'),
    dismissesWithTooltip: true,
  ),
  (
    name: 'Tutup on the QR screen',
    path: '$_list/t2/undangan/qr',
    page: _qr,
    exit: find.text('Tutup'),
    dismissesWithTooltip: false,
  ),
];

/// Taps [finder] after scrolling it into view, without waiting for any page
/// transition. [times] taps follow each other with no frame in between.
Future<void> _tapNow(
  WidgetTester tester,
  Finder finder, {
  int times = 1,
}) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  for (var i = 0; i < times; i++) {
    await tester.tap(finder, warnIfMissed: i == 0);
  }
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// The paths reached by pressing the system back button until the app stays.
Future<List<String>> _backPaths(WidgetTester tester) async {
  final paths = <String>[];
  for (var i = 0; i < 6; i++) {
    final before = currentPath(tester);
    await _back(tester);
    final after = currentPath(tester);
    if (after == before) break;
    paths.add(after);
  }
  return paths;
}

void main() {
  for (final c in _cases) {
    group('leaving by ${c.name} from a deep link', () {
      testWidgets('twice at once ends once on the tenant list', (tester) async {
        await pumpTenantApp(tester, _repo(), path: c.path);

        await _tapNow(tester, c.exit, times: 2);
        await tester.pumpAndSettle();

        expect(currentPath(tester), _list);
        expect(_tenantList, findsOneWidget);
        expectAtRest(tester, _tenantList);
        expect(c.page, findsNothing);
        expect(find.byType(NavigationBar), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('three times at once ends once on the tenant list', (
        tester,
      ) async {
        await pumpTenantApp(tester, _repo(), path: c.path);

        await _tapNow(tester, c.exit, times: 3);
        await tester.pumpAndSettle();

        expect(currentPath(tester), _list);
        expect(_tenantList, findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('twice at once keeps the property detail underneath', (
        tester,
      ) async {
        await pumpTenantApp(tester, _repo(), path: c.path);
        await _tapNow(tester, c.exit, times: 2);
        await tester.pumpAndSettle();

        await _back(tester);

        expect(currentPath(tester), _property);
        expect(find.byType(PropertyDetailScreen), findsOneWidget);
        expectAtRest(tester, find.byType(PropertyDetailScreen));
        expect(_tenantList, findsNothing);
        expect(c.page, findsNothing);
      });

      testWidgets('twice at once does not leave the Properti tab or the app', (
        tester,
      ) async {
        await pumpTenantApp(tester, _repo(), path: c.path);
        await _tapNow(tester, c.exit, times: 2);
        await tester.pumpAndSettle();
        await _back(tester);

        await _back(tester);

        expect(currentPath(tester), '/properti');
        expect(find.byType(PropertyListScreen), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          3,
        );
      });

      testWidgets('a second tap one frame later ends once on the list', (
        tester,
      ) async {
        await pumpTenantApp(tester, _repo(), path: c.path);

        await _tapNow(tester, c.exit);
        await tester.pump();
        await tester.tap(c.exit, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(currentPath(tester), _list);
        expect(_tenantList, findsOneWidget);
        await _back(tester);
        expect(currentPath(tester), _property);
        expect(find.byType(PropertyDetailScreen), findsOneWidget);
      });

      testWidgets('slides only the leaving page out, as one animation', (
        tester,
      ) async {
        await pumpTenantApp(tester, _repo(), path: c.path);

        await _tapNow(tester, c.exit);
        await tester.pump();
        await tester.pump(_tick);

        expectMidSlide(tester, c.page);
        for (final other in _flowPages) {
          if (other.evaluate().isEmpty) continue;
          if (other.evaluate().first.widget == c.page.evaluate().first.widget) {
            continue;
          }
          // The page right under the leaving one may sit a little to the left.
          expect(
            tester.getTopLeft(other).dx,
            lessThanOrEqualTo(0.01),
            reason: 'only the leaving page may slide to the right',
          );
        }
      });
    });
  }

  group('leaving from a deep link two levels deeper', () {
    testWidgets('behaves the same from the share and the QR screen', (
      tester,
    ) async {
      final results = <String, ({String path, List<String> back})>{};
      for (final c in _cases.where((c) => !c.dismissesWithTooltip)) {
        await tester.pumpWidget(const SizedBox());
        await pumpTenantApp(tester, _repo(), path: c.path);
        await _tapNow(tester, c.exit);
        await tester.pumpAndSettle();
        results[c.name] = (
          path: currentPath(tester),
          back: await _backPaths(tester),
        );
      }

      expect(results, hasLength(2));
      final values = results.values.toList();
      expect(values.first.path, _list);
      expect(values.first.path, values.last.path);
      expect(values.first.back, values.last.back);
      expect(values.first.back.first, _property);
    });

    testWidgets('the QR screen and the share screen both leave the tenant '
        'detail out of the history', (tester) async {
      for (final path in ['$_list/t2/undangan/qr', '$_list/t2/undangan']) {
        await tester.pumpWidget(const SizedBox());
        await pumpTenantApp(tester, _repo(), path: path);
        final exit = path.endsWith('qr')
            ? find.text('Tutup')
            : find.text('Selesai');
        await _tapNow(tester, exit);
        await tester.pumpAndSettle();

        final paths = await _backPaths(tester);

        expect(paths.first, _property, reason: path);
        for (final visited in paths) {
          expect(visited, isNot(startsWith('$_list/')), reason: path);
        }
        expect(find.byType(TenantDetailScreen), findsNothing, reason: path);
      }
    });
  });
}
