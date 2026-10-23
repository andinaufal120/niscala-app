import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure_mapper.dart';
import 'package:niscala/core/api/api_providers.dart';
import 'package:niscala_api/api.dart';

/// Room management. Every method throws an `ApiFailure` when the call fails.
abstract interface class RoomRepository {
  Future<List<RoomSummary>> list(String propertyId);

  Future<Room> get(String roomId);

  Future<Room> create(String propertyId, RoomInput input);

  Future<Room> update(String roomId, RoomInput input);

  Future<void> delete(String roomId);

  /// The facility tags already used on the rooms of the property's Owner.
  Future<List<String>> facilitySuggestions(String propertyId);
}

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiRoomRepository(rooms: RoomsApi(client));
});

/// The rooms of one property. Invalidate it after a change. Failures are not
/// retried in the background: the screen shows them and the user retries.
final roomListProvider = FutureProvider.family<List<RoomSummary>, String>(
  (ref, propertyId) => ref.watch(roomRepositoryProvider).list(propertyId),
  retry: (_, _) => null,
);

/// One room. Invalidate it after a change. Failures are not retried in the
/// background, see [roomListProvider].
final roomDetailProvider = FutureProvider.family<Room, String>(
  (ref, roomId) => ref.watch(roomRepositoryProvider).get(roomId),
  retry: (_, _) => null,
);

/// The facility suggestions of a property. Failures are not retried, and the
/// form shows no suggestions instead of an error.
final facilitySuggestionsProvider = FutureProvider.family<List<String>, String>(
  (ref, propertyId) =>
      ref.watch(roomRepositoryProvider).facilitySuggestions(propertyId),
  retry: (_, _) => null,
);

class ApiRoomRepository implements RoomRepository {
  ApiRoomRepository({required this.rooms});

  final RoomsApi rooms;

  @override
  Future<List<RoomSummary>> list(String propertyId) => _guard(() async {
    return (await rooms.listRooms(propertyId))!.items;
  });

  @override
  Future<Room> get(String roomId) => _guard(() async {
    return (await rooms.getRoom(roomId))!;
  });

  @override
  Future<Room> create(String propertyId, RoomInput input) => _guard(() async {
    return (await rooms.createRoom(propertyId, input))!;
  });

  @override
  Future<Room> update(String roomId, RoomInput input) => _guard(() async {
    return (await rooms.updateRoom(roomId, input))!;
  });

  @override
  Future<void> delete(String roomId) => _guard(() => rooms.deleteRoom(roomId));

  @override
  Future<List<String>> facilitySuggestions(String propertyId) =>
      _guard(() async {
        return (await rooms.listFacilitySuggestions(propertyId))!.items;
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Object catch (error) {
      throw toApiFailure(error);
    }
  }
}
