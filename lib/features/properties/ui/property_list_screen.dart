import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/screen_header.dart';
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
            padding: const EdgeInsets.all(NiscalaSpacing.gutter),
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) formGap,
                _PropertyCard(property: items[i]),
              ],
            ],
          ),
          subtitle: isOwner
              ? 'Semua properti milik Anda'
              : 'Properti yang ditugaskan kepada Anda',
          action: isOwner
              ? FilledButton(
                  onPressed: () => context.go('/properti/tambah'),
                  child: const Text('Tambah'),
                )
              : null,
        );
      },
    );
  }
}

/// The tab page: the header on top, the state below it. The header has no
/// app bar, as a tab root does.
Scaffold _listPage(Widget body, {String? subtitle, Widget? action}) => Scaffold(
  body: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ScreenHeader(title: 'Properti', subtitle: subtitle, action: action),
      Expanded(child: body),
    ],
  ),
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
              const SizedBox(height: NiscalaSpacing.s),
              Wrap(
                spacing: NiscalaSpacing.s,
                runSpacing: NiscalaSpacing.s,
                children: [
                  _FactPill(
                    '${property.roomCount} kamar · '
                    '${property.occupiedRoomCount} terisi',
                  ),
                  _FactPill(
                    managers.isEmpty
                        ? 'Belum ada pengelola'
                        : 'Pengelola: $managers',
                  ),
                  if (!property.editable)
                    StatusBadge(
                      label: 'Hanya lihat',
                      colors: NiscalaTokens.of(context).readOnly,
                    ),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

/// A short fact about a property on a neutral pill.
class _FactPill extends StatelessWidget {
  const _FactPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NiscalaColors.neutralSoft,
        borderRadius: BorderRadius.circular(NiscalaRadius.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: NiscalaColors.textSecondary),
        ),
      ),
    );
  }
}
