import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/features/subscription/data/subscription_repository.dart';
import 'package:niscala_api/api.dart';

import '../../../helpers/fakes.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

http.Response _ok(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: _json);

http.Response _error(int status, String code, {String? field}) => http.Response(
  jsonEncode({'code': code, 'field': field, 'message': 'English text'}),
  status,
  headers: _json,
);

class _Harness {
  _Harness(http.Response Function(http.Request request) respond) {
    _build(
      MockClient((request) async {
        requests.add(request);
        return respond(request);
      }),
    );
  }

  _Harness.failing(Object error) {
    _build(
      MockClient((request) async {
        requests.add(request);
        throw error;
      }),
    );
  }

  void _build(http.Client client) {
    final apiClient = ApiClient(basePath: 'http://api.test')..client = client;
    repository = ApiSubscriptionRepository(
      subscriptions: SubscriptionsApi(apiClient),
    );
  }

  final requests = <http.Request>[];
  late final ApiSubscriptionRepository repository;

  http.Request get request => requests.single;
  Map<String, dynamic> get body =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

Matcher _failure(String code, {String? field, int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.field, 'field', field)
    .having((f) => f.statusCode, 'statusCode', status);

Map<String, dynamic> _asJson(Object value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  group('subscription', () {
    test('gets the free subscription from /subscription', () async {
      final h = _Harness((_) => _ok(_asJson(makeSubscription())));

      final result = await h.repository.subscription();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/subscription');
      expect(result.status, SubscriptionStatus.free);
      expect(result.planCode, PlanCode.free);
      expect(result.billingPeriod, isNull);
      expect(result.endDate, isNull);
      expect(result.autoRenew, isFalse);
      expect(result.propertyCount, 1);
      expect(result.scheduledDowngrade, isNull);
      expect(result.openOrder, isNull);
    });

    test('gets an active subscription with its dates and period', () async {
      final h = _Harness(
        (_) => _ok(
          _asJson(
            makeActiveSubscription(
              planCode: PlanCode.pro,
              billingPeriod: SubscriptionPeriod.yearly,
              autoRenew: false,
              propertyCount: 4,
            ),
          ),
        ),
      );

      final result = await h.repository.subscription();

      expect(result.status, SubscriptionStatus.active);
      expect(result.planCode, PlanCode.pro);
      expect(result.billingPeriod, SubscriptionPeriod.yearly);
      expect(result.endDate, DateTime.utc(2026, 12, 15));
      expect(result.autoRenew, isFalse);
      expect(result.propertyCount, 4);
    });

    test('gets the scheduled downgrade and the open order', () async {
      final h = _Harness(
        (_) => _ok(
          _asJson(
            makeActiveSubscription(
              planCode: PlanCode.pro,
              scheduledDowngrade: makeScheduledDowngrade(
                planCode: PlanCode.free,
                keptPropertyIds: ['p1'],
                keptRoomIds: ['r1', 'r2'],
              ),
              openOrder: makeSubscriptionOrder(
                id: 'o9',
                planCode: PaidPlanCode.pro,
                billingPeriod: SubscriptionPeriod.yearly,
              ),
            ),
          ),
        ),
      );

      final result = await h.repository.subscription();

      final downgrade = result.scheduledDowngrade!;
      expect(downgrade.planCode, PlanCode.free);
      expect(downgrade.effectiveDate, DateTime.utc(2026, 12, 16));
      expect(downgrade.keptPropertyIds, ['p1']);
      expect(downgrade.keptRoomIds, ['r1', 'r2']);
      final order = result.openOrder!;
      expect(order.id, 'o9');
      expect(order.planCode, PaidPlanCode.pro);
      expect(order.billingPeriod, SubscriptionPeriod.yearly);
      expect(order.status, OrderStatus.awaitingPayment);
    });

    test('sends no body and no If-Match header', () async {
      final h = _Harness((_) => _ok(_asJson(makeSubscription())));

      await h.repository.subscription();

      expect(h.request.body, isEmpty);
      expect(h.request.headers.containsKey('if-match'), isFalse);
    });

    test('keeps the code and status of an error response', () async {
      final h = _Harness((_) => _error(403, 'FORBIDDEN'));

      await expectLater(
        h.repository.subscription(),
        throwsA(_failure('FORBIDDEN', status: 403)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.subscription(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('plans', () {
    test('gets /subscription-plans and unwraps the items in order', () async {
      final h = _Harness(
        (_) => _ok({'items': makeSubscriptionPlans().map(_asJson).toList()}),
      );

      final result = await h.repository.plans();

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/subscription-plans');
      expect(result.map((p) => p.code), [
        PlanCode.free,
        PlanCode.basic,
        PlanCode.pro,
      ]);
    });

    test('keeps limits, null limits, AI and prices of every plan', () async {
      final h = _Harness(
        (_) => _ok({'items': makeSubscriptionPlans().map(_asJson).toList()}),
      );

      final result = await h.repository.plans();

      final free = result[0];
      expect(free.maxProperties, 1);
      expect(free.maxRoomsPerProperty, 15);
      expect(free.aiEnabled, isFalse);
      expect(free.prices, isEmpty);
      final basic = result[1];
      expect(basic.maxProperties, 3);
      expect(basic.maxRoomsPerProperty, isNull);
      expect(basic.aiEnabled, isTrue);
      expect(basic.prices.map((p) => p.billingPeriod), [
        SubscriptionPeriod.monthly,
        SubscriptionPeriod.yearly,
      ]);
      expect(basic.prices.map((p) => p.amount), [49000, 490000]);
      expect(basic.prices.first.googlePlayProductId, 'niscala_basic');
      final pro = result[2];
      expect(pro.maxProperties, isNull);
      expect(pro.maxRoomsPerProperty, isNull);
      expect(pro.prices.map((p) => p.amount), [129000, 1290000]);
    });

    test('returns an empty list when the API lists no plans', () async {
      final h = _Harness((_) => _ok({'items': []}));

      expect(await h.repository.plans(), isEmpty);
    });

    test('keeps the code and status of an error response', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.plans(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.plans(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('createOrder', () {
    test('posts the plan and period to /subscription/orders', () async {
      final h = _Harness(
        (_) => _ok(
          _asJson(
            makeSubscriptionOrder(
              planCode: PaidPlanCode.pro,
              billingPeriod: SubscriptionPeriod.yearly,
            ),
          ),
          201,
        ),
      );

      final order = await h.repository.createOrder(
        planCode: PaidPlanCode.pro,
        billingPeriod: SubscriptionPeriod.yearly,
      );

      expect(h.request.method, 'POST');
      expect(h.request.url.path, '/subscription/orders');
      expect(h.request.headers['content-type'], contains('application/json'));
      expect(h.body, {'planCode': 'pro', 'billingPeriod': 'yearly'});
      expect(order.planCode, PaidPlanCode.pro);
      expect(order.billingPeriod, SubscriptionPeriod.yearly);
    });

    test('sends the wire value of a monthly basic plan', () async {
      final h = _Harness((_) => _ok(_asJson(makeSubscriptionOrder()), 201));

      await h.repository.createOrder(
        planCode: PaidPlanCode.basic,
        billingPeriod: SubscriptionPeriod.monthly,
      );

      expect(h.body, {'planCode': 'basic', 'billingPeriod': 'monthly'});
    });

    test('returns the order with its Google Play fields and status', () async {
      final h = _Harness((_) => _ok(_asJson(makeSubscriptionOrder()), 201));

      final order = await h.repository.createOrder(
        planCode: PaidPlanCode.basic,
        billingPeriod: SubscriptionPeriod.monthly,
      );

      expect(order.id, 'o1');
      expect(order.status, OrderStatus.awaitingPayment);
      expect(order.googlePlayProductId, 'niscala_basic');
      expect(order.googlePlayBasePlanId, 'monthly');
      expect(order.obfuscatedAccountId, 'obfuscated-o1');
      expect(order.createdAt, DateTime.utc(2026, 11, 23, 12));
    });

    test('sends no If-Match header', () async {
      final h = _Harness((_) => _ok(_asJson(makeSubscriptionOrder()), 201));

      await h.repository.createOrder(
        planCode: PaidPlanCode.basic,
        billingPeriod: SubscriptionPeriod.monthly,
      );

      expect(h.request.headers.containsKey('if-match'), isFalse);
    });

    test('keeps the code and status of a rejected upgrade', () async {
      final h = _Harness((_) => _error(409, 'SUBSCRIPTION_NOT_AN_UPGRADE'));

      await expectLater(
        h.repository.createOrder(
          planCode: PaidPlanCode.basic,
          billingPeriod: SubscriptionPeriod.monthly,
        ),
        throwsA(_failure('SUBSCRIPTION_NOT_AN_UPGRADE', status: 409)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.createOrder(
          planCode: PaidPlanCode.basic,
          billingPeriod: SubscriptionPeriod.monthly,
        ),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('order', () {
    test('gets /subscription/orders/{id}', () async {
      final h = _Harness(
        (_) => _ok(
          _asJson(
            makeSubscriptionOrder(id: 'o7', status: OrderStatus.succeeded),
          ),
        ),
      );

      final order = await h.repository.order('o7');

      expect(h.request.method, 'GET');
      expect(h.request.url.path, '/subscription/orders/o7');
      expect(order.id, 'o7');
      expect(order.status, OrderStatus.succeeded);
    });

    test('keeps the code and status of an unknown order', () async {
      final h = _Harness((_) => _error(404, 'SUBSCRIPTION_ORDER_NOT_FOUND'));

      await expectLater(
        h.repository.order('missing'),
        throwsA(_failure('SUBSCRIPTION_ORDER_NOT_FOUND', status: 404)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.order('o1'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('scheduleDowngrade', () {
    http.Response downgradeResponse() => _ok(
      _asJson(
        makeScheduledDowngrade(
          planCode: PlanCode.free,
          keptPropertyIds: ['p1'],
          keptRoomIds: ['r1', 'r2'],
        ),
      ),
    );

    test('puts the plan and kept ids to the scheduled downgrade', () async {
      final h = _Harness((_) => downgradeResponse());

      final result = await h.repository.scheduleDowngrade(
        planCode: PlanCode.free,
        keptPropertyIds: ['p1'],
        keptRoomIds: ['r1', 'r2'],
      );

      expect(h.request.method, 'PUT');
      expect(h.request.url.path, '/subscription/scheduled-downgrade');
      expect(h.request.headers['content-type'], contains('application/json'));
      expect(h.body, {
        'planCode': 'free',
        'keptPropertyIds': ['p1'],
        'keptRoomIds': ['r1', 'r2'],
      });
      expect(result.planCode, PlanCode.free);
      expect(result.effectiveDate, DateTime.utc(2026, 12, 16));
      expect(result.keptPropertyIds, ['p1']);
      expect(result.keptRoomIds, ['r1', 'r2']);
    });

    test('sends an empty room list for a downgrade to basic', () async {
      final h = _Harness(
        (_) => _ok(
          _asJson(
            makeScheduledDowngrade(
              planCode: PlanCode.basic,
              keptPropertyIds: ['p1', 'p2', 'p3'],
            ),
          ),
        ),
      );

      await h.repository.scheduleDowngrade(
        planCode: PlanCode.basic,
        keptPropertyIds: ['p1', 'p2', 'p3'],
        keptRoomIds: [],
      );

      expect(h.body, {
        'planCode': 'basic',
        'keptPropertyIds': ['p1', 'p2', 'p3'],
        'keptRoomIds': <String>[],
      });
    });

    test('sends no If-Match header', () async {
      final h = _Harness((_) => downgradeResponse());

      await h.repository.scheduleDowngrade(
        planCode: PlanCode.free,
        keptPropertyIds: ['p1'],
        keptRoomIds: [],
      );

      expect(h.request.headers.containsKey('if-match'), isFalse);
    });

    for (final code in [
      'KEPT_PROPERTIES_INVALID',
      'KEPT_ROOMS_INVALID',
      'SUBSCRIPTION_NOT_A_DOWNGRADE',
    ]) {
      test('keeps the code and status of $code', () async {
        final h = _Harness((_) => _error(422, code));

        await expectLater(
          h.repository.scheduleDowngrade(
            planCode: PlanCode.free,
            keptPropertyIds: ['p1'],
            keptRoomIds: [],
          ),
          throwsA(_failure(code, status: 422)),
        );
      });
    }

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.scheduleDowngrade(
          planCode: PlanCode.free,
          keptPropertyIds: ['p1'],
          keptRoomIds: [],
        ),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('cancelDowngrade', () {
    test('deletes the scheduled downgrade without a body', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.cancelDowngrade();

      expect(h.request.method, 'DELETE');
      expect(h.request.url.path, '/subscription/scheduled-downgrade');
      expect(h.request.body, isEmpty);
    });

    test('sends no If-Match header', () async {
      final h = _Harness((_) => http.Response('', 204));

      await h.repository.cancelDowngrade();

      expect(h.request.headers.containsKey('if-match'), isFalse);
    });

    test('keeps the code and status of an error response', () async {
      final h = _Harness((_) => _error(500, 'INTERNAL_ERROR'));

      await expectLater(
        h.repository.cancelDowngrade(),
        throwsA(_failure('INTERNAL_ERROR', status: 500)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.cancelDowngrade(),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });

  group('providers', () {
    test(
      'subscriptionProvider reads the subscription of the repository',
      () async {
        final fake = FakeSubscriptionRepository(
          subscription: makeActiveSubscription(planCode: PlanCode.pro),
        );
        final container = ProviderContainer(
          overrides: [subscriptionRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final result = await container.read(subscriptionProvider.future);

        expect(result.planCode, PlanCode.pro);
        expect(fake.subscriptionCalls, 1);
      },
    );

    test(
      'subscriptionPlansProvider reads the plans of the repository',
      () async {
        final fake = FakeSubscriptionRepository();
        final container = ProviderContainer(
          overrides: [subscriptionRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final result = await container.read(subscriptionPlansProvider.future);

        expect(result.map((p) => p.code), [
          PlanCode.free,
          PlanCode.basic,
          PlanCode.pro,
        ]);
        expect(fake.plansCalls, 1);
      },
    );

    test(
      'subscriptionProvider surfaces the failure of the repository',
      () async {
        final fake = FakeSubscriptionRepository()
          ..subscriptionScript.always = const ApiFailure(
            code: 'INTERNAL_ERROR',
          );
        final container = ProviderContainer(
          overrides: [subscriptionRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        await expectLater(
          container.read(subscriptionProvider.future),
          throwsA(_failure('INTERNAL_ERROR')),
        );
      },
    );

    test(
      'subscriptionPlansProvider surfaces the failure of the repository',
      () async {
        final fake = FakeSubscriptionRepository()
          ..plansScript.always = const ApiFailure.network();
        final container = ProviderContainer(
          overrides: [subscriptionRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        await expectLater(
          container.read(subscriptionPlansProvider.future),
          throwsA(_failure('NETWORK_ERROR')),
        );
      },
    );
  });
}
