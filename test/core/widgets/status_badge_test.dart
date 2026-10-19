import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';

import '../../helpers/a11y.dart';
import '../../helpers/fakes.dart';

final _tokens = buildTheme().extension<NiscalaTokens>()!;

final _allColors = <String, BadgeColors>{
  'complaintNew': _tokens.complaintNew,
  'urgencyHigh': _tokens.urgencyHigh,
  'paymentPaid': _tokens.paymentPaid,
  'paymentUnpaid': _tokens.paymentUnpaid,
  'paymentRejected': _tokens.paymentRejected,
  'roomVacant': _tokens.roomVacant,
  'category': _tokens.category,
};

Widget _badge(StatusBadge badge) => themedApp(Scaffold(body: badge));

Widget _allBadges() => themedApp(
  Scaffold(
    body: Column(
      children: [
        for (final entry in _allColors.entries)
          StatusBadge(label: 'Label ${entry.key}', colors: entry.value),
      ],
    ),
  ),
);

BoxDecoration _decoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(StatusBadge),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  const colors = BadgeColors(
    background: Color(0xFFDDEEEA),
    foreground: Color(0xFF0E5E52),
  );

  testWidgets('shows the label text', (tester) async {
    await tester.pumpWidget(
      _badge(const StatusBadge(label: 'Lunas', colors: colors)),
    );

    expect(find.text('Lunas'), findsOneWidget);
  });

  testWidgets('shows the label for every token', (tester) async {
    await tester.pumpWidget(_allBadges());

    for (final name in _allColors.keys) {
      expect(find.text('Label $name'), findsOneWidget);
    }
  });

  testWidgets('paints the background of the colours it is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      _badge(const StatusBadge(label: 'Lunas', colors: colors)),
    );

    expect(_decoration(tester).color, colors.background);
  });

  testWidgets('writes the label in the foreground colour', (tester) async {
    await tester.pumpWidget(
      _badge(const StatusBadge(label: 'Lunas', colors: colors)),
    );

    expect(
      tester.widget<Text>(find.text('Lunas')).style?.color,
      colors.foreground,
    );
  });

  testWidgets('takes its colours from a token', (tester) async {
    await tester.pumpWidget(
      _badge(StatusBadge(label: 'Baru', colors: _tokens.complaintNew)),
    );

    expect(_decoration(tester).color, _tokens.complaintNew.background);
    expect(
      tester.widget<Text>(find.text('Baru')).style?.color,
      _tokens.complaintNew.foreground,
    );
  });

  testWidgets('has radius 6', (tester) async {
    await tester.pumpWidget(
      _badge(const StatusBadge(label: 'Lunas', colors: colors)),
    );

    expect(_decoration(tester).borderRadius, BorderRadius.circular(6));
  });

  testWidgets('writes the label 11 bold', (tester) async {
    await tester.pumpWidget(
      _badge(const StatusBadge(label: 'Lunas', colors: colors)),
    );

    final style = tester.widget<Text>(find.text('Lunas')).style;
    expect(style?.fontSize, 11);
    expect(style?.fontWeight, FontWeight.w700);
  });

  testWidgets('pads the label by 8 sideways and 3 vertically', (tester) async {
    await tester.pumpWidget(
      _badge(const StatusBadge(label: 'Lunas', colors: colors)),
    );

    final box = tester.getSize(
      find
          .descendant(
            of: find.byType(StatusBadge),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final text = tester.getSize(find.text('Lunas'));
    expect(box.width, closeTo(text.width + 16, 0.01));
    expect(box.height, closeTo(text.height + 6, 0.01));
  });

  testWidgets('draws no border when the colours have none', (tester) async {
    await tester.pumpWidget(
      _badge(const StatusBadge(label: 'Lunas', colors: colors)),
    );

    expect(_decoration(tester).border, isNull);
  });

  testWidgets('draws the border of the colours when they have one', (
    tester,
  ) async {
    await tester.pumpWidget(
      _badge(StatusBadge(label: 'Belum bayar', colors: _tokens.paymentUnpaid)),
    );

    final border = _decoration(tester).border;
    expect(border, isNotNull);
    expect(border!.top.color, _tokens.paymentUnpaid.border);
    expect(border.top.width, greaterThan(0));
  });

  testWidgets('shows the icon in the foreground colour when one is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      _badge(
        const StatusBadge(
          label: 'Lunas',
          colors: colors,
          icon: Icons.check_circle,
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Lunas'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.check_circle)).color,
      colors.foreground,
    );
  });

  testWidgets('shows no icon when none is given', (tester) async {
    await tester.pumpWidget(
      _badge(const StatusBadge(label: 'Lunas', colors: colors)),
    );

    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('reads as a single semantics node with the label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _badge(
        const StatusBadge(
          label: 'Menunggu verifikasi',
          colors: colors,
          icon: Icons.schedule,
        ),
      ),
    );

    try {
      final node = tester.getSemantics(find.byType(StatusBadge));
      expect(node.label, 'Menunggu verifikasi');
      expect(node.childrenCount, 0);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('text contrast is at least 4.5 to 1 for every token', (
    tester,
  ) async {
    await tester.pumpWidget(_allBadges());

    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('fits at large text size', (tester) async {
    await pumpAtLargeText(tester, _allBadges());

    expect(tester.takeException(), isNull);
  });

  testWidgets('wraps a long label at large text size without overflow', (
    tester,
  ) async {
    await pumpAtLargeText(
      tester,
      _badge(
        const StatusBadge(
          label: 'Menunggu verifikasi pembayaran',
          colors: colors,
          icon: Icons.schedule,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
