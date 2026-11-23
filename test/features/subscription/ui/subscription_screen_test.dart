import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/features/subscription/ui/downgrade_screen.dart';
import 'package:niscala/features/subscription/ui/subscription_screen.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/fakes.dart';
import 'subscription_ui_helpers.dart';

const _note =
    'Pembayaran dan perpanjangan otomatis dikelola Google Play. Batalkan '
    'kapan saja, paket tetap aktif sampai akhir periode.';

Future<void> _open(
  WidgetTester tester,
  FakeSubscriptionRepository subscriptions, {
  bool settle = true,
  bool largeText = false,
}) => pumpSubscriptionApp(
  tester,
  subscriptions,
  settle: settle,
  largeText: largeText,
);

FakeSubscriptionRepository _free() => FakeSubscriptionRepository();

FakeSubscriptionRepository _active({
  PlanCode plan = PlanCode.basic,
  SubscriptionPeriod period = SubscriptionPeriod.monthly,
  bool autoRenew = true,
  int propertyCount = 1,
  ScheduledDowngrade? scheduledDowngrade,
  SubscriptionOrder? openOrder,
}) => FakeSubscriptionRepository(
  subscription: makeActiveSubscription(
    planCode: plan,
    billingPeriod: period,
    autoRenew: autoRenew,
    propertyCount: propertyCount,
    scheduledDowngrade: scheduledDowngrade,
    openOrder: openOrder,
  ),
);

