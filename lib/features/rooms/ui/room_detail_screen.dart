import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/navigation.dart';
import 'package:niscala/core/widgets/confirm_dialog.dart';
import 'package:niscala/core/widgets/danger_button.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/core/tokens.dart';
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
      await _showDeleteFailure(errorMessageFor(failure));
      return;
    }
    if (!mounted) return;
    ref.invalidate(roomListProvider(widget.propertyId));
    final messenger = ScaffoldMessenger.of(context);
    leavePage(context, '/properti/${widget.propertyId}/kamar');
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
      appBar: DetailAppBar(
        title: loaded == null ? 'Kamar' : 'Kamar ${loaded.number}',
        subtitle: property?.name,
        actions: [
          if (loaded != null && loaded.editable)
            DetailBarAction.text(
              label: 'Ubah',
              onPressed: _deleting
                  ? null
                  : () => context.go(
                      '/properti/${widget.propertyId}/kamar/${widget.roomId}/ubah',
                    ),
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
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!r.editable) ...[
            StatusBadge(
              label: 'Hanya bisa dilihat',
              colors: NiscalaTokens.of(context).readOnly,
              icon: Icons.visibility_outlined,
            ),
            const SizedBox(height: NiscalaSpacing.s),
            const Text(_readOnly),
            formGap,
          ],
          if (lease == null)
            SectionCard(
              title: 'Tarif dasar kamar',
              trailing: OccupancyBadge(occupancy: r.occupancy),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Rent(r.baseRate),
                  const Text('Nilai awal saat mendaftarkan penyewa'),
                ],
              ),
            )
          else
            SectionCard(
              title: 'Tarif sewa · masa sewa ini',
              trailing: OccupancyBadge(occupancy: r.occupancy),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Rent(lease.rent),
                  Text(
                    'Tarif dasar kamar: ${formatRupiah(r.baseRate)} / bulan',
                  ),
                ],
              ),
            ),
          formGap,
          SectionCard(
            title: 'Ukuran',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (length != null && width != null) ...[
                  Text(formatDimensions(length, width)),
                  Text('${formatMeasure(length * width)} m²'),
                ] else
                  const Text('Belum diisi'),
              ],
            ),
          ),
          formGap,
          SectionCard(
            title: 'Fasilitas',
            child: r.facilities.isEmpty
                ? const Text('Belum ada fasilitas')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in r.facilities) _FacilityPill(tag),
                    ],
                  ),
          ),
          formGap,
          if (lease == null)
            SectionCard(
              title: 'Kamar kosong',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Belum ada penyewa di kamar ini.'),
                  if (r.editable) ...[
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => context.go(
                        '/properti/${widget.propertyId}/penyewa/tambah?kamar=${r.id}',
                      ),
                      child: const Text('Tambah Penyewa'),
                    ),
                  ],
                ],
              ),
            )
          else
            SectionCard(
              title: 'Penyewa & masa sewa',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lease.tenantName, style: theme.textTheme.titleMedium),
                  Text(lease.tenantPhone),
                  const SizedBox(height: NiscalaSpacing.s),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LeaseDate(
                          'Mulai',
                          _dateOrDash(lease.startDate),
                        ),
                      ),
                      const SizedBox(width: NiscalaSpacing.s),
                      Expanded(
                        child: _LeaseDate(
                          'Berakhir',
                          _dateOrDash(lease.endDate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NiscalaSpacing.s),
                  const Divider(height: 1),
                  TextButton(
                    onPressed: () => context.go(
                      '/properti/${widget.propertyId}/penyewa/${lease.tenantId}',
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text('Lihat rincian penyewa')),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          formGap,
          DangerButton(
            label: 'Hapus Kamar',
            onPressed: _deleting ? null : () => _askToDelete(r),
          ),
        ],
      ),
    );
  }
}

/// A monthly rent: the amount large, the unit small and muted.
class _Rent extends StatelessWidget {
  const _Rent(this.amount);

  final int amount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        text: formatRupiah(amount),
        style: textTheme.headlineSmall,
        children: [
          TextSpan(
            text: ' / bulan',
            style: textTheme.bodyMedium?.copyWith(
              color: NiscalaColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A label with a date under it.
class _LeaseDate extends StatelessWidget {
  const _LeaseDate(this.label, this.date);

  final String label;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Text(date),
      ],
    );
  }
}

/// One facility on a soft primary pill.
class _FacilityPill extends StatelessWidget {
  const _FacilityPill(this.tag);

  final String tag;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NiscalaColors.primarySoft,
        borderRadius: BorderRadius.circular(NiscalaRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          tag,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: NiscalaColors.primary),
        ),
      ),
    );
  }
}

String _dateOrDash(DateTime? date) => date == null ? '-' : formatDate(date);
