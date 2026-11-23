import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/navigation.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/rooms/data/room_repository.dart';
import 'package:niscala/features/subscription/data/subscription_repository.dart';
import 'package:niscala/features/subscription/subscription_labels.dart';
import 'package:niscala_api/api.dart';

const _subscriptionPath = '/akun/langganan';
const _noPaidPlan = 'Tidak ada langganan berbayar yang bisa diturunkan.';
const _renewalNote =
    'Perpanjangan dikelola di Google Play: ubah atau batalkan langganan di '
    'sana.';
const _keptProperties = 'Properti yang tetap bisa diubah';
const _keptRooms = 'Kamar yang tetap bisa diubah';

/// The plan of a downgrade page, read from the `paket` query, or null when a
/// downgrade cannot go to it.
PlanCode? downgradePlanOf(String? paket) => switch (paket) {
  'free' => PlanCode.free,
  'basic' => PlanCode.basic,
  _ => null,
};

/// Picks the properties and, for a plan with a room limit, the rooms that stay
/// editable when the Owner downgrades to [planCode].
class DowngradeScreen extends ConsumerStatefulWidget {
  const DowngradeScreen({super.key, required this.planCode});

  final PlanCode planCode;

  @override
  ConsumerState<DowngradeScreen> createState() => _DowngradeScreenState();
}

class _DowngradeScreenState extends ConsumerState<DowngradeScreen> {
  /// The properties the Owner ticked. Null until the Owner ticks one: then the
  /// default applies, see [_form].
  Set<String>? _chosenProperties;

  /// The rooms the Owner ticked for the chosen property. Reset when the
  /// property changes.
  Set<String>? _chosenRooms;
  String? _error;
  var _saving = false;

