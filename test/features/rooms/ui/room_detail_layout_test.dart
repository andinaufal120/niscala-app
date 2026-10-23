import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/rooms/ui/room_form_screen.dart';
import 'package:niscala/features/tenants/ui/tenant_detail_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/layout.dart';
import 'room_ui_helpers.dart';

Future<void> _open(
  WidgetTester tester,
  Room room, {
  UserRole role = UserRole.owner,
  bool narrow = false,
  bool largeText = false,
}) async {
  await pumpRoomApp(
    tester,
    FakeRoomRepository(
      rooms: [
        room,
        vacantRoom(id: 'r2'),
      ],
    ),
    tenants: FakeTenantRepository(
      tenants: [makeTenant(id: 't1', name: 'Budi Santoso')],
    ),
    role: role,
    path: '/properti/p1/kamar/${room.id}',
    largeText: largeText,
  );
  if (narrow) await useNarrowScreen(tester);
}

Room _occupied({bool editable = true}) =>
    occupiedRoom(id: 'r1', editable: editable);

Room _vacant({bool editable = true}) =>
    vacantRoom(id: 'r1', number: '08', baseRate: 650000, editable: editable);

Finder _appBarUbah() => find.descendant(
  of: find.byType(AppBar),
  matching: find.ancestor(
    of: find.text('Ubah'),
    matching: find.bySubtype<ButtonStyleButton>(),
  ),
);

Finder _badgeBox(String label) =>
    find.ancestor(of: statusBadge(label), matching: find.byType(StatusBadge));

const _rentCard = 'Tarif sewa · masa sewa ini';
const _tenantCard = 'Penyewa & masa sewa';

