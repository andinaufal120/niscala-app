import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/rooms/ui/room_detail_screen.dart';
import 'package:niscala/features/rooms/ui/room_form_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import '../../../helpers/fields.dart';
import 'room_ui_helpers.dart';

/// Every test of this file reads semantics labels.
void testWidgets(
  String description,
  Future<void> Function(WidgetTester tester) body,
) => testWidgetsWithSemantics(description, body);

const _number = 'Nomor kamar (wajib)';
const _conflict = ApiFailure(code: 'RESOURCE_VERSION_CONFLICT');
const _conflictMessage =
    'Data ini sudah diubah oleh pengguna lain. Data terbaru sudah dimuat ulang.';

Room _room({int version = 3, String number = '08', int baseRate = 800000}) =>
    makeRoom(
      id: 'r1',
      number: number,
      baseRate: baseRate,
      version: version,
      facilities: ['ac'],
    );

Future<void> _pumpEdit(
  WidgetTester tester,
  FakeRoomRepository repo, {
  bool largeText = false,
}) => pumpRoomApp(
  tester,
  repo,
  path: '/properti/p1/kamar/r1/ubah',
  largeText: largeText,
);

Future<void> _submitEdit(WidgetTester tester) =>
    tapVisible(tester, find.text('Simpan Perubahan'));

void main() {
  group('the edit form sends the version it read', () {
    testWidgets('sends the version of the loaded room', (tester) async {
      final repo = FakeRoomRepository(rooms: [_room(version: 3)]);
      await _pumpEdit(tester, repo);

      await _submitEdit(tester);

      expect(repo.updatedVersions, [3]);
    });

    testWidgets('sends version 1 for a room at its first version', (
      tester,
    ) async {
      final repo = FakeRoomRepository(rooms: [_room(version: 1)]);
      await _pumpEdit(tester, repo);

      await _submitEdit(tester);

      expect(repo.updatedVersions, [1]);
    });

    testWidgets('sends a larger version unchanged', (tester) async {
      final repo = FakeRoomRepository(rooms: [_room(version: 7)]);
      await _pumpEdit(tester, repo);

      await _submitEdit(tester);

      expect(repo.updatedVersions, [7]);
    });

    testWidgets('sends the version together with the edited values', (
      tester,
    ) async {
      final repo = FakeRoomRepository(rooms: [_room(version: 4)]);
      await _pumpEdit(tester, repo);
      await typeInto(tester, _number, '12');

      await _submitEdit(tester);

      expect(repo.updated.single.id, 'r1');
      expect(repo.updated.single.input.number, '12');
      expect(repo.updatedVersions, [4]);
    });

    testWidgets('the add form sends no update', (tester) async {
      final repo = FakeRoomRepository(rooms: [_room()]);
      await pumpRoomApp(tester, repo, path: '/properti/p1/kamar/tambah');
      await typeInto(tester, _number, '20');
      await typeInto(tester, 'Tarif dasar per bulan (wajib)', '700000');

      await tapVisible(tester, find.text('Simpan Kamar'));

      expect(repo.updatedVersions, isEmpty);
      expect(repo.created, hasLength(1));
    });
  });

  group('a version conflict on edit', () {
    FakeRoomRepository conflictingRepo() {
      final repo = FakeRoomRepository(rooms: [_room(version: 3)]);
      repo.updateScript.queue.add(_conflict);
      return repo;
    }

    testWidgets('closes the form and returns to the room detail', (
      tester,
    ) async {
      await _pumpEdit(tester, conflictingRepo());

      await _submitEdit(tester);

      expect(find.byType(RoomFormScreen), findsNothing);
      expect(find.byType(RoomDetailScreen), findsOneWidget);
      expect(currentPath(tester), '/properti/p1/kamar/r1');
    });

    testWidgets(
      'shows the message in a snack bar on the screen it returns to',
      (tester) async {
        await _pumpEdit(tester, conflictingRepo());

        await _submitEdit(tester);

        expect(snackBar(_conflictMessage), findsOneWidget);
        expect(messageOfCode('RESOURCE_VERSION_CONFLICT'), _conflictMessage);
      },
    );

    testWidgets('shows the message once and shows no success snack bar', (
      tester,
    ) async {
      await _pumpEdit(tester, conflictingRepo());

      await _submitEdit(tester);

      expect(find.text(_conflictMessage), findsOneWidget);
      expect(snackBar('Perubahan tersimpan'), findsNothing);
    });

    testWidgets('sends the update once and does not retry', (tester) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);

      await _submitEdit(tester);

      expect(repo.updated, hasLength(1));
      expect(repo.updatedVersions, [3]);
    });

    testWidgets('reloads the room and shows the changed data', (tester) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);
      final loadsBefore = repo.getCalls;
      repo.rooms[0] = _room(version: 5, number: '11', baseRate: 950000);

      await _submitEdit(tester);

      expect(repo.getCalls, greaterThan(loadsBefore));
      expect(appBarTitle('Kamar 11'), findsOneWidget);
      expect(find.textContaining('Rp950.000'), findsOneWidget);
    });

    testWidgets('the next edit sends the newer version', (tester) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);
      repo.rooms[0] = _room(version: 5, number: '11');
      await _submitEdit(tester);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      goTo(tester, '/properti/p1/kamar/r1/ubah');
      await tester.pumpAndSettle();
      expect(labeledTextField(tester, _number).controller!.text, '11');
      await _submitEdit(tester);

      expect(repo.updatedVersions, [3, 5]);
    });

    testWidgets('shows the message as plain text without an inline error', (
      tester,
    ) async {
      final repo = conflictingRepo();
      await _pumpEdit(tester, repo);

      await _submitEdit(tester);

      expect(find.byType(RoomFormScreen), findsNothing);
      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsNothing);
    });

    testWidgets('meets the accessibility guidelines with the snack bar', (
      tester,
    ) async {
      await _pumpEdit(tester, conflictingRepo());

      await _submitEdit(tester);

      expect(snackBar(_conflictMessage), findsOneWidget);
      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text size with the snack bar', (tester) async {
      await _pumpEdit(tester, conflictingRepo(), largeText: true);

      await _submitEdit(tester);

      expect(snackBar(_conflictMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('other failures on edit stay on the form', () {
    testWidgets('a field error shows inline and does not close the form', (
      tester,
    ) async {
      final repo = FakeRoomRepository(rooms: [_room()])
        ..updateScript.queue.add(
          const ApiFailure(code: 'VALIDATION_FAILED', field: 'number'),
        );
      await _pumpEdit(tester, repo);

      await _submitEdit(tester);

      expect(labeledFieldError(tester, _number), 'Nomor kamar tidak valid.');
      expect(find.byType(RoomFormScreen), findsOneWidget);
      expect(snackBar(_conflictMessage), findsNothing);
    });

    testWidgets(
      'a network failure shows a banner and does not close the form',
      (tester) async {
        final repo = FakeRoomRepository(rooms: [_room()])
          ..updateScript.queue.add(const ApiFailure.network());
        await _pumpEdit(tester, repo);

        await _submitEdit(tester);

        expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
        expect(find.byType(RoomFormScreen), findsOneWidget);
        expect(snackBar(_conflictMessage), findsNothing);
      },
    );

    testWidgets('a retry after a failure sends the same version', (
      tester,
    ) async {
      final repo = FakeRoomRepository(rooms: [_room(version: 6)])
        ..updateScript.queue.add(const ApiFailure.network());
      await _pumpEdit(tester, repo);
      await _submitEdit(tester);

      await _submitEdit(tester);

      expect(repo.updatedVersions, [6, 6]);
    });
  });
}
