import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// Property management. Every method throws an `ApiFailure` when the call
/// fails.
abstract interface class PropertyRepository {
  Future<List<PropertySummary>> list();

  Future<Property> get(String id);

  Future<Property> create(PropertyInput input);

  Future<Property> update(String id, PropertyInput input);

  Future<void> delete(String id);

  /// Confirms the caller's password, which the API asks for before a change
  /// that needs a recent re-authentication.
  Future<void> reauthenticateWithPassword(String password);
}

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiPropertyRepository(
    properties: PropertiesApi(client),
    account: AccountApi(client),
  );
});

/// The properties the caller can see. Invalidate it after a change. Failures
/// are not retried in the background: the screen shows them and the user
/// retries.
final propertyListProvider = FutureProvider<List<PropertySummary>>(
  (ref) => ref.watch(propertyRepositoryProvider).list(),
  retry: (_, _) => null,
);

/// One property. Invalidate it after a change. Failures are not retried in
/// the background, see [propertyListProvider].
final propertyDetailProvider = FutureProvider.family<Property, String>(
  (ref, id) => ref.watch(propertyRepositoryProvider).get(id),
  retry: (_, _) => null,
);

class ApiPropertyRepository implements PropertyRepository {
  ApiPropertyRepository({required this.properties, required this.account});

  final PropertiesApi properties;
  final AccountApi account;

  @override
  Future<List<PropertySummary>> list() => _guard(() async {
    return (await properties.listProperties())!.items;
  });

  @override
  Future<Property> get(String id) => _guard(() async {
    return (await properties.getProperty(id))!;
  });

  @override
  Future<Property> create(PropertyInput input) => _guard(() async {
    return (await properties.createProperty(input))!;
  });

  @override
  Future<Property> update(String id, PropertyInput input) => _guard(() async {
    return (await properties.updateProperty(id, input))!;
  });

  @override
  Future<void> delete(String id) => _guard(() => properties.deleteProperty(id));

  @override
  Future<void> reauthenticateWithPassword(String password) => _guard(() async {
    await account.reauthenticateWithPassword(
      ReauthenticationPasswordInput(password: password),
    );
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
