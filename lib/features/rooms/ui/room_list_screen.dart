import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/rooms/data/room_repository.dart';
import 'package:niscala/features/rooms/ui/room_widgets.dart';
import 'package:niscala_api/api.dart';

const _emptyWithoutName =
    'Belum ada kamar. Tambahkan kamar agar bisa mendaftarkan penyewa di '
    'properti ini.';
const _emptyFilter = 'Tidak ada kamar dengan status ini.';

const _filters = <(String, Occupancy?)>[
  ('Semua', null),
  ('Terisi', Occupancy.occupied),
  ('Kosong', Occupancy.vacant),
];

/// The rooms of one property. Filtering by occupancy happens on the loaded
/// list, so it never sends a request.
class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  /// Null shows every room.
  Occupancy? _filter;

  void _openAdd() => context.go('/properti/${widget.propertyId}/kamar/tambah');

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(propertyDetailProvider(widget.propertyId)).value;
    final name = property?.name;
    // A property that failed to load keeps the add action; the server still
    // enforces the view-only rule.
    final canAdd = property?.editable ?? true;
    final rooms = ref.watch(roomListProvider(widget.propertyId));
    return rooms.when(
      skipLoadingOnReload: true,
      loading: () => _page(
        name,
        const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
      ),
      error: (error, _) => _page(
        name,
        ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(roomListProvider(widget.propertyId)),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _page(
            name,
            EmptyState(
              message: name == null
                  ? _emptyWithoutName
                  : 'Belum ada kamar. Tambahkan kamar agar bisa mendaftarkan '
                        'penyewa di $name.',
              actionLabel: canAdd ? 'Tambah Kamar' : null,
              onAction: canAdd ? _openAdd : null,
            ),
          );
        }
        final shown = _filter == null
            ? items
            : items.where((room) => room.occupancy == _filter).toList();
        return _page(
          name,
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (canAdd) ...[
                FilledButton.icon(
                  onPressed: _openAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
                formGap,
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, occupancy) in _filters)
                    ChoiceChip(
                      label: Text(label),
                      selected: _filter == occupancy,
                      onSelected: (_) => setState(() => _filter = occupancy),
                    ),
                ],
              ),
              formGap,
              if (shown.isEmpty)
                Text(_emptyFilter, style: Theme.of(context).textTheme.bodyLarge)
              else
                for (final room in shown) ...[
                  _RoomRow(propertyId: widget.propertyId, room: room),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        );
      },
    );
  }
}

Scaffold _page(String? propertyName, Widget body) => Scaffold(
  appBar: AppBar(
    title: RoomTitle(title: 'Kamar', propertyName: propertyName),
  ),
  body: body,
);

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.propertyId, required this.room});

  final String propertyId;
  final RoomSummary room;

  /// The lease of an occupied room, or the dimensions and facilities of a
  /// vacant one. Null when there is nothing to show.
  String? get _detailLine {
    final lease = room.lease;
    if (room.occupancy == Occupancy.occupied) {
      if (lease == null) return null;
      final end = lease.endDate;
      return end == null
          ? lease.tenantName
          : '${lease.tenantName} · s.d. ${formatDate(end)}';
    }
    final length = room.lengthM;
    final width = room.widthM;
    final parts = [
      if (length != null && width != null) formatDimensions(length, width),
      if (room.facilities.isNotEmpty) room.facilities.join(', '),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detailLine;
    return Card(
      child: MergeSemantics(
        child: ListTile(
          onTap: () => context.go('/properti/$propertyId/kamar/${room.id}'),
          title: Text(
            room.number,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${formatRupiah(room.baseRate)} / bulan'),
              const SizedBox(height: 4),
              OccupancyBadge(occupancy: room.occupancy),
              if (detail != null) Text(detail),
              if (!room.editable) ...[
                const SizedBox(height: 4),
                const StatusBadge(
                  label: 'Hanya lihat',
                  tone: StatusTone.neutral,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
