import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/tokens.dart';

import '../helpers/contrast.dart';
import '../helpers/fakes.dart';

const _white = Color(0xFFFFFFFF);
const _primary = Color(0xFF0E5E52);
const _primaryStrong = Color(0xFF0A463D);
const _primarySoft = Color(0xFFDDEEEA);
const _ground = Color(0xFFF3F5F4);
const _text = Color(0xFF15211E);
const _textSecondary = Color(0xFF34423E);
const _textMuted = Color(0xFF50605B);
const _textDisabled = Color(0xFF7D8C87);
const _neutralSoft = Color(0xFFE7ECEA);
const _danger = Color(0xFF9A3412);
const _dangerSoft = Color(0xFFFBE4DA);
const _onDangerSoft = Color(0xFF7A2A0C);
const _warningSoft = Color(0xFFFDE7C7);
const _onWarningSoft = Color(0xFF7C3A00);
const _noticeSoft = Color(0xFFFDF3E1);
const _onNotice = Color(0xFF5C3A06);

typedef _Expected = ({Color background, Color foreground, Color? border});

_Expected _pair(Color background, Color foreground, [Color? border]) =>
    (background: background, foreground: foreground, border: border);

/// The badge colours the design gives each status, by token name.
final _planned = <String, _Expected>{
  'complaintNew': _pair(_primarySoft, _primary),
  'complaintInProgress': _pair(_warningSoft, _onWarningSoft),
  'complaintDone': _pair(_neutralSoft, _textSecondary),
  'urgencyHigh': _pair(_danger, _white),
  'urgencyMedium': _pair(_warningSoft, _onWarningSoft),
  'urgencyLow': _pair(_neutralSoft, _textSecondary),
  'paymentPaid': _pair(_primarySoft, _primaryStrong),
  'paymentAwaitingVerification': _pair(_warningSoft, _onWarningSoft),
  'paymentRejected': _pair(_dangerSoft, _onDangerSoft),
  'paymentUnpaid': _pair(_white, _textSecondary, _textDisabled),
  'classificationClassifying': _pair(_primarySoft, _primary),
  'classificationAwaiting': _pair(_warningSoft, _onWarningSoft),
  'classificationNotClassified': _pair(_neutralSoft, _textSecondary),
  'category': _pair(_primarySoft, _primary),
};

