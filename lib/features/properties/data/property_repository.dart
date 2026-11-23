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

  /// Replaces the property. [version] is the version the caller read; a stale
  /// one fails with `RESOURCE_VERSION_CONFLICT`.
  Future<Property> update(
    String id,
    PropertyInput input, {
    required int version,
  });

  Future<void> delete(String id);
}

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiPropertyRepository(properties: PropertiesApi(client));
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
  ApiPropertyRepository({required this.properties});

  final PropertiesApi properties;

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
  Future<Property> update(
    String id,
    PropertyInput input, {
    required int version,
  }) => _guard(() async {
    return (await properties.updateProperty(id, input, ifMatch: '"$version"'))!;
  });

  @override
  Future<void> delete(String id) => _guard(() => properties.deleteProperty(id));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
