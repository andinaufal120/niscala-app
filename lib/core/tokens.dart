import 'package:flutter/material.dart';

/// The raw colours of the design.
abstract final class NiscalaColors {
  static const primary = Color(0xFF0E5E52);
  static const primaryStrong = Color(0xFF0A463D);
  static const primarySoft = Color(0xFFDDEEEA);
  static const ground = Color(0xFFF3F5F4);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF15211E);
  static const textSecondary = Color(0xFF34423E);
  static const textMuted = Color(0xFF50605B);
  static const textDisabled = Color(0xFF7D8C87);
  static const divider = Color(0xFFDCE3E0);
  static const controlBorder = Color(0xFFC9D3CF);
  static const fieldBorder = Color(0xFFA9B6B1);
  static const neutralSoft = Color(0xFFE7ECEA);
  static const danger = Color(0xFF9A3412);
  static const dangerSoft = Color(0xFFFBE4DA);
  static const onDangerSoft = Color(0xFF7A2A0C);
  static const warningSoft = Color(0xFFFDE7C7);
  static const onWarningSoft = Color(0xFF7C3A00);
  static const noticeSoft = Color(0xFFFDF3E1);
  static const noticeBorder = Color(0xFFF0D3A1);
  static const onNotice = Color(0xFF5C3A06);
  static const focus = Color(0xFFF6B44B);
  static const scrim = Color(0x8C15211E);
}

/// The spacing steps of the design, in logical pixels.
abstract final class NiscalaSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Space between a screen edge and its content.
  static const double gutter = 20;
}

/// The corner radii of the design, in logical pixels.
abstract final class NiscalaRadius {
  static const double badge = 6;
  static const double small = 10;
  static const double control = 12;
  static const double textarea = 14;
  static const double card = 16;
  static const double sheet = 24;
}

/// The colours of one badge. A badge without [border] has no outline.
@immutable
class BadgeColors {
  const BadgeColors({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;
}

const _soft = BadgeColors(
  background: NiscalaColors.primarySoft,
  foreground: NiscalaColors.primary,
);
const _warning = BadgeColors(
  background: NiscalaColors.warningSoft,
  foreground: NiscalaColors.onWarningSoft,
);
const _neutral = BadgeColors(
  background: NiscalaColors.neutralSoft,
  foreground: NiscalaColors.textSecondary,
);
const _good = BadgeColors(
  background: NiscalaColors.primarySoft,
  foreground: NiscalaColors.primaryStrong,
);

/// The non-Material design tokens: one badge colour pair per status value.
@immutable
class NiscalaTokens extends ThemeExtension<NiscalaTokens> {
  const NiscalaTokens({
    this.complaintNew = _soft,
    this.complaintInProgress = _warning,
    this.complaintDone = _neutral,
    this.urgencyHigh = const BadgeColors(
      background: NiscalaColors.danger,
      foreground: NiscalaColors.surface,
    ),
    this.urgencyMedium = _warning,
    this.urgencyLow = _neutral,
    this.paymentPaid = _good,
    this.paymentAwaitingVerification = _warning,
    this.paymentRejected = const BadgeColors(
      background: NiscalaColors.dangerSoft,
      foreground: NiscalaColors.onDangerSoft,
    ),
    this.paymentUnpaid = const BadgeColors(
      background: NiscalaColors.surface,
      foreground: NiscalaColors.textSecondary,
      border: NiscalaColors.textDisabled,
    ),
    this.classificationClassifying = _soft,
    this.classificationAwaiting = _warning,
    this.classificationNotClassified = _neutral,
    this.roomOccupied = _good,
    this.roomVacant = _neutral,
    this.tenantNotActivated = _warning,
    this.tenantActive = _good,
    this.category = _soft,
    this.readOnly = _warning,
  });

  final BadgeColors complaintNew;
  final BadgeColors complaintInProgress;
  final BadgeColors complaintDone;
  final BadgeColors urgencyHigh;
  final BadgeColors urgencyMedium;
  final BadgeColors urgencyLow;
  final BadgeColors paymentPaid;
  final BadgeColors paymentAwaitingVerification;
  final BadgeColors paymentRejected;
  final BadgeColors paymentUnpaid;
  final BadgeColors classificationClassifying;
  final BadgeColors classificationAwaiting;
  final BadgeColors classificationNotClassified;
  final BadgeColors roomOccupied;
  final BadgeColors roomVacant;
  final BadgeColors tenantNotActivated;
  final BadgeColors tenantActive;
  final BadgeColors category;
  final BadgeColors readOnly;

  /// The tokens of the theme in [context].
  static NiscalaTokens of(BuildContext context) =>
      Theme.of(context).extension<NiscalaTokens>()!;

  @override
  NiscalaTokens copyWith({
    BadgeColors? complaintNew,
    BadgeColors? complaintInProgress,
    BadgeColors? complaintDone,
    BadgeColors? urgencyHigh,
    BadgeColors? urgencyMedium,
    BadgeColors? urgencyLow,
    BadgeColors? paymentPaid,
    BadgeColors? paymentAwaitingVerification,
    BadgeColors? paymentRejected,
    BadgeColors? paymentUnpaid,
    BadgeColors? classificationClassifying,
    BadgeColors? classificationAwaiting,
    BadgeColors? classificationNotClassified,
    BadgeColors? roomOccupied,
    BadgeColors? roomVacant,
    BadgeColors? tenantNotActivated,
    BadgeColors? tenantActive,
    BadgeColors? category,
    BadgeColors? readOnly,
  }) => NiscalaTokens(
    complaintNew: complaintNew ?? this.complaintNew,
    complaintInProgress: complaintInProgress ?? this.complaintInProgress,
    complaintDone: complaintDone ?? this.complaintDone,
    urgencyHigh: urgencyHigh ?? this.urgencyHigh,
    urgencyMedium: urgencyMedium ?? this.urgencyMedium,
    urgencyLow: urgencyLow ?? this.urgencyLow,
    paymentPaid: paymentPaid ?? this.paymentPaid,
    paymentAwaitingVerification:
        paymentAwaitingVerification ?? this.paymentAwaitingVerification,
    paymentRejected: paymentRejected ?? this.paymentRejected,
    paymentUnpaid: paymentUnpaid ?? this.paymentUnpaid,
    classificationClassifying:
        classificationClassifying ?? this.classificationClassifying,
    classificationAwaiting:
        classificationAwaiting ?? this.classificationAwaiting,
    classificationNotClassified:
        classificationNotClassified ?? this.classificationNotClassified,
    roomOccupied: roomOccupied ?? this.roomOccupied,
    roomVacant: roomVacant ?? this.roomVacant,
    tenantNotActivated: tenantNotActivated ?? this.tenantNotActivated,
    tenantActive: tenantActive ?? this.tenantActive,
    category: category ?? this.category,
    readOnly: readOnly ?? this.readOnly,
  );

  /// Status colours do not animate between themes: the other tokens win.
  @override
  NiscalaTokens lerp(ThemeExtension<NiscalaTokens>? other, double t) =>
      other is NiscalaTokens ? other : this;
}
