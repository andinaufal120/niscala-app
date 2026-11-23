import 'dart:convert';
import 'dart:io';

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

http.Response _error(int status, String code) => http.Response(
  jsonEncode({'code': code, 'field': null, 'message': 'English text'}),
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

Matcher _failure(String code, {int? status}) => isA<ApiFailure>()
    .having((f) => f.code, 'code', code)
    .having((f) => f.statusCode, 'statusCode', status);

Map<String, dynamic> _asJson(Object value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  group('verifyPurchase', () {
    test('posts the purchase token to the verification of the order', () async {
      final h = _Harness(
        (_) =>
            _ok(_asJson(makeSubscriptionOrder(status: OrderStatus.succeeded))),
      );

      await h.repository.verifyPurchase(
        orderId: 'o1',
        purchaseToken: 'token-1',
      );

      expect(h.request.method, 'POST');
      expect(
        h.request.url.path,
        '/subscription/orders/o1/purchase-verification',
      );
      expect(h.request.headers['content-type'], contains('application/json'));
      expect(h.body, {'purchaseToken': 'token-1'});
    });

    test('puts the order id of the call in the path', () async {
      final h = _Harness((_) => _ok(_asJson(makeSubscriptionOrder(id: 'o77'))));

      await h.repository.verifyPurchase(
        orderId: 'o77',
        purchaseToken: 'token-9',
      );

      expect(
        h.request.url.path,
        '/subscription/orders/o77/purchase-verification',
      );
      expect(h.body, {'purchaseToken': 'token-9'});
    });

    test('sends no If-Match header', () async {
      final h = _Harness((_) => _ok(_asJson(makeSubscriptionOrder())));

      await h.repository.verifyPurchase(
        orderId: 'o1',
        purchaseToken: 'token-1',
      );

      expect(h.request.headers.containsKey('if-match'), isFalse);
    });

    test(
      'returns the order with its plan, period and Google Play fields',
      () async {
        final h = _Harness(
          (_) => _ok(
            _asJson(
              makeSubscriptionOrder(
                id: 'o5',
                planCode: PaidPlanCode.pro,
                billingPeriod: SubscriptionPeriod.yearly,
                status: OrderStatus.succeeded,
              ),
            ),
          ),
        );

        final order = await h.repository.verifyPurchase(
          orderId: 'o5',
          purchaseToken: 'token-1',
        );

        expect(order.id, 'o5');
        expect(order.planCode, PaidPlanCode.pro);
        expect(order.billingPeriod, SubscriptionPeriod.yearly);
        expect(order.status, OrderStatus.succeeded);
        expect(order.googlePlayProductId, 'niscala_pro');
        expect(order.googlePlayBasePlanId, 'yearly');
        expect(order.obfuscatedAccountId, 'obfuscated-o5');
      },
    );

    for (final status in OrderStatus.values) {
      test('returns an order that is ${status.value}', () async {
        final h = _Harness(
          (_) => _ok(_asJson(makeSubscriptionOrder(status: status))),
        );

        final order = await h.repository.verifyPurchase(
          orderId: 'o1',
          purchaseToken: 'token-1',
        );

        expect(order.status, status);
      });
    }

    for (final entry in {
      503: 'GOOGLE_PLAY_UNREACHABLE',
      409: 'SUBSCRIPTION_ORDER_CLOSED',
      410: 'PURCHASE_TOKEN_IN_USE',
      422: 'PURCHASE_TOKEN_INVALID',
      423: 'PURCHASE_PRODUCT_MISMATCH',
      404: 'SUBSCRIPTION_ORDER_NOT_FOUND',
      403: 'FORBIDDEN',
    }.entries) {
      test(
        'keeps the code and status ${entry.key} of ${entry.value}',
        () async {
          final h = _Harness((_) => _error(entry.key, entry.value));

          await expectLater(
            h.repository.verifyPurchase(orderId: 'o1', purchaseToken: 't'),
            throwsA(_failure(entry.value, status: entry.key)),
          );
        },
      );
    }

    test('keeps a 409 closed order and a 409 token in use apart', () async {
      final closed = _Harness((_) => _error(409, 'SUBSCRIPTION_ORDER_CLOSED'));
      final inUse = _Harness((_) => _error(409, 'PURCHASE_TOKEN_IN_USE'));

      await expectLater(
        closed.repository.verifyPurchase(orderId: 'o1', purchaseToken: 't'),
        throwsA(_failure('SUBSCRIPTION_ORDER_CLOSED', status: 409)),
      );
      await expectLater(
        inUse.repository.verifyPurchase(orderId: 'o1', purchaseToken: 't'),
        throwsA(_failure('PURCHASE_TOKEN_IN_USE', status: 409)),
      );
    });

    test('converts a transport error to a network failure', () async {
      final h = _Harness.failing(const SocketException('no route'));

      await expectLater(
        h.repository.verifyPurchase(orderId: 'o1', purchaseToken: 't'),
        throwsA(_failure('NETWORK_ERROR')),
      );
    });
  });
}
