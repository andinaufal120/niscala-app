import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/filter_chip_row.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/core/widgets/screen_header.dart';
import 'package:niscala/features/user_accounts/data/user_account_repository.dart';
import 'package:niscala/features/user_accounts/status_labels.dart';
import 'package:niscala_api/api.dart';

const _searchLabel = 'Cari email';
const _deletedLabel = 'Tampilkan akun yang dihapus';
const _emptyMessage = 'Tidak ada akun yang cocok';

/// How long the typing must pause before the search is sent.
const _searchDelay = Duration(milliseconds: 400);

/// A null role shows every role.
const _roleFilters = <(String, UserRole?)>[
  ('Semua', null),
  ('Pemilik', UserRole.owner),
  ('Penyewa', UserRole.tenant),
  ('Pengelola', UserRole.manager),
];

/// Every user account, for an Admin. The search, the role and the deleted
/// accounts narrow the list, and each change asks the API again.
class UserAccountListScreen extends ConsumerStatefulWidget {
  const UserAccountListScreen({super.key});

  @override
  ConsumerState<UserAccountListScreen> createState() =>
      _UserAccountListScreenState();
}

class _UserAccountListScreenState extends ConsumerState<UserAccountListScreen> {
  final _searchController = TextEditingController();
  Timer? _searchTimer;

  /// The email sent with the request. Null when the search is blank.
  String? _email;
  UserRole? _role;
  var _includeDeleted = false;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDelay, () {
      final email = text.trim();
      setState(() => _email = email.isEmpty ? null : email);
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = (email: _email, role: _role, includeDeleted: _includeDeleted);
    final accounts = ref.watch(userAccountListProvider(query));
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Akun Pengguna',
            action: TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size.square(48)),
              onPressed: () => ref.read(logoutProvider)(),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
          ),
          // The filters scroll with the results, so a large text size never
          // pushes the results off the screen.
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      NiscalaSpacing.gutter,
                      NiscalaSpacing.l,
                      NiscalaSpacing.gutter,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LabeledField(
                          label: _searchLabel,
                          child: TextField(
                            controller: _searchController,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        const SizedBox(height: NiscalaSpacing.l),
                        FilterChipRow(
                          chips: [
                            for (final (label, role) in _roleFilters)
                              ChoiceChip(
                                label: Text(label),
                                selected: _role == role,
                                onSelected: (_) => setState(() => _role = role),
                              ),
                          ],
                        ),
                        CheckboxListTile(
                          value: _includeDeleted,
                          onChanged: (checked) => setState(
                            () => _includeDeleted = checked ?? false,
                          ),
                          title: const Text(_deletedLabel),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                accounts.when(
                  skipLoadingOnReload: true,
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Memuat',
                      ),
                    ),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(
                      message: errorMessageFor(error),
                      onRetry: () =>
                          ref.invalidate(userAccountListProvider(query)),
                    ),
                  ),
                  data: (items) => items.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(message: _emptyMessage),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            NiscalaSpacing.gutter,
                            NiscalaSpacing.l,
                            NiscalaSpacing.gutter,
                            NiscalaSpacing.gutter,
                          ),
                          sliver: SliverList.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: NiscalaSpacing.s,
                              ),
                              child: _AccountRow(account: items[index]),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One account as a card. It reads as one item for assistive technology.
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});

  final UserAccountSummary account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: MergeSemantics(
        child: ListTile(
          onTap: () => context.go('/admin/${account.id}'),
          title: Text(account.name, style: theme.textTheme.titleMedium),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account.email),
              const SizedBox(height: NiscalaSpacing.xs),
              Wrap(
                spacing: NiscalaSpacing.s,
                runSpacing: NiscalaSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    userRoleLabels[account.role]!,
                    style: theme.textTheme.labelLarge,
                  ),
                  UserAccountStatusBadge(account.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
