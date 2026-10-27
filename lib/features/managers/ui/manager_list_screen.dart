import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/managers/data/manager_repository.dart';
import 'package:niscala/features/managers/ui/manager_widgets.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala_api/api.dart';

const _empty =
    'Belum ada pengelola. Tambahkan pengelola, lalu bagikan tautan undangan '
    'agar ia bisa mengaktifkan akun.';
const _addLabel = 'Tambah Pengelola';

/// The managers assigned to one property.
class ManagerListScreen extends ConsumerWidget {
  const ManagerListScreen({super.key, required this.propertyId});

  final String propertyId;

  void _openAdd(BuildContext context) =>
      context.go('/properti/$propertyId/pengelola/tambah');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(propertyDetailProvider(propertyId)).value?.name;
    final managers = ref.watch(managerListProvider(propertyId));
    return managers.when(
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
          onRetry: () => ref.invalidate(managerListProvider(propertyId)),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _page(
            name,
            EmptyState(
              message: _empty,
              actionLabel: _addLabel,
              onAction: () => _openAdd(context),
            ),
          );
        }
        return _page(
          name,
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: () => _openAdd(context),
                icon: const Icon(Icons.add),
                label: const Text(_addLabel),
              ),
              formGap,
              for (final manager in items) ...[
                _ManagerRow(propertyId: propertyId, manager: manager),
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
  appBar: DetailAppBar(title: 'Pengelola', subtitle: propertyName),
  body: body,
);

/// One manager as a card. Its nickname is the main text when set, otherwise
/// the name; the row reads as one item for assistive technology.
class _ManagerRow extends StatelessWidget {
  const _ManagerRow({required this.propertyId, required this.manager});

  final String propertyId;
  final ManagerSummary manager;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nickname = manager.nickname;
    final email = manager.email;
    return Card(
      child: MergeSemantics(
        child: ListTile(
          onTap: () =>
              context.go('/properti/$propertyId/pengelola/${manager.id}'),
          title: Text(
            nickname ?? manager.name,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (nickname != null) Text(manager.name),
              Text(manager.phone),
              if (email != null) Text(email),
              Text(manager.properties.map((p) => p.name).join(', ')),
              const SizedBox(height: 4),
              ManagerStatusBadge(status: manager.accountStatus),
            ],
          ),
        ),
      ),
    );
  }
}