void main() {
  final tokens = buildTheme().extension<NiscalaTokens>()!;

  final byName = <String, BadgeColors>{
    'complaintNew': tokens.complaintNew,
    'complaintInProgress': tokens.complaintInProgress,
    'complaintDone': tokens.complaintDone,
    'urgencyHigh': tokens.urgencyHigh,
    'urgencyMedium': tokens.urgencyMedium,
    'urgencyLow': tokens.urgencyLow,
    'paymentPaid': tokens.paymentPaid,
    'paymentAwaitingVerification': tokens.paymentAwaitingVerification,
    'paymentRejected': tokens.paymentRejected,
    'paymentUnpaid': tokens.paymentUnpaid,
    'classificationClassifying': tokens.classificationClassifying,
    'classificationAwaiting': tokens.classificationAwaiting,
    'classificationNotClassified': tokens.classificationNotClassified,
    'roomOccupied': tokens.roomOccupied,
    'roomVacant': tokens.roomVacant,
    'tenantNotActivated': tokens.tenantNotActivated,
    'tenantActive': tokens.tenantActive,
    'category': tokens.category,
  };

  final groups = <String, List<String>>{
    'complaint status': [
      'complaintNew',
      'complaintInProgress',
      'complaintDone',
    ],
    'urgency': ['urgencyHigh', 'urgencyMedium', 'urgencyLow'],
    'payment status': [
      'paymentPaid',
      'paymentAwaitingVerification',
      'paymentRejected',
      'paymentUnpaid',
    ],
    'classification state': [
      'classificationClassifying',
      'classificationAwaiting',
      'classificationNotClassified',
    ],
    'room occupancy': ['roomOccupied', 'roomVacant'],
    'tenant account': ['tenantNotActivated', 'tenantActive'],
  };

  group('BadgeColors', () {
    test('keeps its background and foreground', () {
      const colors = BadgeColors(
        background: _primarySoft,
        foreground: _primary,
      );

      expect(colors.background, _primarySoft);
      expect(colors.foreground, _primary);
    });

    test('has no border unless one is given', () {
      const plain = BadgeColors(background: _white, foreground: _text);
      const bordered = BadgeColors(
        background: _white,
        foreground: _text,
        border: _textDisabled,
      );

      expect(plain.border, isNull);
      expect(bordered.border, _textDisabled);
    });
  });

  group('NiscalaTokens', () {
    test('is registered on the app theme', () {
      expect(buildTheme().extension<NiscalaTokens>(), isNotNull);
    });

    testWidgets('is reachable from a widget through of()', (tester) async {
      late NiscalaTokens found;
      await tester.pumpWidget(
        themedApp(
          Builder(
            builder: (context) {
              found = NiscalaTokens.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(found.complaintNew.background, tokens.complaintNew.background);
      expect(
        Theme.of(tester.element(find.byType(SizedBox)))
            .extension<NiscalaTokens>(),
        isNotNull,
      );
    });

    test('lerping with itself keeps every colour', () {
      final same = tokens.lerp(tokens, 0.5);

      expect(same.complaintNew.background, tokens.complaintNew.background);
      expect(same.paymentUnpaid.border, tokens.paymentUnpaid.border);
      expect(same.category.foreground, tokens.category.foreground);
    });

    test('copyWith without arguments keeps every colour', () {
      final copy = tokens.copyWith();

      expect(copy.urgencyHigh.background, tokens.urgencyHigh.background);
      expect(copy.roomVacant.foreground, tokens.roomVacant.foreground);
    });
  });

  group('a token exists for every status value', () {
    for (final entry in groups.entries) {
      for (final name in entry.value) {
        test('${entry.key}: $name', () {
          expect(byName[name], isNotNull);
        });
      }
    }

    test('lists every status token once', () {
      final all = groups.values.expand((names) => names).toList();

      expect(all.toSet(), hasLength(all.length));
      expect(byName.keys, containsAll(all));
    });
  });

  group('status colours follow the design', () {
    for (final entry in _planned.entries) {
      test(entry.key, () {
        final actual = byName[entry.key]!;

        expect(actual.background, entry.value.background);
        expect(actual.foreground, entry.value.foreground);
        expect(actual.border, entry.value.border);
      });
    }
  });

  group('values in one group look different', () {
    for (final entry in groups.entries) {
      test(entry.key, () {
        final looks = [
          for (final name in entry.value)
            (
              byName[name]!.background,
              byName[name]!.foreground,
              byName[name]!.border,
            ),
        ];

        expect(looks.toSet(), hasLength(entry.value.length));
      });
    }

    test('the unpaid badge is outlined so it differs from a white card', () {
      expect(tokens.paymentUnpaid.border, isNotNull);
    });
  });

  group('badge text contrast is at least 4.5 to 1', () {
    for (final entry in byName.entries) {
      test(entry.key, () {
        final colors = entry.value;

        expect(
          contrastRatio(colors.foreground, colors.background),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  group('the unpaid badge border is at least 3 to 1 on white', () {
    test('paymentUnpaid', () {
      expect(
        contrastRatio(tokens.paymentUnpaid.border!, _white),
        greaterThanOrEqualTo(3),
      );
    });
  });

  group('body text pairs have at least 4.5 to 1', () {
    final pairs = <String, (Color, Color)>{
      'text on ground': (_text, _ground),
      'text on white': (_text, _white),
      'textSecondary on ground': (_textSecondary, _ground),
      'textSecondary on white': (_textSecondary, _white),
      'textMuted on ground': (_textMuted, _ground),
      'textMuted on white': (_textMuted, _white),
      'textMuted on primarySoft': (_textMuted, _primarySoft),
      'text on primarySoft': (_text, _primarySoft),
      'primary on white': (_primary, _white),
      'primary on ground': (_primary, _ground),
      'primary on primarySoft': (_primary, _primarySoft),
      'primaryStrong on primarySoft': (_primaryStrong, _primarySoft),
      'white on primary': (_white, _primary),
      'white on primaryStrong': (_white, _primaryStrong),
      'danger on white': (_danger, _white),
      'danger on ground': (_danger, _ground),
      'white on danger': (_white, _danger),
      'onDangerSoft on dangerSoft': (_onDangerSoft, _dangerSoft),
      'onWarningSoft on warningSoft': (_onWarningSoft, _warningSoft),
      'onNotice on noticeSoft': (_onNotice, _noticeSoft),
    };

    for (final entry in pairs.entries) {
      test(entry.key, () {
        final (foreground, background) = entry.value;

        expect(
          contrastRatio(foreground, background),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });
}
