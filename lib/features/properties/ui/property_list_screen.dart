import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/status_badge.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/properties/ui/property_detail_screen.dart';
import 'package:niscala_api/api.dart';

const _ownerEmpty =
    'Belum ada properti. Tambahkan kos pertama Anda untuk mulai mengelola '
    'kamar dan penyewa.';
const _managerEmpty =
    'Belum ada properti yang ditugaskan. Minta Pemilik Kost menugaskan Anda '
    'ke sebuah properti.';

/// The Properti tab. A manager with exactly one property sees its detail
/// directly, without a list.
class PropertyListScreen extends ConsumerWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(currentRoleProvider) == UserRole.owner;
    final properties = ref.watch(propertyListProvider);
    return properties.when(
      skipLoadingOnReload: true,
      loading: () => _listPage(
        const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
      ),
      error: (error, _) => _listPage(
        ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(propertyListProvider),
        ),
      ),
      data: (items) {
        if (!isOwner && items.length == 1) {
          return PropertyDetailScreen(
            propertyId: items.single.id,
            showBack: false,
          );
        }
        if (items.isEmpty) {
          return _listPage(
            EmptyState(
              message: isOwner ? _ownerEmpty : _managerEmpty,
              actionLabel: isOwner ? 'Tambah Properti Pertama' : null,
              onAction: isOwner ? () => context.go('/properti/tambah') : null,
            ),
          );
        }
        return _listPage(
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                isOwner
                    ? 'Semua properti milik Anda'
                    : 'Properti yang ditugaskan kepada Anda',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (isOwner) ...[
                formGap,
                FilledButton.icon(
                  onPressed: () => context.go('/properti/tambah'),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
              ],
              for (final property in items) ...[
                formGap,
                _PropertyCard(property: property),
              ],
            ],
          ),
        );
      },
    );
  }
}

Scaffold _listPage(Widget body) => Scaffold(
  appBar: AppBar(title: const Text('Properti')),
  body: body,
);

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property});

  final PropertySummary property;

  @override
  Widget build(BuildContext context) {
    final managers = property.managers.map((m) => m.name).join(', ');
    return Card(
      child: MergeSemantics(
        child: ListTile(
          onTap: () => context.go('/properti/${property.id}'),
          title: Text(
            property.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(property.address),
              Text(
                '${property.roomCount} kamar · '
                '${property.occupiedRoomCount} terisi',
              ),
              Text(
                managers.isEmpty
                    ? 'Belum ada pengelola'
                    : 'Pengelola: $managers',
              ),
              if (!property.editable) ...[
                const SizedBox(height: 4),
                StatusBadge(
                  label: 'Hanya lihat',
                  colors: NiscalaTokens.of(context).readOnly,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
