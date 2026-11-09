import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/health_repository.dart';

/// Why the API cannot be used right now.
enum ServerProblem { noConnection, unavailable }

/// The server problem to show, or null while the last check succeeded.
final serverStatusProvider =
    NotifierProvider<ServerStatusController, ServerProblem?>(
      ServerStatusController.new,
    );

class ServerStatusController extends Notifier<ServerProblem?> {
  Future<void>? _checking;

  @override
  ServerProblem? build() => null;

  /// Checks the server. Concurrent calls share one request. The state keeps
  /// its previous value until the check finishes. Never throws.
  Future<void> check() => _checking ??= _check().whenComplete(() {
    _checking = null;
  });

  Future<void> _check() async {
    try {
      await ref.read(healthRepositoryProvider).check();
      state = null;
    } on Object catch (error) {
      final failure = toApiFailure(error);
      state = failure.code == 'NETWORK_ERROR'
          ? ServerProblem.noConnection
          : ServerProblem.unavailable;
    }
  }
}