void main() {
  setUpAll(loadAppFont);

  group('app bar', () {
    testWidgets('Ubah is a text button of at least 48 dp', (tester) async {
      await _open(tester, _occupied());

      expect(_appBarUbah(), findsOneWidget);
      final rect = tester.getRect(_appBarUbah());
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.width, greaterThanOrEqualTo(48));
    });

    testWidgets('Ubah keeps a gutter of space to the right edge', (
      tester,
    ) async {
      await _open(tester, _occupied(), narrow: true);

      expect(
        screenWidth(tester) - tester.getRect(_appBarUbah()).right,
        greaterThanOrEqualTo(NiscalaSpacing.gutter),
      );
    });

    testWidgets('Ubah opens the edit form of the room', (tester) async {
      await _open(tester, _occupied());

      await tester.tap(_appBarUbah());
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/properti/p1/kamar/r1/ubah');
      expect(find.byType(RoomFormScreen), findsOneWidget);
    });

    testWidgets('a view-only room shows no Ubah', (tester) async {
      await _open(tester, _occupied(editable: false));

      expect(_appBarUbah(), findsNothing);
    });
  });

  group('rent card', () {
    testWidgets('holds the Terisi badge on the heading row, top right', (
      tester,
    ) async {
      await _open(tester, _occupied(), narrow: true);

      expectSectionCard(tester, _rentCard);
      final card = sectionCardOf(_rentCard);
      expect(
        find.descendant(of: card, matching: statusBadge('Terisi')),
        findsOneWidget,
      );
      expect(statusBadge('Terisi'), findsOneWidget);

      final heading = tester.getRect(find.text(_rentCard));
      final badgeRect = tester.getRect(_badgeBox('Terisi'));
      final cardRect = tester.getRect(card);
      expect(badgeRect.top, lessThan(heading.bottom));
      expect(badgeRect.bottom, greaterThan(heading.top));
      expect(badgeRect.left, greaterThan(heading.left));
      expect(cardRect.right - badgeRect.right, lessThanOrEqualTo(24));
    });

    testWidgets('holds the Kosong badge in the base rate card', (tester) async {
      await _open(tester, _vacant(), narrow: true);

      final card = sectionCardOf('Tarif dasar kamar');
      expect(
        find.descendant(of: card, matching: statusBadge('Kosong')),
        findsOneWidget,
      );
      expect(statusBadge('Kosong'), findsOneWidget);

      final heading = tester.getRect(find.text('Tarif dasar kamar'));
      final badge = tester.getRect(_badgeBox('Kosong'));
      expect(badge.top, lessThan(heading.bottom));
      expect(badge.bottom, greaterThan(heading.top));
      expect(badge.left, greaterThan(heading.left));
    });

    testWidgets('no badge sits above the first card', (tester) async {
      await _open(tester, _occupied(), narrow: true);

      expect(
        tester.getTopLeft(statusBadge('Terisi')).dy,
        greaterThanOrEqualTo(tester.getTopLeft(sectionCardOf(_rentCard)).dy),
      );
    });

    testWidgets('shows the rent big and the unit small and muted', (
      tester,
    ) async {
      await _open(tester, _occupied(), narrow: true);

      final rent = find.textContaining('Rp750.000');
      final amount = styleOfPart(tester, rent, 'Rp750.000');
      expect(amount.fontSize, inInclusiveRange(22, 26));
      expect(amount.fontWeight, FontWeight.w800);

      final unit = find.descendant(
        of: sectionCardOf(_rentCard),
        matching: find.textContaining('/ bulan'),
      );
      final unitStyle = styleOfPart(tester, unit.first, '/ bulan');
      expect(unitStyle.fontSize!, lessThan(amount.fontSize!));
      expect(unitStyle.color, NiscalaColors.textMuted);
    });

    testWidgets('keeps the base rate line below the rent', (tester) async {
      await _open(tester, _occupied(), narrow: true);

      final base = find.text('Tarif dasar kamar: Rp800.000 / bulan');
      expect(base, findsOneWidget);
      expect(
        find.descendant(of: sectionCardOf(_rentCard), matching: base),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(base).dy,
        greaterThanOrEqualTo(
          tester.getRect(find.textContaining('Rp750.000')).bottom - 1,
        ),
      );
    });

    testWidgets('keeps the badge on the card at 200 % text', (tester) async {
      await _open(tester, _occupied(), largeText: true);

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: sectionCardOf(_rentCard),
          matching: statusBadge('Terisi'),
        ),
        findsOneWidget,
      );
    });
  });

  group('size and facilities', () {
    testWidgets('Ukuran shows a heading and the size and nothing else', (
      tester,
    ) async {
      await _open(tester, _occupied(), narrow: true);

      expectSectionCard(tester, 'Ukuran');
      final texts = find.descendant(
        of: sectionCardOf('Ukuran'),
        matching: find.byType(Text),
      );
      expect(
        [for (final text in texts.evaluate()) (text.widget as Text).data],
        ['Ukuran', '3,5 × 4 m', '14 m²'],
      );
    });

    testWidgets('each facility is a primary soft pill in one Wrap', (
      tester,
    ) async {
      await _open(tester, _occupied(), narrow: true);

      expectSectionCard(tester, 'Fasilitas');
      final card = sectionCardOf('Fasilitas');
      final wrap = find.descendant(of: card, matching: find.byType(Wrap));
      expect(wrap, findsOneWidget);
      for (final tag in ['ac', 'kasur']) {
        final facility = find.descendant(of: wrap, matching: find.text(tag));
        expect(facility, findsOneWidget);
        expect(
          hasFillAround(facility, NiscalaColors.primarySoft),
          isTrue,
          reason: '"$tag" must sit on a primary soft fill',
        );
        expect(styleOf(tester, facility).color, NiscalaColors.primary);
      }
    });

    testWidgets('facilities wrap instead of overflowing at 200 % text', (
      tester,
    ) async {
      await _open(
        tester,
        occupiedRoom(
          id: 'r1',
          facilities: const ['ac', 'kasur', 'lemari', 'kamar mandi dalam'],
        ),
        largeText: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('kamar mandi dalam'), findsOneWidget);
    });

    testWidgets('no facilities keeps the empty text and shows no pill', (
      tester,
    ) async {
      await _open(tester, _vacant(), narrow: true);

      final card = sectionCardOf('Fasilitas');
      expect(
        find.descendant(of: card, matching: find.text('Belum ada fasilitas')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.byType(Wrap)),
        findsNothing,
      );
    });
  });

  group('tenant card', () {
    testWidgets('puts Mulai and Berakhir side by side with their dates', (
      tester,
    ) async {
      await _open(tester, _occupied(), narrow: true);

      final start = tester.getRect(find.text('Mulai'));
      final end = tester.getRect(find.text('Berakhir'));
      expect(start.top, closeTo(end.top, 1));
      expect(end.left, greaterThan(start.right));

      final startDate = tester.getRect(find.text('1 Jan 2026'));
      final endDate = tester.getRect(find.text('31 Des 2026'));
      expect(startDate.left, closeTo(start.left, 1));
      expect(endDate.left, closeTo(end.left, 1));
      expect(startDate.top, greaterThanOrEqualTo(start.bottom - 1));
      expect(endDate.top, greaterThanOrEqualTo(end.bottom - 1));
      expect(startDate.top, closeTo(endDate.top, 1));
    });

    testWidgets('keeps both dates and dashes inside the card', (tester) async {
      final room = makeRoom(id: 'r1', number: '08', lease: makeRoomLease());
      await _open(tester, room, narrow: true);

      final card = sectionCardOf(_tenantCard);
      expect(
        find.descendant(of: card, matching: find.text('-')),
        findsNWidgets(2),
      );
      expect(
        tester.getTopLeft(find.text('Mulai')).dy,
        closeTo(tester.getTopLeft(find.text('Berakhir')).dy, 1),
      );
    });

    testWidgets('does not overlap Mulai and Berakhir at 200 % text', (
      tester,
    ) async {
      await _open(tester, _occupied(), largeText: true);

      expect(tester.takeException(), isNull);
      final columns = [
        for (final text in ['Mulai', '1 Jan 2026', 'Berakhir', '31 Des 2026'])
          tester.getRect(find.text(text)),
      ];
      expect(columns[0].overlaps(columns[2]), isFalse);
      expect(columns[1].overlaps(columns[3]), isFalse);
      expect(columns[0].overlaps(columns[3]), isFalse);
      expect(columns[1].overlaps(columns[2]), isFalse);
      for (final rect in columns) {
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(360));
      }
    });

    testWidgets('a divider separates the dates from the tenant link', (
      tester,
    ) async {
      await _open(tester, _occupied(), narrow: true);

      final divider = find.descendant(
        of: sectionCardOf(_tenantCard),
        matching: find.byType(Divider),
      );
      expect(divider, findsOneWidget);
      final rect = tester.getRect(divider);
      expect(
        rect.top,
        greaterThanOrEqualTo(tester.getRect(find.text('31 Des 2026')).bottom),
      );
      expect(
        rect.bottom,
        lessThanOrEqualTo(
          tester.getRect(textButtonLabelled('Lihat rincian penyewa')).top + 1,
        ),
      );
    });

    testWidgets('Lihat rincian penyewa is a full width text button row', (
      tester,
    ) async {
      await _open(tester, _occupied(), narrow: true);

      final link = textButtonLabelled('Lihat rincian penyewa');
      expect(link, findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Lihat rincian penyewa'),
          matching: find.bySubtype<OutlinedButton>(),
        ),
        findsNothing,
      );
      final rect = tester.getRect(link);
      expect(rect.height, greaterThanOrEqualTo(48));
      final card = tester.getRect(sectionCardOf(_tenantCard));
      expect(rect.width, greaterThanOrEqualTo(card.width - 32 - 1));

      final chevron = find.descendant(
        of: link,
        matching: find.byIcon(Icons.chevron_right),
      );
      expect(chevron, findsOneWidget);
      expect(
        tester.getRect(chevron).left,
        greaterThanOrEqualTo(
          tester.getRect(find.text('Lihat rincian penyewa')).right - 1,
        ),
      );
    });

    testWidgets('Lihat rincian penyewa opens the tenant detail', (
      tester,
    ) async {
      await _open(tester, _occupied());

      await tapVisible(tester, find.text('Lihat rincian penyewa'));

      expect(currentPath(tester), '/properti/p1/penyewa/t1');
      expect(find.byType(TenantDetailScreen), findsOneWidget);
    });

    testWidgets('a vacant room shows neither the divider nor the link', (
      tester,
    ) async {
      await _open(tester, _vacant(), narrow: true);

      expect(find.text('Lihat rincian penyewa'), findsNothing);
      expect(
        find.descendant(
          of: sectionCardOf('Kamar kosong'),
          matching: find.byType(Divider),
        ),
        findsNothing,
      );
    });
  });

  group('delete action', () {
    testWidgets('Hapus Kamar is a full width danger outlined button', (
      tester,
    ) async {
      await _open(tester, _occupied(), narrow: true);

      expectDangerOutlinedButton(
        tester,
        'Hapus Kamar',
        reference: sectionCardOf(_rentCard),
      );
    });

    testWidgets('Hapus Kamar is the same for a vacant room', (tester) async {
      await _open(tester, _vacant(), narrow: true);

      expectDangerOutlinedButton(
        tester,
        'Hapus Kamar',
        reference: sectionCardOf('Tarif dasar kamar'),
      );
    });

    testWidgets('Hapus Kamar still asks for confirmation', (tester) async {
      await _open(tester, _occupied());

      await tapVisible(tester, find.text('Hapus Kamar'));

      expect(find.text('Hapus Kamar 08?'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });
  });
}
