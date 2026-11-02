import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/auth/data/auth_repository.dart';
import 'package:niscala/features/auth/link_token.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';

const _invalidLink = 'Tautan tidak valid.';
const _linkHelper = 'Tempel tautan konfirmasi dari email Anda.';

/// Confirms a new login email from a pasted email-change link. Success does not
/// sign the user in.
class ConfirmEmailChangeScreen extends ConsumerStatefulWidget {
  const ConfirmEmailChangeScreen({super.key});

  @override
  ConsumerState<ConfirmEmailChangeScreen> createState() =>
      _ConfirmEmailChangeScreenState();
}

class _ConfirmEmailChangeScreenState
    extends ConsumerState<ConfirmEmailChangeScreen> {
  final _link = TextEditingController();
  var _busy = false;
  var _done = false;
  String? _linkError;
  String? _banner;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final token = tokenFromQueryLink(_link.text);
    if (token == null) {
      setState(() {
        _linkError = _invalidLink;
        _banner = null;
      });
      return;
    }
    setState(() {
      _linkError = null;
      _banner = null;
      _busy = true;
    });
    try {
      await ref.read(authRepositoryProvider).confirmEmailChange(token);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _banner = errorMessageFor(failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthPage(
      appBar: DetailAppBar(
        title: 'Konfirmasi email baru',
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/masuk'),
        ),
      ),
      children: _done ? _result(theme) : _linkStep(),
    );
  }

  List<Widget> _linkStep() => [
    if (_banner != null) ...[FormMessage(_banner!), formGap],
    LabeledField(
      label: 'Tautan konfirmasi',
      required: true,
      helper: _linkHelper,
      child: TextField(
        controller: _link,
        decoration: InputDecoration(errorText: _linkError),
        keyboardType: TextInputType.url,
        autocorrect: false,
      ),
    ),
    formGap,
    BusyButton(label: 'Konfirmasi', busy: _busy, onPressed: _submit),
  ];

  List<Widget> _result(ThemeData theme) => [
    Semantics(
      header: true,
      child: Text('Email diperbarui', style: theme.textTheme.titleLarge),
    ),
    const SizedBox(height: 8),
    Text(
      'Email login akun Anda sudah diperbarui. Masuk dengan email baru Anda.',
      style: theme.textTheme.bodyLarge,
    ),
    formGap,
    FilledButton(
      onPressed: () => context.go('/masuk'),
      child: const Text('Masuk'),
    ),
  ];
}
