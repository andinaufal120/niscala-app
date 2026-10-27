import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/dashboard/data/dashboard_repository.dart';
import 'package:niscala/features/rooms/ui/room_widgets.dart';
import 'package:niscala_api/api.dart';

const _emptyMessage =
    'Belum ada properti. Hunian kamar akan tampil di sini setelah ada '
    'properti yang bisa Anda kelola.';
const _noRooms = 'Belum ada kamar di properti ini.';
const _summaryHeading = 'Ringkasan semua properti';

/// The occupancy of each property, with a summary across them when there are
/// several. Every figure is read from the API as returned.
class OccupancyDashboardScreen extends ConsumerWidget {
  const OccupancyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(occupancyDashboardProvider);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Beranda'),
          Expanded(
            child: dashboard.when(
              // Retrying after an error shows the spinner, not the old error.
              skipLoadingOnRefresh: false,
              loading: () => const Center(
                child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
              ),
              error: (error, _) => ErrorView(
                message: errorMessageFor(error),
                onRetry: () => ref.invalidate(occupancyDashboardProvider),
              ),
              data: (dashboard) => _DashboardBody(dashboard: dashboard),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard});

  final OccupancyDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final items = dashboard.items;
    if (items.isEmpty) return const EmptyState(message: _emptyMessage);
    final summary = dashboard.summary;
    return ListView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      children: [
        if (summary.propertyCount > 1) ...[
          SectionCard(
            title: _summaryHeading,
            child: _Figures(
              occupied: summary.occupiedRoomCount,
              vacant: summary.vacantRoomCount,
              roomCount: summary.roomCount,
              percentage: summary.occupancyPercentage,
              propertyCount: summary.propertyCount,
            ),
          ),
          const SizedBox(height: NiscalaSpacing.l),
        ],
        for (final property in items) ...[
          _PropertyCard(property: property),
          const SizedBox(height: NiscalaSpacing.l),
        ],
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final PropertyOccupancy property;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: property.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Figures(
            occupied: property.occupiedRoomCount,
            vacant: property.vacantRoomCount,
            roomCount: property.roomCount,
            percentage: property.occupancyPercentage,
          ),
          const SizedBox(height: NiscalaSpacing.m),
          if (property.rooms.isEmpty)
            Text(_noRooms, style: Theme.of(context).textTheme.bodyLarge)
          else
            Wrap(
              spacing: NiscalaSpacing.s,
              runSpacing: NiscalaSpacing.s,
              children: [
                for (final room in property.rooms) _RoomChip(room: room),
              ],
            ),
        ],
      ),
    );
  }
}

/// The counts and the occupancy percentage of a property, or of all of them
/// when [propertyCount] is given.
class _Figures extends StatelessWidget {
  const _Figures({
    required this.occupied,
    required this.vacant,
    required this.roomCount,
    required this.percentage,
    this.propertyCount,
  });

  final int occupied;
  final int vacant;
  final int roomCount;
  final int percentage;
  final int? propertyCount;

  @override
  Widget build(BuildContext context) {
    final propertyCount = this.propertyCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (propertyCount != null) Text('$propertyCount properti'),
        Text('$occupied Terisi · $vacant Kosong'),
        Text('$roomCount kamar'),
        Text(
          '$percentage% terisi',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

/// One room with its number and occupancy. It shows the state in words, so it
/// does not rely on colour alone, and it is not tappable.
class _RoomChip extends StatelessWidget {
  const _RoomChip({required this.room});

  final OccupancyRoom room;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: NiscalaColors.divider),
          borderRadius: BorderRadius.circular(NiscalaRadius.small),
        ),
        child: Padding(
          padding: const EdgeInsets.all(NiscalaSpacing.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kamar ${room.number}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: NiscalaSpacing.xs),
              OccupancyBadge(occupancy: room.occupancy),
            ],
          ),
        ),
      ),
    );
  }
}
