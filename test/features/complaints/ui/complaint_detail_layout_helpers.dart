import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/layout.dart';
import 'complaint_ui_helpers.dart';

/// The detail bar of the screen on show.
DetailAppBar detailBar(WidgetTester tester) =>
    tester.widget<DetailAppBar>(find.byType(DetailAppBar));

/// Expects the Status card: a plain section card titled Status that holds the
/// steps of [status], above every other card, with no status badge.
void expectStatusCard(WidgetTester tester, ComplaintStatus status) {
  expectSectionCard(tester, 'Status');
  final card = sectionCardOf('Status');
  expect(tester.widget<SectionCard>(card).emphasis, isFalse);
  final steps = find.descendant(of: card, matching: statusSteps());
  expect(steps, findsOneWidget);
  expect(tester.widget<ComplaintStatusSteps>(steps).status, status);
  expect(statusSteps(), findsOneWidget);

  final top = tester.getTopLeft(card).dy;
  for (final other in find.byType(SectionCard).evaluate()) {
    final otherTop = tester
        .getTopLeft(find.byElementPredicate((e) => e == other))
        .dy;
    expect(otherTop, greaterThanOrEqualTo(top));
  }
}

/// Expects the labelled value rows of an AI classification in the card titled
/// Klasifikasi: Kategori and Urgensi side by side (or stacked, reading
/// Kategori first, when [mayStack]), and the suggested action below.
void expectClassificationRow(
  WidgetTester tester, {
  required String category,
  required String urgency,
  bool mayStack = false,
}) {
  final card = sectionCardOf('Klasifikasi');
  Finder inCard(Finder f) => find.descendant(of: card, matching: f);

  final categoryLabel = inCard(find.text('Kategori'));
  final urgencyLabel = inCard(find.text('Urgensi'));
  expect(categoryLabel, findsOneWidget);
  expect(urgencyLabel, findsOneWidget);
  final k = tester.getRect(categoryLabel);
  final u = tester.getRect(urgencyLabel);

  for (final label in [categoryLabel, urgencyLabel]) {
    final style = styleOf(tester, label);
    expect(style.fontSize, 12);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, NiscalaColors.textMuted);
  }

  final value = tester.getRect(inCard(find.text(category)));
  final badge = tester.getRect(
    find.ancestor(
      of: inCard(statusBadge(urgency)),
      matching: find.byType(StatusBadge),
    ),
  );
  expect(value.top, greaterThanOrEqualTo(k.bottom - 1));
  expect(value.left, closeTo(k.left, 1));
  expect(badge.top, greaterThanOrEqualTo(u.bottom - 1));
  expect(badge.left, closeTo(u.left, 1));

  final sideBySide = (u.top - k.top).abs() <= 1 && u.left > k.left + 20;
  if (!mayStack) {
    expect(sideBySide, isTrue, reason: 'Kategori and Urgensi share a row');
    expect(value.top, closeTo(badge.top, 8));
  } else if (!sideBySide) {
    expect(u.top, greaterThanOrEqualTo(value.bottom - 1));
  }
}

/// Expects the suggested action label above its text, both below the
/// Kategori/Urgensi values.
void expectSuggestedAction(WidgetTester tester, String action) {
  final card = sectionCardOf('Klasifikasi');
  Finder inCard(Finder f) => find.descendant(of: card, matching: f);
  final label = tester.getRect(inCard(find.text('Tindakan yang disarankan')));
  final text = tester.getRect(inCard(find.text(action)));
  expect(text.top, greaterThanOrEqualTo(label.bottom - 1));
  expect(
    label.top,
    greaterThanOrEqualTo(
      tester.getRect(inCard(find.text('Pipa dan air'))).bottom - 1,
    ),
  );
  final urgencyBadge = tester.getRect(
    find.descendant(of: card, matching: find.byType(StatusBadge)).first,
  );
  expect(label.top, greaterThanOrEqualTo(urgencyBadge.bottom - 1));
}

/// Expects the AI disclaimer [text] in small muted type under a divider, which
/// sits below [above] (the last content of the card).
void expectDisclaimerUnderDivider(WidgetTester tester, Finder above) {
  final card = sectionCardOf('Klasifikasi');
  final divider = find.descendant(of: card, matching: find.byType(Divider));
  expect(divider, findsOneWidget);
  final line = tester.getRect(divider).center.dy;
  final disclaimer = find.descendant(of: card, matching: aiDisclaimer());
  expect(disclaimer, findsOneWidget);
  final rect = tester.getRect(disclaimer);
  expect(line, lessThan(rect.top));
  expect(line, greaterThan(tester.getRect(above).bottom - 1));
  final style = styleOf(tester, disclaimer);
  expect(style.fontSize, 12);
  expect(style.color, NiscalaColors.textMuted);
}