void main() {
  group('the screen', () {
    testWidgets('is titled Langganan as a heading', (tester) async {
      await _open(tester, _free());

      expect(find.byType(SubscriptionScreen), findsOneWidget);
      expect(currentPath(tester), subscriptionPath);
      expect(find.text('Langganan'), findsOneWidget);
      expectHeading(tester, 'Langganan');
    });

    testWidgets('covers the bottom navigation', (tester) async {
      await _open(tester, _free());

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Kembali returns to the Akun tab', (tester) async {
      await _open(tester, _free());

      await pressBack(tester);

      expect(currentPath(tester), '/akun');
      expect(find.byType(SubscriptionScreen), findsNothing);
    });

    testWidgets('loads the subscription and the plans once', (tester) async {
      final subscriptions = _free();
      await _open(tester, subscriptions);

      expect(subscriptions.subscriptionCalls, 1);
      expect(subscriptions.plansCalls, 1);
    });

    for (final entry in <String, FakeSubscriptionRepository Function()>{
      'a free subscription': _free,
      'an active subscription': _active,
      'a Pro subscription': () => _active(plan: PlanCode.pro),
    }.entries) {
      testWidgets('shows the Google Play note with ${entry.key}', (
        tester,
      ) async {
        await _open(tester, entry.value());

        expect(find.text(_note), findsOneWidget);
      });
    }

    testWidgets('shows the sections in order', (tester) async {
      await _open(tester, _free());

      final status = tester.getTopLeft(find.text('Status saat ini')).dy;
      final choose = tester.getTopLeft(find.text('Pilih paket')).dy;
      final chip = tester.getTopLeft(filterChip('Bulanan')).dy;
      final firstAction = tester.getTopLeft(find.text('Pilih Basic')).dy;
      expect(status, lessThan(choose));
      expect(choose, lessThan(chip));
      expect(chip, lessThan(firstAction));
    });

    testWidgets('announces both section titles as headings', (tester) async {
      await _open(tester, _free());

      expectHeading(tester, 'Status saat ini');
      expectHeading(tester, 'Pilih paket');
    });

    testWidgets('never shows an English term or null', (tester) async {
      await _open(
        tester,
        _active(
          scheduledDowngrade: makeScheduledDowngrade(),
          openOrder: makeSubscriptionOrder(planCode: PaidPlanCode.pro),
        ),
      );

      for (final term in [
        'Subscription',
        'Upgrade',
        'Downgrade',
        'Monthly',
        'Yearly',
        'null',
      ]) {
        expect(find.textContaining(term), findsNothing, reason: term);
      }
    });
  });

  group('loading and failure', () {
    testWidgets('shows a progress indicator labelled Memuat while loading', (
      tester,
    ) async {
      final subscriptions = _free()
        ..subscriptionScript.gate = Completer<void>();
      await _open(tester, subscriptions, settle: false);

      expectLoading(tester);
      expect(find.text('Status saat ini'), findsNothing);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('keeps loading while only the plans are missing', (
      tester,
    ) async {
      final subscriptions = _free()..plansScript.gate = Completer<void>();
      await _open(tester, subscriptions, settle: false);

      expectLoading(tester);
      expect(find.text('Pilih Basic'), findsNothing);
    });

    testWidgets('shows the content once loading finishes', (tester) async {
      final gate = Completer<void>();
      final subscriptions = _free()..subscriptionScript.gate = gate;
      await _open(tester, subscriptions, settle: false);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Status saat ini'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'shows the Indonesian message and a retry on a network failure',
      (tester) async {
        final subscriptions = _free()
          ..subscriptionScript.always = const ApiFailure.network();
        await _open(tester, subscriptions);

        expect(find.byType(ErrorView), findsOneWidget);
        expect(find.text(messageOfCode('NETWORK_ERROR')), findsOneWidget);
        expect(find.text('Coba lagi'), findsOneWidget);
        expect(find.text('Status saat ini'), findsNothing);
      },
    );

    testWidgets('shows the generic message for an unknown code', (
      tester,
    ) async {
      final subscriptions = _free()
        ..subscriptionScript.always = const ApiFailure(code: 'SOMETHING_NEW');
      await _open(tester, subscriptions);

      expect(find.text('Terjadi kesalahan. Coba lagi.'), findsOneWidget);
    });

    testWidgets('shows the error when only the plans fail', (tester) async {
      final subscriptions = _free()
        ..plansScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, subscriptions);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
      expect(find.text('Pilih Basic'), findsNothing);
    });

    testWidgets('Coba lagi loads the subscription again', (tester) async {
      final subscriptions = _free()
        ..subscriptionScript.queue.add(const ApiFailure.network());
      await _open(tester, subscriptions);
      expect(subscriptions.subscriptionCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(subscriptions.subscriptionCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Status saat ini'), findsOneWidget);
    });

    testWidgets('Coba lagi loads the plans again', (tester) async {
      final subscriptions = _free()
        ..plansScript.queue.add(const ApiFailure.network());
      await _open(tester, subscriptions);
      expect(subscriptions.plansCalls, 1);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(subscriptions.plansCalls, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text('Pilih Basic'), findsOneWidget);
    });

    testWidgets('keeps showing the failure when the retry fails too', (
      tester,
    ) async {
      final subscriptions = _free()
        ..subscriptionScript.always = const ApiFailure(code: 'INTERNAL_ERROR');
      await _open(tester, subscriptions);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text(messageOfCode('INTERNAL_ERROR')), findsOneWidget);
      expect(subscriptions.subscriptionCalls, 2);
    });
  });

  group('the current status of a free subscription', () {
    testWidgets('shows the free plan, the status and the property count', (
      tester,
    ) async {
      await _open(
        tester,
        FakeSubscriptionRepository(
          subscription: makeSubscription(propertyCount: 1),
        ),
      );

      expect(find.text('Paket Gratis'), findsAtLeastNWidgets(1));
      expect(find.text('Status: Gratis'), findsOneWidget);
      expect(find.text('Properti terpakai: 1'), findsOneWidget);
    });

    testWidgets('shows no end date, period or renewal', (tester) async {
      await _open(tester, _free());

      expect(find.textContaining('Aktif hingga'), findsNothing);
      expect(find.textContaining('Periode:'), findsNothing);
      expect(find.textContaining('Perpanjangan otomatis'), findsNothing);
      expect(find.text('Status: Aktif'), findsNothing);
    });

    testWidgets('shows the number of properties the owner has', (tester) async {
      await _open(
        tester,
        FakeSubscriptionRepository(
          subscription: makeSubscription(propertyCount: 4),
        ),
      );

      expect(find.text('Properti terpakai: 4'), findsOneWidget);
    });

    testWidgets('offers no cancel button and no open order', (tester) async {
      await _open(tester, _free());

      expect(find.text('Batalkan penurunan paket'), findsNothing);
      expect(find.textContaining('menunggu pembayaran'), findsNothing);
      expect(find.textContaining('Turun ke paket'), findsNothing);
    });
  });

  group('the current status of an active subscription', () {
    testWidgets('shows plan, status, end date, period and renewal', (
      tester,
    ) async {
      await _open(tester, _active());

      expect(find.text('Paket Basic'), findsAtLeastNWidgets(1));
      expect(find.text('Status: Aktif'), findsOneWidget);
      expect(find.text('Aktif hingga 15 Des 2026'), findsOneWidget);
      expect(find.text('Periode: Bulanan'), findsOneWidget);
      expect(find.text('Perpanjangan otomatis: Aktif'), findsOneWidget);
      expect(find.text('Properti terpakai: 1'), findsOneWidget);
      expect(find.text('Status: Gratis'), findsNothing);
    });

    testWidgets('shows a yearly period', (tester) async {
      await _open(tester, _active(period: SubscriptionPeriod.yearly));

      expect(find.text('Periode: Tahunan'), findsOneWidget);
      expect(find.text('Periode: Bulanan'), findsNothing);
    });

    testWidgets('says renewal is off when the owner cancelled it', (
      tester,
    ) async {
      await _open(tester, _active(autoRenew: false));

      expect(find.text('Perpanjangan otomatis: Tidak aktif'), findsOneWidget);
      expect(find.text('Perpanjangan otomatis: Aktif'), findsNothing);
    });

    testWidgets('shows the Pro plan', (tester) async {
      await _open(tester, _active(plan: PlanCode.pro, propertyCount: 5));

      expect(find.text('Paket Pro'), findsAtLeastNWidgets(1));
      expect(find.text('Properti terpakai: 5'), findsOneWidget);
    });

    testWidgets('shows the end date in the abbreviated Indonesian format', (
      tester,
    ) async {
      await _open(
        tester,
        FakeSubscriptionRepository(
          subscription: makeActiveSubscription(
            endDate: DateTime.utc(2027, 1, 5),
          ),
        ),
      );

      expect(find.text('Aktif hingga 5 Jan 2027'), findsOneWidget);
    });

    testWidgets('shows no scheduled downgrade or open order without one', (
      tester,
    ) async {
      await _open(tester, _active());

      expect(find.textContaining('Turun ke paket'), findsNothing);
      expect(find.text('Batalkan penurunan paket'), findsNothing);
      expect(find.textContaining('menunggu pembayaran'), findsNothing);
    });
  });

  group('a scheduled downgrade', () {
    testWidgets('shows the plan and the day it starts', (tester) async {
      await _open(
        tester,
        _active(
          plan: PlanCode.pro,
          scheduledDowngrade: makeScheduledDowngrade(
            planCode: PlanCode.basic,
            effectiveDate: DateTime.utc(2026, 12, 16),
          ),
        ),
      );

      expect(
        find.text('Turun ke paket Basic mulai 16 Des 2026'),
        findsOneWidget,
      );
      expect(find.text('Batalkan penurunan paket'), findsOneWidget);
    });

    testWidgets('names the free plan Gratis', (tester) async {
      await _open(
        tester,
        _active(scheduledDowngrade: makeScheduledDowngrade()),
      );

      expect(
        find.text('Turun ke paket Gratis mulai 16 Des 2026'),
        findsOneWidget,
      );
    });

    testWidgets('cancelling calls the API once and reloads the subscription', (
      tester,
    ) async {
      final subscriptions = _active(
        scheduledDowngrade: makeScheduledDowngrade(),
      );
      await _open(tester, subscriptions);

      await tap(tester, find.text('Batalkan penurunan paket'));

      expect(subscriptions.cancelCalls, 1);
      expect(subscriptions.subscriptionCalls, 2);
      expect(subscriptions.calls.last, 'subscription');
      expect(
        subscriptions.calls.indexOf('cancelDowngrade'),
        lessThan(subscriptions.calls.lastIndexOf('subscription')),
      );
    });

    testWidgets('cancelling removes the line and confirms in a SnackBar', (
      tester,
    ) async {
      await _open(
        tester,
        _active(scheduledDowngrade: makeScheduledDowngrade()),
      );

      await tap(tester, find.text('Batalkan penurunan paket'));

      expect(snackBar('Penurunan paket dibatalkan'), findsOneWidget);
      expect(find.textContaining('Turun ke paket'), findsNothing);
      expect(find.text('Batalkan penurunan paket'), findsNothing);
      expect(currentPath(tester), subscriptionPath);
    });
  });

  group('an open order', () {
    testWidgets('says the order waits for payment', (tester) async {
      await _open(
        tester,
        _active(
          openOrder: makeSubscriptionOrder(
            planCode: PaidPlanCode.pro,
            billingPeriod: SubscriptionPeriod.yearly,
          ),
        ),
      );

      expect(
        find.text('Pesanan paket Pro (Tahunan) menunggu pembayaran.'),
        findsOneWidget,
      );
    });

    testWidgets('names a monthly Basic order', (tester) async {
      await _open(
        tester,
        FakeSubscriptionRepository(
          subscription: makeSubscription(openOrder: makeSubscriptionOrder()),
        ),
      );

      expect(
        find.text('Pesanan paket Basic (Bulanan) menunggu pembayaran.'),
        findsOneWidget,
      );
    });
  });

  group('the plans of a free subscription', () {
    testWidgets('lists the free plan as current and the two paid plans', (
      tester,
    ) async {
      await _open(tester, _free());

      expect(find.text('Paket Anda'), findsOneWidget);
      expect(find.text('Pilih Basic'), findsOneWidget);
      expect(find.text('Pilih Pro'), findsOneWidget);
      expect(find.text('Pilih Gratis'), findsNothing);
    });

    testWidgets('lists the plans in the order free, basic, pro', (
      tester,
    ) async {
      await _open(tester, _free());

      expect(
        tester.getTopLeft(find.text('Paket Anda')).dy,
        lessThan(tester.getTopLeft(find.text('Pilih Basic')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Pilih Basic')).dy,
        lessThan(tester.getTopLeft(find.text('Pilih Pro')).dy),
      );
    });

    testWidgets('offers no way down and no lower plans', (tester) async {
      await _open(tester, _free());

      expect(find.textContaining('Lihat paket lebih rendah'), findsNothing);
      expect(
        find.textContaining('Sembunyikan paket lebih rendah'),
        findsNothing,
      );
      expect(find.textContaining('Turunkan ke'), findsNothing);
    });

    testWidgets('shows the monthly price of each plan by default', (
      tester,
    ) async {
      await _open(tester, _free());

      expect(find.text('Rp0'), findsOneWidget);
      expect(find.text('Rp49.000/bulan'), findsOneWidget);
      expect(find.text('Rp129.000/bulan'), findsOneWidget);
      expect(find.textContaining('/tahun'), findsNothing);
    });

    testWidgets('shows the property limit of each plan', (tester) async {
      await _open(tester, _free());

      expect(find.text('Maksimal 1 properti'), findsOneWidget);
      expect(find.text('Maksimal 3 properti'), findsOneWidget);
      expect(find.text('Jumlah properti tidak dibatasi'), findsOneWidget);
    });

    testWidgets('shows the room limit of each plan', (tester) async {
      await _open(tester, _free());

      expect(find.text('Maksimal 15 kamar per properti'), findsOneWidget);
      expect(find.text('Jumlah kamar tidak dibatasi'), findsNWidgets(2));
    });

    testWidgets('shows the AI features of the plans that have them', (
      tester,
    ) async {
      await _open(tester, _free());

      expect(find.text('Klasifikasi keluhan AI'), findsNWidgets(2));
      expect(find.text('Ringkasan pola pembayaran AI'), findsNWidgets(2));
      expect(find.text('Tanpa fitur AI'), findsOneWidget);
    });

    testWidgets('takes the limits and prices from the API data', (
      tester,
    ) async {
      final subscriptions = FakeSubscriptionRepository(
        plans: [
          makeSubscriptionPlan(
            code: PlanCode.free,
            maxProperties: 2,
            maxRoomsPerProperty: 9,
          ),
          makeSubscriptionPlan(
            code: PlanCode.basic,
            aiEnabled: true,
            maxProperties: 5,
            maxRoomsPerProperty: 20,
            prices: [
              makeSubscriptionPlanPrice(
                plan: PaidPlanCode.basic,
                period: SubscriptionPeriod.monthly,
                amount: 59000,
              ),
              makeSubscriptionPlanPrice(
                plan: PaidPlanCode.basic,
                period: SubscriptionPeriod.yearly,
                amount: 590000,
              ),
            ],
          ),
          makeSubscriptionPlan(
            code: PlanCode.pro,
            aiEnabled: true,
            prices: [
              makeSubscriptionPlanPrice(
                plan: PaidPlanCode.pro,
                period: SubscriptionPeriod.monthly,
                amount: 149000,
              ),
              makeSubscriptionPlanPrice(
                plan: PaidPlanCode.pro,
                period: SubscriptionPeriod.yearly,
                amount: 1490000,
              ),
            ],
          ),
        ],
      );
      await _open(tester, subscriptions);

      expect(find.text('Maksimal 2 properti'), findsOneWidget);
      expect(find.text('Maksimal 9 kamar per properti'), findsOneWidget);
      expect(find.text('Maksimal 5 properti'), findsOneWidget);
      expect(find.text('Maksimal 20 kamar per properti'), findsOneWidget);
      expect(find.text('Rp59.000/bulan'), findsOneWidget);
      expect(find.text('Rp149.000/bulan'), findsOneWidget);
      expect(find.text('Maksimal 3 properti'), findsNothing);
    });
  });

  group('the plans of an active subscription', () {
    testWidgets('Basic marks Basic as current and offers an upgrade to Pro', (
      tester,
    ) async {
      await _open(tester, _active());

      expect(find.text('Paket Anda'), findsOneWidget);
      expect(find.text('Pilih Pro'), findsOneWidget);
      expect(find.text('Pilih Basic'), findsNothing);
      expect(find.text('Pilih Gratis'), findsNothing);
    });

    testWidgets('Basic hides the free plan until asked', (tester) async {
      await _open(tester, _active());

      expect(find.text('Rp0'), findsNothing);
      expect(find.text('Maksimal 1 properti'), findsNothing);
      expect(find.text('Turunkan ke Gratis'), findsNothing);
      expect(find.text('Lihat paket lebih rendah (1)'), findsOneWidget);
    });

    testWidgets('Pro marks Pro as current and offers no purchase', (
      tester,
    ) async {
      await _open(tester, _active(plan: PlanCode.pro));

      expect(find.text('Paket Anda'), findsOneWidget);
      expect(find.textContaining('Pilih Basic'), findsNothing);
      expect(find.textContaining('Pilih Pro'), findsNothing);
      expect(find.text('Rp129.000/bulan'), findsOneWidget);
      expect(find.text('Rp49.000/bulan'), findsNothing);
    });

    testWidgets('Pro counts two lower plans', (tester) async {
      await _open(tester, _active(plan: PlanCode.pro));

      expect(find.text('Lihat paket lebih rendah (2)'), findsOneWidget);
    });

    testWidgets('the current plan card has no action button', (tester) async {
      await _open(tester, _active());

      expect(find.textContaining('Turunkan ke Basic'), findsNothing);
      expect(find.text('Pilih Basic'), findsNothing);
    });
  });

  group('the lower plans', () {
    testWidgets('the toggle shows the lower plans and changes its label', (
      tester,
    ) async {
      await _open(tester, _active(plan: PlanCode.pro));

      await tap(tester, find.text('Lihat paket lebih rendah (2)'));

      expect(find.text('Sembunyikan paket lebih rendah (2)'), findsOneWidget);
      expect(find.text('Lihat paket lebih rendah (2)'), findsNothing);
      expect(find.text('Turunkan ke Basic'), findsOneWidget);
      expect(find.text('Turunkan ke Gratis'), findsOneWidget);
      expect(find.text('Rp0'), findsOneWidget);
      expect(find.text('Rp49.000/bulan'), findsOneWidget);
    });

    testWidgets('the toggle hides them again', (tester) async {
      await _open(tester, _active(plan: PlanCode.pro));
      await tap(tester, find.text('Lihat paket lebih rendah (2)'));

      await tap(tester, find.text('Sembunyikan paket lebih rendah (2)'));

      expect(find.text('Lihat paket lebih rendah (2)'), findsOneWidget);
      expect(find.text('Turunkan ke Basic'), findsNothing);
      expect(find.text('Turunkan ke Gratis'), findsNothing);
    });

    testWidgets('a Basic subscription shows only the free plan below', (
      tester,
    ) async {
      await _open(tester, _active());

      await tap(tester, find.text('Lihat paket lebih rendah (1)'));

      expect(find.text('Sembunyikan paket lebih rendah (1)'), findsOneWidget);
      expect(find.text('Turunkan ke Gratis'), findsOneWidget);
      expect(find.text('Turunkan ke Basic'), findsNothing);
      expect(find.text('Maksimal 1 properti'), findsOneWidget);
    });

    testWidgets('toggling does not load again', (tester) async {
      final subscriptions = _active();
      await _open(tester, subscriptions);

      await tap(tester, find.text('Lihat paket lebih rendah (1)'));
      await tap(tester, find.text('Sembunyikan paket lebih rendah (1)'));

      expect(subscriptions.subscriptionCalls, 1);
      expect(subscriptions.plansCalls, 1);
    });

    testWidgets('Turunkan ke Gratis opens the downgrade page for free', (
      tester,
    ) async {
      await _open(tester, _active());
      await tap(tester, find.text('Lihat paket lebih rendah (1)'));

      await tap(tester, find.text('Turunkan ke Gratis'));

      expect(currentPath(tester), '$subscriptionPath/turunkan');
      expect(currentUri(tester).queryParameters['paket'], 'free');
      expect(find.byType(DowngradeScreen), findsOneWidget);
      expect(find.text('Turunkan ke Paket Gratis'), findsOneWidget);
    });

    testWidgets('Turunkan ke Basic opens the downgrade page for basic', (
      tester,
    ) async {
      await _open(tester, _active(plan: PlanCode.pro));
      await tap(tester, find.text('Lihat paket lebih rendah (2)'));

      await tap(tester, find.text('Turunkan ke Basic'));

      expect(currentUri(tester).queryParameters['paket'], 'basic');
      expect(find.byType(DowngradeScreen), findsOneWidget);
      expect(find.text('Turunkan ke Paket Basic'), findsOneWidget);
    });

    testWidgets('opening a downgrade does not create an order or a downgrade', (
      tester,
    ) async {
      final subscriptions = _active();
      await _open(tester, subscriptions);
      await tap(tester, find.text('Lihat paket lebih rendah (1)'));

      await tap(tester, find.text('Turunkan ke Gratis'));

      expect(subscriptions.createOrderCalls, 0);
      expect(subscriptions.scheduleCalls, 0);
    });
  });

  group('the period chips', () {
    testWidgets('offer Bulanan and Tahunan in the page body', (tester) async {
      await _open(tester, _free());

      for (final label in ['Bulanan', 'Tahunan']) {
        expect(filterChip(label), findsOneWidget);
        expect(
          find.descendant(of: find.byType(AppBar), matching: filterChip(label)),
          findsNothing,
        );
      }
      expect(
        find.byWidgetPredicate(
          (widget) => widget is ChoiceChip || widget is FilterChip,
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('Bulanan is selected by default', (tester) async {
      await _open(tester, _free());

      expectChipSelected(tester, 'Bulanan', selected: true);
      expectChipSelected(tester, 'Tahunan', selected: false);
    });

    testWidgets('every chip is at least 48 dp', (tester) async {
      await _open(tester, _free());

      for (final label in ['Bulanan', 'Tahunan']) {
        expectChipTargetSize(tester, label);
      }
    });

    testWidgets('every chip takes its look from the chip theme', (
      tester,
    ) async {
      await _open(tester, _free());

      for (final label in ['Bulanan', 'Tahunan']) {
        expectChipStyledByTheme(tester, label);
      }
    });

    testWidgets('Tahunan shows the yearly prices', (tester) async {
      await _open(tester, _free());

      await tester.tap(filterChip('Tahunan'));
      await tester.pumpAndSettle();

      expect(find.text('Rp490.000/tahun'), findsOneWidget);
      expect(find.text('Rp1.290.000/tahun'), findsOneWidget);
      expect(find.text('Rp0'), findsOneWidget);
      expect(find.textContaining('/bulan'), findsNothing);
      expectChipSelected(tester, 'Tahunan', selected: true);
      expectChipSelected(tester, 'Bulanan', selected: false);
    });

    testWidgets('Bulanan brings the monthly prices back', (tester) async {
      await _open(tester, _free());
      await tester.tap(filterChip('Tahunan'));
      await tester.pumpAndSettle();

      await tester.tap(filterChip('Bulanan'));
      await tester.pumpAndSettle();

      expect(find.text('Rp49.000/bulan'), findsOneWidget);
      expect(find.text('Rp129.000/bulan'), findsOneWidget);
      expect(find.textContaining('/tahun'), findsNothing);
    });

    testWidgets('switching updates in place without loading again', (
      tester,
    ) async {
      final subscriptions = _free();
      await _open(tester, subscriptions);

      await tester.tap(filterChip('Tahunan'));
      await tester.pumpAndSettle();

      expect(subscriptions.subscriptionCalls, 1);
      expect(subscriptions.plansCalls, 1);
      expect(subscriptions.createOrderCalls, 0);
      expect(currentPath(tester), subscriptionPath);
    });

    testWidgets('the yearly price also shows on the current plan card', (
      tester,
    ) async {
      await _open(tester, _active());

      await tester.tap(filterChip('Tahunan'));
      await tester.pumpAndSettle();

      expect(find.text('Rp490.000/tahun'), findsOneWidget);
      expect(find.text('Rp1.290.000/tahun'), findsOneWidget);
    });
  });

  group('accessibility', () {
    final states = <String, FakeSubscriptionRepository Function()>{
      'a free subscription': _free,
      'an active monthly subscription': _active,
      'an active yearly Pro subscription': () =>
          _active(plan: PlanCode.pro, period: SubscriptionPeriod.yearly),
      'renewal switched off': () => _active(autoRenew: false),
      'a scheduled downgrade': () =>
          _active(scheduledDowngrade: makeScheduledDowngrade()),
      'an open order': () => _active(openOrder: makeSubscriptionOrder()),
    };

    for (final entry in states.entries) {
      testWidgets('meets the guidelines with ${entry.key}', (tester) async {
        await _open(tester, entry.value());

        await expectMeetsA11yGuidelines(tester);
      });

      testWidgets('fits at large text with ${entry.key}', (tester) async {
        await _open(tester, entry.value(), largeText: true);

        expect(tester.takeException(), isNull);
        expect(find.byType(SubscriptionScreen), findsOneWidget);
      });
    }

    testWidgets('meets the guidelines with the lower plans shown', (
      tester,
    ) async {
      await _open(tester, _active(plan: PlanCode.pro));
      await tap(tester, find.text('Lihat paket lebih rendah (2)'));

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text with the lower plans shown', (
      tester,
    ) async {
      await _open(tester, _active(plan: PlanCode.pro), largeText: true);
      await tap(tester, find.text('Lihat paket lebih rendah (2)'));

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines with the yearly prices', (tester) async {
      await _open(tester, _free());
      await tester.tap(filterChip('Tahunan'));
      await tester.pumpAndSettle();

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('meets the guidelines while loading', (tester) async {
      final subscriptions = _free()
        ..subscriptionScript.gate = Completer<void>();
      await _open(tester, subscriptions, settle: false);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text while loading', (tester) async {
      final subscriptions = _free()
        ..subscriptionScript.gate = Completer<void>();
      await pumpSubscriptionApp(
        tester,
        subscriptions,
        settle: false,
        largeText: true,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('meets the guidelines with a failure', (tester) async {
      final subscriptions = _free()
        ..subscriptionScript.always = const ApiFailure.network();
      await _open(tester, subscriptions);

      await expectMeetsA11yGuidelines(tester);
    });

    testWidgets('fits at large text with a failure', (tester) async {
      final subscriptions = _free()
        ..subscriptionScript.always = const ApiFailure.network();
      await _open(tester, subscriptions, largeText: true);

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorView), findsOneWidget);
    });

    testWidgets(
      'each plan action has a spoken label that starts with its text',
      (tester) async {
        await _open(tester, _free());

        expect(
          semanticsLabelOf(tester, 'Pilih Basic'),
          startsWith('Pilih Basic'),
        );
        expect(semanticsLabelOf(tester, 'Pilih Pro'), startsWith('Pilih Pro'));
      },
    );
  });
}