  Future<void> _submit(_Keep keep) async {
    final problem = keep.problem;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .scheduleDowngrade(
            planCode: widget.planCode,
            keptPropertyIds: keep.propertyIds.toList(),
            keptRoomIds: keep.roomIds.toList(),
          );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorMessageFor(failure);
      });
      return;
    }
    if (!mounted) return;
    ref.invalidate(subscriptionProvider);
    final messenger = ScaffoldMessenger.of(context);
    leavePage(context, _subscriptionPath);
    messenger.showSnackBar(
      const SnackBar(content: Text('Penurunan paket dijadwalkan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    final plans = ref.watch(subscriptionPlansProvider);
    final properties = ref.watch(propertyListProvider);
    return Scaffold(
      appBar: DetailAppBar(
        title: 'Turunkan ke Paket ${planName(widget.planCode.value)}',
      ),
      body: _body(subscription, plans, properties),
    );
  }

  Widget _body(
    AsyncValue<Subscription> subscription,
    AsyncValue<List<SubscriptionPlan>> plans,
    AsyncValue<List<PropertySummary>> properties,
  ) {
    if (subscription.hasError) {
      return ErrorView(
        message: errorMessageFor(subscription.error!),
        onRetry: () => ref.invalidate(subscriptionProvider),
      );
    }
    if (plans.hasError) {
      return ErrorView(
        message: errorMessageFor(plans.error!),
        onRetry: () => ref.invalidate(subscriptionPlansProvider),
      );
    }
    if (properties.hasError) {
      return ErrorView(
        message: errorMessageFor(properties.error!),
        onRetry: () => ref.invalidate(propertyListProvider),
      );
    }
    final current = subscription.value;
    final planList = plans.value;
    final owned = properties.value;
    if (current == null || planList == null || owned == null) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
      );
    }
    if (current.status == SubscriptionStatus.free) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(NiscalaSpacing.gutter),
        child: Text(_noPaidPlan),
      );
    }
    final target = planList.firstWhere((plan) => plan.code == widget.planCode);
    return _form(current, target, owned);
  }

  Widget _form(
    Subscription current,
    SubscriptionPlan target,
    List<PropertySummary> owned,
  ) {
    final propertyLimit = target.maxProperties ?? owned.length;
    final keptProperties =
        _chosenProperties ??
        (owned.length <= propertyLimit
            ? {for (final property in owned) property.id}
            : <String>{});
    final roomLimit = target.maxRoomsPerProperty;
    final propertyId = roomLimit != null && keptProperties.length == 1
        ? keptProperties.single
        : null;
    final rooms = propertyId == null
        ? null
        : ref.watch(roomListProvider(propertyId));
    final loadedRooms = rooms?.value;
    // Saving waits until the rooms of the chosen property have loaded.
    final keep = rooms != null && loadedRooms == null
        ? null
        : _Keep(
            propertyIds: keptProperties,
            propertyCount: math.min(propertyLimit, owned.length),
            roomIds: loadedRooms == null
                ? const {}
                : _keptRoomIds(loadedRooms, roomLimit!),
            roomCount: loadedRooms == null
                ? null
                : math.min(roomLimit!, loadedRooms.length),
          );
    final endDate = current.endDate!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Penurunan paket berlaku setelah periode berjalan berakhir pada '
            '${formatDate(endDate)}. Yang tidak dipilih hanya bisa dilihat, '
            'tidak bisa diubah.',
          ),
          formGap,
          const Text(_renewalNote),
          formGap,
          SectionCard(
            title: owned.length <= propertyLimit
                ? _keptProperties
                : 'Pilih $propertyLimit properti yang tetap bisa diubah',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final property in owned)
                  CheckboxListTile(
                    value: keptProperties.contains(property.id),
                    onChanged: (checked) => _toggleProperty(
                      property.id,
                      checked ?? false,
                      keptProperties,
                    ),
                    title: Text(property.name),
                    subtitle: Text('${property.roomCount} kamar'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          formGap,
          if (propertyId != null && rooms != null) ...[
            _roomsSection(propertyId, roomLimit!, rooms),
            formGap,
          ],
          if (_error != null) ...[FormMessage(_error!), formGap],
          BusyButton(
            label: 'Simpan penurunan paket',
            busy: _saving,
            onPressed: keep == null ? null : () => _submit(keep),
          ),
          const SizedBox(height: NiscalaSpacing.s),
          OutlinedButton(
            onPressed: _saving
                ? null
                : () => leavePage(context, _subscriptionPath),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  /// The rooms of the chosen property. A plan with at most [roomLimit] rooms
  /// keeps them all unless the Owner changes the choice.
  Widget _roomsSection(
    String propertyId,
    int roomLimit,
    AsyncValue<List<RoomSummary>> rooms,
  ) {
    if (rooms.hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormMessage(errorMessageFor(rooms.error!)),
          formGap,
          FilledButton(
            onPressed: () => ref.invalidate(roomListProvider(propertyId)),
            child: const Text('Coba lagi'),
          ),
        ],
      );
    }
    final list = rooms.value;
    if (list == null) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
      );
    }
    final kept = _keptRoomIds(list, roomLimit);
    return SectionCard(
      title: list.length <= roomLimit
          ? _keptRooms
          : 'Pilih $roomLimit kamar yang tetap bisa diubah',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final room in list)
            CheckboxListTile(
              value: kept.contains(room.id),
              onChanged: (checked) =>
                  _toggleRoom(room.id, checked ?? false, kept),
              title: Text(
                'Kamar ${room.number}, '
                '${room.occupancy == Occupancy.occupied ? 'terisi' : 'kosong'}',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  /// The rooms kept by the Owner's choice, or by default: all of them when the
  /// property has no more than [limit] rooms, none otherwise.
  Set<String> _keptRoomIds(List<RoomSummary> rooms, int limit) =>
      _chosenRooms ??
      (rooms.length <= limit
          ? {for (final room in rooms) room.id}
          : <String>{});

  void _toggleProperty(String id, bool checked, Set<String> kept) {
    setState(() {
      final next = {...kept};
      if (checked) {
        next.add(id);
      } else {
        next.remove(id);
      }
      _chosenProperties = next;
      _chosenRooms = null;
    });
  }

  void _toggleRoom(String id, bool checked, Set<String> kept) {
    setState(() {
      final next = {...kept};
      if (checked) {
        next.add(id);
      } else {
        next.remove(id);
      }
      _chosenRooms = next;
    });
  }
}

/// What the Owner keeps, with the counts the plan requires. [roomCount] is null
/// when the plan has no room limit to apply.
class _Keep {
  const _Keep({
    required this.propertyIds,
    required this.propertyCount,
    required this.roomIds,
    required this.roomCount,
  });

  final Set<String> propertyIds;
  final int propertyCount;
  final Set<String> roomIds;
  final int? roomCount;

  /// The reason the choice does not fit the plan, or null when it fits.
  String? get problem {
    if (propertyIds.length != propertyCount) {
      return 'Pilih tepat $propertyCount properti.';
    }
    final rooms = roomCount;
    if (rooms != null && roomIds.length != rooms) {
      return 'Pilih tepat $rooms kamar.';
    }
    return null;
  }
}
