import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/widgets/confirm_dialog.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala_api/api.dart';

const _readOnlyOwner =
    'Properti ini tidak termasuk paket Anda saat ini. Data tidak bisa diubah, '
    'tetapi tagihan, pembayaran, dan keluhan tetap diproses. Menghapus '
    'properti tetap bisa.';
const _readOnlyManager =
    'Paket pemilik kost tidak mencakup properti ini. Anda hanya bisa melihat '
    'data sampai pemilik meningkatkan paket.';
const _managerOnly =
    'Hanya Pemilik Kost yang dapat mengubah atau menghapus properti.';
const _noBank = 'Belum ada rekening. Penyewa hanya bisa membayar tunai.';
const _deleteMessage =
    'Semua kamar dan penugasan Pengelola Kost di properti ini ikut terhapus. '
    'Tindakan ini tidak dapat dibatalkan.';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    this.showBack = true,
  });

  final String propertyId;
  final bool showBack;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  var _deleting = false;

  Future<void> _askToDelete(Property property) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus ${property.name}?',
      message: _deleteMessage,
      confirmLabel: 'Hapus',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(propertyRepositoryProvider).delete(property.id);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _deleting = false);
      await _showDeleteFailure(errorMessage(failure.code));
      return;
    }
    if (!mounted) return;
    ref.invalidate(propertyListProvider);
    final messenger = ScaffoldMessenger.of(context);
    context.go('/properti');
    messenger.showSnackBar(const SnackBar(content: Text('Properti dihapus')));
  }

  Future<void> _showDeleteFailure(String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Properti belum bisa dihapus'),
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
    final isOwner = ref.watch(currentRoleProvider) == UserRole.owner;
    final property = ref.watch(propertyDetailProvider(widget.propertyId));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBack,
        title: const Text('Rincian Properti'),
      ),
      body: property.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () =>
              ref.invalidate(propertyDetailProvider(widget.propertyId)),
        ),
        data: (p) => _details(context, p, isOwner),
      ),
    );
  }

  Widget _details(BuildContext context, Property p, bool isOwner) {
    final theme = Theme.of(context);
    final bank = p.bankAccount;
    final managers = p.managers.map((m) => m.name).join(', ');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NiscalaSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(p.name, style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: 4),
          Text(p.address, style: theme.textTheme.bodyLarge),
          if (!p.editable) ...[
            formGap,
            StatusBadge(
              label: 'Hanya bisa dilihat',
              colors: NiscalaTokens.of(context).readOnly,
              icon: Icons.visibility_outlined,
            ),
            const SizedBox(height: 8),
            Text(isOwner ? _readOnlyOwner : _readOnlyManager),
          ],
          formGap,
          if (isOwner) ...[
            if (p.editable)
              FilledButton(
                onPressed: _deleting
                    ? null
                    : () => context.go('/properti/${p.id}/ubah'),
                child: const Text('Ubah'),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: _deleting ? null : () => _askToDelete(p),
              child: const Text('Hapus Properti'),
            ),
          ] else
            Text(_managerOnly),
          formGap,
          Text('Jumlah kamar', style: theme.textTheme.titleSmall),
          Text('${p.roomCount} kamar'),
          Text('${p.occupiedRoomCount} terisi · ${p.vacantRoomCount} kosong'),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _deleting
                ? null
                : () => context.go('/properti/${p.id}/kamar'),
            child: const Text('Kelola Kamar'),
          ),
          const SizedBox(height: 4),
          const Text('Tambah, ubah, atau hapus kamar'),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _deleting
                ? null
                : () => context.go('/properti/${p.id}/penyewa'),
            child: const Text('Kelola Penyewa'),
          ),
          const SizedBox(height: 4),
          const Text('Daftarkan penyewa, atur masa sewa dan tagihan'),
          formGap,
          SectionCard(
            title: 'Pengelola Kost',
            child: p.managers.isEmpty
                ? const Text('Belum ada pengelola')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${p.managers.length} pengelola'),
                      Text(managers),
                    ],
                  ),
          ),
          formGap,
          SectionCard(
            title: 'Rekening transfer sewa',
            child: bank == null
                ? const Text(_noBank)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${bank.bankName} · ${bank.accountNumber}'),
                      Text('a.n. ${bank.accountHolderName}'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
