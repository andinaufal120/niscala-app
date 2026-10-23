import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/rooms/ui/room_widgets.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';

final _tokens = buildTheme().extension<NiscalaTokens>()!;

Widget _badge(Occupancy occupancy) =>
    themedApp(Scaffold(body: OccupancyBadge(occupancy: occupancy)));

void main() {
  testWidgets('shows Terisi for an occupied room', (tester) async {
    await tester.pumpWidget(_badge(Occupancy.occupied));

    expect(find.text('Terisi'), findsOneWidget);
  });

  testWidgets('shows Kosong for a vacant room', (tester) async {
    await tester.pumpWidget(_badge(Occupancy.vacant));

    expect(find.text('Kosong'), findsOneWidget);
  });

  testWidgets('colours an occupied room from the occupied token', (
    tester,
  ) async {
    await tester.pumpWidget(_badge(Occupancy.occupied));

    final colors = tester.widget<StatusBadge>(find.byType(StatusBadge)).colors;
    expect(colors.background, _tokens.roomOccupied.background);
    expect(colors.foreground, _tokens.roomOccupied.foreground);
    expect(colors.border, _tokens.roomOccupied.border);
  });

  testWidgets('colours a vacant room from the vacant token', (tester) async {
    await tester.pumpWidget(_badge(Occupancy.vacant));

    final colors = tester.widget<StatusBadge>(find.byType(StatusBadge)).colors;
    expect(colors.background, _tokens.roomVacant.background);
    expect(colors.foreground, _tokens.roomVacant.foreground);
    expect(colors.border, _tokens.roomVacant.border);
  });

  testWidgets('shows occupied and vacant rooms in different colours', (
    tester,
  ) async {
    await tester.pumpWidget(_badge(Occupancy.occupied));
    final occupied = tester.widget<StatusBadge>(find.byType(StatusBadge));
    await tester.pumpWidget(_badge(Occupancy.vacant));
    final vacant = tester.widget<StatusBadge>(find.byType(StatusBadge));

    expect(occupied.colors.background, isNot(vacant.colors.background));
  });

  testWidgets('speaks its label', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_badge(Occupancy.occupied));

      expect(find.bySemanticsLabel('Terisi'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await tester.pumpWidget(_badge(Occupancy.vacant));

    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('fits at large text size', (tester) async {
    await pumpAtLargeText(tester, _badge(Occupancy.occupied));

    expect(tester.takeException(), isNull);
  });
}
