import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala_api/api.dart';

import '../../features/auth/ui/auth_ui_helpers.dart';
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

final _screens = <String, Future<void> Function(WidgetTester)>{
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
  'verify email': (t) => pumpVerify(t, FakeAuthRepository()),
  'activation': _pumpActivation,
};

void main() {
  setUpAll(loadAppFont);

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

      heights[entry.key] = tester.getSize(bar).height;
      lefts[entry.key] = tester.getTopLeft(titleText).dx;
    }

    for (final entry in heights.entries) {
      expect(entry.value, 56, reason: '${entry.key} bar height');
    }
    final reference = lefts.values.first;
    for (final entry in lefts.entries) {
      expect(
        entry.value,
        closeTo(reference, 0.5),
        reason: '${entry.key} title left edge ($lefts)',
      );
    }
  });
}
