import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/widgets/confirm_dialog.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/rooms/data/room_repository.dart';
import 'package:niscala/features/rooms/ui/room_widgets.dart';
import 'package:niscala_api/api.dart';

const _readOnly =
    'Kamar ini tidak termasuk paket pemilik kost saat ini. Data kamar, masa '
    'sewa, dan penyewanya tidak bisa diubah. Tagihan tetap terbit, dan '
    'pembayaran serta keluhan penyewa tetap bisa diproses. Menghapus kamar '
    'tetap bisa.';
const _deleteMessage =
    'Kamar akan dihapus. Tindakan ini tidak dapat dibatalkan.';

/// One room with its rent, size, facilities and lease. The edit action shows
/// only when the room is editable.
class RoomDetailScreen extends ConsumerStatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.propertyId,
    required this.roomId,
  });

  final String propertyId;
  final String roomId;

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  var _deleting = false;

  Future<void> _askToDelete(Room room) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus Kamar ${room.number}?',
      message: _deleteMessage,
      confirmLabel: 'Hapus',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(roomRepositoryProvider).delete(room.id);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _deleting = false);
      await _showDeleteFailure(errorMessage(failure.code));
      return;
    }
    if (!mounted) return;
    ref.invalidate(roomListProvider(widget.propertyId));
    final messenger = ScaffoldMessenger.of(context);
    context.go('/properti/${widget.propertyId}/kamar');
    messenger.showSnackBar(const SnackBar(content: Text('Kamar dihapus')));
  }

  Future<void> _showDeleteFailure(String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Kamar belum bisa dihapus'),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Mengerti'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final property = ref.watch(propertyDetailProvider(widget.propertyId)).value;
    final room = ref.watch(roomDetailProvider(widget.roomId));
    final loaded = room.value;
    return Scaffold(
      appBar: AppBar(
        title: RoomTitle(
          title: loaded == null ? 'Kamar' : 'Kamar ${loaded.number}',
          propertyName: property?.name,
        ),
        actions: [
          if (loaded != null && loaded.editable)
            TextButton(
              onPressed: _deleting
                  ? null
                  : () => context.go(
                      '/properti/${widget.propertyId}/kamar/${widget.roomId}/ubah',
                    ),
              child: const Text('Ubah'),
            ),
        ],
      ),
      body: room.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(roomDetailProvider(widget.roomId)),
        ),
        data: (r) => _details(context, r),
      ),
    );
  }

  Widget _details(BuildContext context, Room r) {
    final theme = Theme.of(context);
    final lease = r.lease;
    final length = r.lengthM;
    final width = r.widthM;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OccupancyBadge(occupancy: r.occupancy),
              if (!r.editable)
                const StatusBadge(
                  label: 'Hanya bisa dilihat',
                  tone: StatusTone.warning,
                  icon: Icons.visibility_outlined,
                ),
            ],
          ),
          if (!r.editable) ...[const SizedBox(height: 8), Text(_readOnly)],
          formGap,
          if (lease == null)
            _RoomSection(
              title: 'Tarif dasar kamar',
              children: [
                Text('${formatRupiah(r.baseRate)} / bulan'),
                const Text('Nilai awal saat mendaftarkan penyewa'),
              ],
            )
          else
            _RoomSection(
              title: 'Tarif sewa · masa sewa ini',
              children: [
                Text('${formatRupiah(lease.rent)} / bulan'),
                Text('Tarif dasar kamar: ${formatRupiah(r.baseRate)} / bulan'),
              ],
            ),
          formGap,
          _RoomSection(
            title: 'Ukuran',
            children: [
              if (length != null && width != null) ...[
                Text(formatDimensions(length, width)),
                Text('${formatMeasure(length * width)} m²'),
              ] else
                const Text('Belum diisi'),
            ],
          ),
          formGap,
          _RoomSection(
            title: 'Fasilitas',
            children: [
              if (r.facilities.isEmpty)
                const Text('Belum ada fasilitas')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in r.facilities) Chip(label: Text(tag)),
                  ],
                ),
            ],
          ),
          formGap,
          if (lease == null)
            _RoomSection(
              title: 'Kamar kosong',
              children: const [Text('Belum ada penyewa di kamar ini.')],
            )
          else
            _RoomSection(
              title: 'Penyewa & masa sewa',
              children: [
                Text(lease.tenantName, style: theme.textTheme.titleMedium),
                Text(lease.tenantPhone),
                const SizedBox(height: 8),
                Text('Mulai', style: theme.textTheme.labelLarge),
                Text(_dateOrDash(lease.startDate)),
                const SizedBox(height: 8),
                Text('Berakhir', style: theme.textTheme.labelLarge),
                Text(_dateOrDash(lease.endDate)),
              ],
            ),
          formGap,
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: _deleting ? null : () => _askToDelete(r),
            child: const Text('Hapus Kamar'),
          ),
        ],
      ),
    );
  }
}

String _dateOrDash(DateTime? date) => date == null ? '-' : formatDate(date);

/// A titled block of the detail screen. The title is a header for assistive
/// technology.
class _RoomSection extends StatelessWidget {
  const _RoomSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    );
  }
}
