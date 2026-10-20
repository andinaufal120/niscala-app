import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/features/complaints/ui/complaint_form_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/management_complaint_list_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_detail_screen.dart';
import 'package:niscala/features/complaints/ui/tenant_complaint_list_screen.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala/features/properties/ui/property_form_screen.dart';
import 'package:niscala/features/properties/ui/property_list_screen.dart';
import 'package:niscala/features/rooms/ui/room_detail_screen.dart';
import 'package:niscala/features/rooms/ui/room_list_screen.dart';
import 'package:niscala_api/api.dart';

import '../features/complaints/ui/complaint_ui_helpers.dart';
import '../helpers/fakes.dart';
import '../helpers/transitions.dart';

const _tick = Duration(milliseconds: 100);

/// A screen reached from a parent screen by one tap.
typedef _Flow = ({
  String name,
  Future<void> Function(WidgetTester tester) show,
  Future<void> Function(WidgetTester tester) open,
  Finder parent,
  Finder child,
});

Future<void> _tapComplaint(WidgetTester tester) =>
    tester.tap(find.text(makeComplaint().description));

FakeComplaintRepository _complaints() =>
    FakeComplaintRepository(complaints: [makeComplaint()]);

FakePropertyRepository _properties() => FakePropertyRepository(
  properties: [
    makeProperty(id: 'p1'),
    makeProperty(id: 'p2', name: 'Kos Mawar'),
  ],
);

FakeRoomRepository _rooms() => FakeRoomRepository(
  rooms: [
    occupiedRoom(id: 'r1', number: '01'),
    vacantRoom(id: 'r2', number: '02'),
  ],
);

final _flows = <_Flow>[
  (
    name: 'tenant complaint list to detail',
    show: (tester) => pumpComplaintApp(tester, _complaints()),
    open: _tapComplaint,
    parent: find.byType(TenantComplaintListScreen),
    child: find.byType(TenantComplaintDetailScreen),
  ),
  (
    name: 'tenant complaint list to the complaint form',
    show: (tester) => pumpComplaintApp(tester, _complaints()),
    open: (tester) => tester.tap(find.text('Ajukan')),
    parent: find.byType(TenantComplaintListScreen),
    child: find.byType(ComplaintFormScreen),
  ),
  (
    name: 'management complaint list to detail',
    show: (tester) =>
        pumpComplaintApp(tester, _complaints(), role: UserRole.owner),
    open: _tapComplaint,
    parent: find.byType(ManagementComplaintListScreen),
    child: find.byType(ManagementComplaintDetailScreen),
  ),
  (
    name: 'property list to detail',
    show: (tester) => pumpPropertyApp(tester, _properties()),
    open: (tester) => tester.tap(find.text('Kos Melati')),
    parent: find.byType(PropertyListScreen),
    child: find.byType(PropertyDetailScreen),
  ),
  (
    name: 'property list to the add form',
    show: (tester) => pumpPropertyApp(tester, _properties()),
    open: (tester) => tester.tap(find.text('Tambah')),
    parent: find.byType(PropertyListScreen),
    child: find.byType(PropertyFormScreen),
  ),
  (
    name: 'room list to detail',
    show: (tester) => pumpRoomApp(tester, _rooms()),
    open: (tester) => tester.tap(find.text('02')),
    parent: find.byType(RoomListScreen),
    child: find.byType(RoomDetailScreen),
  ),
];

/// How the user leaves a sub-page.
typedef _Leave = ({String name, Future<void> Function(WidgetTester) leave});

final _leaves = <_Leave>[
  (name: 'Kembali', leave: (tester) => tester.tap(backButton())),
  (name: 'system back', leave: (tester) => tester.binding.handlePopRoute()),
];

void main() {
  for (final flow in _flows) {
    group(flow.name, () {
      testWidgets('slides the sub-page in mid-transition', (tester) async {
        await flow.show(tester);

        await flow.open(tester);
        await tester.pump();
        await tester.pump(_tick);

        expectMidSlide(tester, flow.child);
      });

      testWidgets('rests at x 0 once opened', (tester) async {
        await flow.show(tester);

        await flow.open(tester);
        await tester.pumpAndSettle();

        expectAtRest(tester, flow.child);
      });

      testWidgets('opens without an intermediate offset without animations', (
        tester,
      ) async {
        useReducedMotion(tester);
        await flow.show(tester);

        await flow.open(tester);
        await tester.pump();
        await tester.pump();

        expectAtRest(tester, flow.child);
      });

      for (final leave in _leaves) {
        testWidgets('${leave.name} slides the sub-page out to the right', (
          tester,
        ) async {
          await flow.show(tester);
          await flow.open(tester);
          await tester.pumpAndSettle();

          await leave.leave(tester);
          await tester.pump();
          await tester.pump(_tick);

          expectMidSlide(tester, flow.child);
          expect(flow.parent, findsOneWidget);
          expect(
            leftOf(tester, flow.parent),
            lessThan(leftOf(tester, flow.child)),
            reason: 'the parent lies underneath the leaving page',
          );
        });

        testWidgets('${leave.name} ends on the parent at x 0', (tester) async {
          await flow.show(tester);
          await flow.open(tester);
          await tester.pumpAndSettle();

          await leave.leave(tester);
          await tester.pumpAndSettle();

          expect(flow.child, findsNothing);
          expectAtRest(tester, flow.parent);
        });

        testWidgets(
          '${leave.name} shows no intermediate frame without animations',
          (tester) async {
            useReducedMotion(tester);
            await flow.show(tester);
            await flow.open(tester);
            await tester.pumpAndSettle();

            await leave.leave(tester);
            await tester.pump();
            await tester.pump(_tick);

            if (flow.child.evaluate().isNotEmpty) {
              expectAtRest(tester, flow.child);
            }
            expectAtRest(tester, flow.parent);
          },
        );
      }
    });
  }
}
