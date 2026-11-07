import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/health_repository.dart';
import 'package:niscala/core/api/server_status.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeHealthRepository health;
  late ProviderContainer container;

  ServerProblem? state() => container.read(serverStatusProvider);
  Future<void> check() => container.read(serverStatusProvider.notifier).check();

  setUp(() {
    health = FakeHealthRepository();
    container = ProviderContainer(
      overrides: [healthRepositoryProvider.overrideWithValue(health)],
    );
    addTearDown(container.dispose);
  });

  test('starts without a problem and without calling the server', () {
    expect(state(), isNull);
    expect(health.checks, 0);
  });

  test('stays without a problem when the check succeeds', () async {
    await check();

    expect(state(), isNull);
    expect(health.checks, 1);
  });

  test('reports no connection on a network failure', () async {
    health.script.always = const ApiFailure.network();

    await check();

    expect(state(), ServerProblem.noConnection);
  });

  test('reports the service as unavailable on a 503 failure', () async {
    health.script.always = const ApiFailure(code: 'UNKNOWN', statusCode: 503);

    await check();

    expect(state(), ServerProblem.unavailable);
  });

  test(
    'reports the service as unavailable on any other error status',
    () async {
      health.script.always = const ApiFailure(
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );

      await check();

      expect(state(), ServerProblem.unavailable);
    },
  );

  test('does not throw when the check fails', () async {
    health.script.always = const ApiFailure.network();

    await expectLater(check(), completes);
  });

  test('switches from no connection to unavailable', () async {
    health.script.queue.addAll([
      const ApiFailure.network(),
      const ApiFailure(code: 'UNKNOWN', statusCode: 503),
    ]);

    await check();
    expect(state(), ServerProblem.noConnection);
    await check();
    expect(state(), ServerProblem.unavailable);
  });

  test('switches from unavailable to no connection', () async {
    health.script.queue.addAll([
      const ApiFailure(code: 'UNKNOWN', statusCode: 503),
      const ApiFailure.network(),
    ]);

    await check();
    await check();

    expect(state(), ServerProblem.noConnection);
  });

  test('clears a no connection problem after a successful check', () async {
    health.script.queue.add(const ApiFailure.network());

    await check();
    expect(state(), ServerProblem.noConnection);
    await check();

    expect(state(), isNull);
  });

  test('clears an unavailable problem after a successful check', () async {
    health.script.queue.add(const ApiFailure(code: 'UNKNOWN', statusCode: 503));

    await check();
    expect(state(), ServerProblem.unavailable);
    await check();

    expect(state(), isNull);
  });

  test('keeps the problem while a later check is in flight', () async {
    health.script.queue.add(const ApiFailure.network());
    await check();
    final gate = Completer<void>();
    health.script.gate = gate;

    final pending = check();
    await Future<void>.delayed(Duration.zero);

    expect(state(), ServerProblem.noConnection);

    gate.complete();
    await pending;

    expect(state(), isNull);
  });

  test('stays without a problem while the first check is in flight', () async {
    final gate = Completer<void>();
    health.script.gate = gate;
    health.script.always = const ApiFailure.network();

    final pending = check();
    await Future<void>.delayed(Duration.zero);

    expect(state(), isNull);

    gate.complete();
    await pending;

    expect(state(), ServerProblem.noConnection);
  });

  test('concurrent checks share one request', () async {
    final gate = Completer<void>();
    health.script.gate = gate;

    final first = check();
    final second = check();
    final third = check();
    await Future<void>.delayed(Duration.zero);

    expect(health.checks, 1);

    gate.complete();
    await Future.wait([first, second, third]);

    expect(health.checks, 1);
  });

  test('concurrent checks all see the shared outcome', () async {
    final gate = Completer<void>();
    health.script.gate = gate;
    health.script.always = const ApiFailure.network();

    final first = check();
    final second = check();
    gate.complete();
    await Future.wait([first, second]);

    expect(state(), ServerProblem.noConnection);
  });

  test('sends a new request once the previous check has finished', () async {
    await check();
    await check();

    expect(health.checks, 2);
  });

  test('sends a new request after a failed check has finished', () async {
    health.script.queue.add(const ApiFailure.network());

    await check();
    await check();

    expect(health.checks, 2);
  });
}
