import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/theme.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/tenants/ui/tenant_widgets.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';

final _tokens = buildTheme().extension<NiscalaTokens>()!;

Widget _badge(TenantAccountStatus status) =>
    themedApp(Scaffold(body: TenantStatusBadge(status: status)));

void main() {
  testWidgets('shows Aktif for an active account', (tester) async {
    await tester.pumpWidget(_badge(TenantAccountStatus.active));

    expect(find.text('Aktif'), findsOneWidget);
  });

  testWidgets('shows Belum Diaktifkan for an account not yet activated', (
    tester,
  ) async {
    await tester.pumpWidget(_badge(TenantAccountStatus.notActivated));

    expect(find.text('Belum Diaktifkan'), findsOneWidget);
  });

  testWidgets('colours an active account from the active token', (
    tester,
  ) async {
    await tester.pumpWidget(_badge(TenantAccountStatus.active));

    final colors = tester.widget<StatusBadge>(find.byType(StatusBadge)).colors;
    expect(colors.background, _tokens.tenantActive.background);
    expect(colors.foreground, _tokens.tenantActive.foreground);
    expect(colors.border, _tokens.tenantActive.border);
  });

  testWidgets('colours an inactive account from the not activated token', (
    tester,
  ) async {
    await tester.pumpWidget(_badge(TenantAccountStatus.notActivated));

    final colors = tester.widget<StatusBadge>(find.byType(StatusBadge)).colors;
    expect(colors.background, _tokens.tenantNotActivated.background);
    expect(colors.foreground, _tokens.tenantNotActivated.foreground);
    expect(colors.border, _tokens.tenantNotActivated.border);
  });

  testWidgets('shows the two states in different colours', (tester) async {
    await tester.pumpWidget(_badge(TenantAccountStatus.active));
    final active = tester.widget<StatusBadge>(find.byType(StatusBadge));
    await tester.pumpWidget(_badge(TenantAccountStatus.notActivated));
    final inactive = tester.widget<StatusBadge>(find.byType(StatusBadge));

    expect(active.colors.background, isNot(inactive.colors.background));
  });

  testWidgets('speaks its label', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_badge(TenantAccountStatus.notActivated));

      expect(find.bySemanticsLabel('Belum Diaktifkan'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    await tester.pumpWidget(_badge(TenantAccountStatus.notActivated));

    await expectMeetsA11yGuidelines(tester);
  });

  testWidgets('fits at large text size', (tester) async {
    await pumpAtLargeText(tester, _badge(TenantAccountStatus.notActivated));

    expect(tester.takeException(), isNull);
  });
}
