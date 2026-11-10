import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/google/google_identity.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/shell/account_screen.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/google_button.dart';
import 'package:niscala/features/account/data/account_repository.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';
import 'package:niscala_api/api.dart';

const _title = 'Hubungkan Google';
const _introHeading = 'Masuk lebih cepat dengan Google';
const _pickLabel = 'Pilih akun Google';
const _doneHeading = 'Google terhubung';
const _backToAccount = 'Kembali ke Akun';
const _cancelled = 'Penghubungan dibatalkan. Akun tidak berubah.';
const _alreadyRegistered =
    'Akun Google ini sudah terhubung ke akun Niscala lain. '
    'Pilih akun Google yang berbeda.';

/// Links a Google account to the account, which must have a password. The
/// user picks the Google account; the link is made with its ID token. The
/// result stays on the screen with the linked email.
class LinkGoogleScreen extends ConsumerStatefulWidget {
  const LinkGoogleScreen({super.key});

  @override
  ConsumerState<LinkGoogleScreen> createState() => _LinkGoogleScreenState();
}

class _LinkGoogleScreenState extends ConsumerState<LinkGoogleScreen> {
  var _busy = false;
  String? _notice;
  String? _banner;

  /// The account after the link. Null until the link succeeds.
  Account? _linked;

  /// Asks for the Google account and links it. Cancelling leaves the account
  /// as it was and says so.
  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
      _banner = null;
    });
    try {
      final idToken = await ref.read(googleIdentityProvider).idToken();
      if (!mounted) return;
      if (idToken == null) {
        setState(() {
          _busy = false;
          _notice = _cancelled;
        });
        return;
      }
      final account = await ref
          .read(accountRepositoryProvider)
          .linkGoogle(idToken);
      if (!mounted) return;
      ref.invalidate(meProvider);
      setState(() {
        _busy = false;
        _linked = account;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _banner = _linkMessage(error);
      });
    }
  }

  void _leave() => context.go(accountTabPath(ref.read(currentRoleProvider)));

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(meProvider).value?.email;
    final linked = _linked;
    final notice = _notice;
    final banner = _banner;
    return AuthPage(
      appBar: const DetailAppBar(title: _title),
      children: [
        if (notice != null) ...[FormMessage(notice, isError: false), formGap],
        if (banner != null) ...[FormMessage(banner), formGap],
        if (linked == null)
          ..._introChildren(context, email)
        else
          ..._doneChildren(linked),
      ],
    );
  }

  List<Widget> _introChildren(BuildContext context, String? email) {
    final theme = Theme.of(context);
    return [
      Semantics(
        header: true,
        child: Text(_introHeading, style: theme.textTheme.titleMedium),
      ),
      formGap,
      _Bullet(
        email == null
            ? 'Email akun Niscala Anda tidak berubah, meskipun akun Google '
                  'memakai email lain.'
            : 'Email akun Niscala Anda tetap $email, meskipun akun Google '
                  'memakai email lain.',
      ),
      const SizedBox(height: 8),
      const _Bullet(
        'Satu akun Google hanya bisa terhubung ke satu akun Niscala.',
      ),
      const SizedBox(height: 8),
      const _Bullet('Niscala hanya membaca nama dan email dari akun Google.'),
      formGap,
      GoogleButton(label: _pickLabel, onPressed: _busy ? null : _pick),
    ];
  }

  List<Widget> _doneChildren(Account linked) {
    final email = linked.googleEmail;
    return [
      const FormMessage(_doneHeading, isError: false),
      if (email != null) ...[formGap, Text('Akun Google: $email')],
      formGap,
      FilledButton(onPressed: _leave, child: const Text(_backToAccount)),
    ];
  }
}

/// The message for a failed link. An already registered Google account gets
/// its own text here, because the sign-up text tells the user to sign in.
String _linkMessage(Object error) =>
    error is ApiFailure && error.code == 'GOOGLE_ACCOUNT_ALREADY_REGISTERED'
    ? _alreadyRegistered
    : errorMessageFor(error);

/// One point of the intro. The bullet is not read aloud, so only the text is.
class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(child: Text('•')),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
