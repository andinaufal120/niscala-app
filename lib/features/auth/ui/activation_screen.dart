import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/google/google_identity.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/google_button.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/auth/data/invitation_repository.dart';
import 'package:niscala/features/auth/invitation_link.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';
import 'package:niscala/features/auth/ui/invitation_link_field.dart';
import 'package:niscala/features/tenants/ui/emergency_contact_fields.dart';
import 'package:niscala_api/api.dart';

/// Activates an account from a pasted invitation link. A valid link turns the
/// same screen into the activation form.
class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _link = TextEditingController();
  var _busy = false;
  String? _linkError;
  String? _banner;
  ({String token, InvitationPreview preview})? _invitation;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _checkLink() async {
    if (_busy) return;
    final token = invitationTokenFromLink(_link.text);
    if (token == null) {
      setState(() => _linkError = invitationLinkRequiredMessage);
      return;
    }
    setState(() {
      _linkError = null;
      _banner = null;
      _busy = true;
    });
    try {
      final preview = await ref
          .read(invitationRepositoryProvider)
          .preview(token);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (preview.status == InvitationLinkStatus.valid) {
          _invitation = (token: token, preview: preview);
        } else {
          _banner = _statusMessage(preview.status);
        }
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _banner = errorMessageFor(failure);
      });
    }
  }

  String _statusMessage(InvitationLinkStatus status) {
    if (status == InvitationLinkStatus.expired) return invitationExpiredMessage;
    if (status == InvitationLinkStatus.used) return invitationUsedMessage;
    return errorMessageFor(status);
  }

  @override
  Widget build(BuildContext context) {
    final invitation = _invitation;
    if (invitation != null) {
      return _ActivationForm(
        token: invitation.token,
        preview: invitation.preview,
      );
    }
    return AuthPage(
      appBar: _activationAppBar(context),
      children: [
        if (_banner != null) ...[FormMessage(_banner!), formGap],
        InvitationLinkField(controller: _link, error: _linkError),
        formGap,
        BusyButton(label: 'Lanjut', busy: _busy, onPressed: _checkLink),
      ],
    );
  }
}

DetailAppBar _activationAppBar(BuildContext context) {
  return DetailAppBar(
    title: 'Aktivasi Akun',
    leading: IconButton(
      tooltip: 'Kembali',
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.go('/masuk'),
    ),
  );
}

/// The account form of a valid invitation. Name and contacts come from the
/// invitation where management filled them in; the rest is entered here.
class _ActivationForm extends ConsumerStatefulWidget {
  const _ActivationForm({required this.token, required this.preview});

  final String token;
  final InvitationPreview preview;

  @override
  ConsumerState<_ActivationForm> createState() => _ActivationFormState();
}

class _ActivationFormState extends ConsumerState<_ActivationForm> {
  late final _name = TextEditingController(text: widget.preview.name);
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _contacts = <EmergencyContactDraft>[];
  var _showPassword = false;
  var _busy = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _contactsError;
  String? _banner;

  @override
  void initState() {
    super.initState();
    if (widget.preview.emergencyContactsRequired) {
      _contacts.addAll([
        for (var i = 0; i < minEmergencyContacts; i++) EmergencyContactDraft(),
      ]);
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _confirm]) {
      controller.dispose();
    }
    for (final draft in _contacts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addContact() => setState(() => _contacts.add(EmergencyContactDraft()));

  void _removeContact(EmergencyContactDraft draft) {
    setState(() => _contacts.remove(draft));
    // The removed block still holds its controllers until this frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) => draft.dispose());
  }

  Future<void> _submit() async {
    if (_busy) return;
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final nameError = name.isEmpty ? 'Nama wajib diisi.' : null;
    final emailError = signUpEmailError(email);
    final passwordError = newPasswordError(password);
    final confirmError = confirmPasswordError(password, _confirm.text);
    final contactsError = _contactCountError();
    final contactsValid = _contactsValid();
    final valid =
        nameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmError == null &&
        contactsError == null &&
        contactsValid;
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
      _contactsError = contactsError;
      _banner = null;
      _busy = valid;
    });
    if (!valid) return;

    try {
      final session = await ref
          .read(invitationRepositoryProvider)
          .activateWithPassword(
            token: widget.token,
            name: name,
            email: email,
            password: password,
            emergencyContacts: _emergencyContactsOrNull(),
          );
      await ref.read(sessionControllerProvider.notifier).signIn(session);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      _showFailure(failure);
    }
  }

  /// The error of too few emergency contacts, or null when the invitation needs
  /// none or enough are given.
  String? _contactCountError() =>
      widget.preview.emergencyContactsRequired &&
          _contacts.length < minEmergencyContacts
      ? emergencyContactsMinimum
      : null;

  /// Whether every contact block is filled in. Each block shows its own errors.
  bool _contactsValid() =>
      [for (final draft in _contacts) draft.validate()].every((valid) => valid);

  /// The contacts to send, trimmed, or null when the invitation needs none.
  List<EmergencyContact>? _emergencyContactsOrNull() =>
      widget.preview.emergencyContactsRequired
      ? [
          for (final draft in _contacts)
            EmergencyContact(
              name: draft.name.text.trim(),
              relationship: draft.relationship.text.trim(),
              phone: draft.phone.text.trim(),
            ),
        ]
      : null;

  /// Activates with the Google account. The name and the contacts are checked
  /// first, so the chooser opens only for a complete form.
  Future<void> _activateWithGoogle() async {
    if (_busy) return;
    final name = _name.text.trim();
    final nameError = name.isEmpty ? 'Nama wajib diisi.' : null;
    final contactsError = _contactCountError();
    final contactsValid = _contactsValid();
    final valid = nameError == null && contactsError == null && contactsValid;
    setState(() {
      _nameError = nameError;
      _contactsError = contactsError;
      _banner = null;
      _busy = valid;
    });
    if (!valid) return;

    try {
      final idToken = await ref.read(googleIdentityProvider).idToken();
      if (idToken == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final session = await ref
          .read(invitationRepositoryProvider)
          .activateWithGoogle(
            token: widget.token,
            name: name,
            idToken: idToken,
            emergencyContacts: _emergencyContactsOrNull(),
          );
      await ref.read(sessionControllerProvider.notifier).signIn(session);
    } on Object catch (error) {
      if (!mounted) return;
      _showGoogleFailure(error);
    }
  }

  /// A name the API rejects is shown on the name field; any other failure is
  /// shown in the banner.
  void _showGoogleFailure(Object error) {
    final isNameError =
        error is ApiFailure &&
        error.code == 'VALIDATION_FAILED' &&
        error.field == 'name';
    setState(() {
      _busy = false;
      if (isNameError) {
        _nameError = errorMessageFor(error, labels: personFormLabels);
      } else {
        _banner = errorMessageFor(error);
      }
    });
  }

  /// Shows a failure next to the field it belongs to, or as a banner.
  void _showFailure(ApiFailure failure) {
    final message = errorMessageFor(failure, labels: personFormLabels);
    final field = switch (failure.code) {
      'EMAIL_ALREADY_REGISTERED' => 'email',
      'PASSWORD_TOO_COMMON' => 'password',
      _ => failure.field,
    };
    setState(() {
      _busy = false;
      switch (field) {
        case 'name':
          _nameError = message;
        case 'email':
          _emailError = message;
        case 'password':
          _passwordError = message;
        default:
          _banner = message;
      }
    });
  }

  /// The place of the invitation, e.g. "Kos Melati · Kamar 08". A manager gets
  /// the names of all their properties.
  String _placeLine(InvitationPreview preview) {
    final names = preview.properties
        .map((property) => property.name)
        .join(', ');
    final room = preview.roomNumber;
    return room == null ? names : '$names · Kamar $room';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = widget.preview;
    return AuthPage(
      appBar: _activationAppBar(context),
      footer: ActionFooter(
        primary: BusyButton(
          label: 'Aktifkan Akun',
          busy: _busy,
          onPressed: _submit,
        ),
      ),
      children: [
        if (_banner != null) ...[FormMessage(_banner!), formGap],
        Semantics(
          header: true,
          child: Text(
            'Undangan dari ${preview.inviterName}',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 4),
        Text(_placeLine(preview), style: theme.textTheme.bodyMedium),
        formGap,
        GoogleButton(
          label: 'Aktifkan dengan Google',
          onPressed: _busy ? null : _activateWithGoogle,
        ),
        formGap,
        const EmailDivider(),
        formGap,
        LabeledField(
          label: 'Nama lengkap',
          required: true,
          child: TextField(
            controller: _name,
            decoration: InputDecoration(errorText: _nameError),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            onChanged: (_) => setState(() {}),
          ),
        ),
        formGap,
        LabeledField(
          label: 'Email',
          required: true,
          helper: 'Email dipakai untuk masuk dan mengatur ulang kata sandi.',
          child: TextField(
            controller: _email,
            decoration: InputDecoration(errorText: _emailError),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => setState(() {}),
          ),
        ),
        formGap,
        LabeledField(
          label: 'Kata sandi',
          required: true,
          helper:
              'Minimal 8 karakter. Boleh berupa kalimat panjang, tanpa '
              'aturan huruf atau simbol khusus.',
          child: TextField(
            controller: _password,
            decoration: InputDecoration(errorText: _passwordError),
            obscureText: !_showPassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) => setState(() {}),
          ),
        ),
        PasswordStrengthHint(
          password: _password.text,
          name: _name.text,
          email: _email.text,
        ),
        formGap,
        LabeledField(
          label: 'Konfirmasi kata sandi',
          required: true,
          child: TextField(
            controller: _confirm,
            decoration: InputDecoration(errorText: _confirmError),
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.newPassword],
          ),
        ),
        ShowPasswordCheckbox(
          value: _showPassword,
          onChanged: (value) => setState(() => _showPassword = value),
        ),
        if (preview.emergencyContactsRequired) ...[
          formGap,
          EmergencyContactsSection(
            drafts: _contacts,
            error: _contactsError,
            onAdd: _addContact,
            onRemove: _removeContact,
          ),
        ],
      ],
    );
  }
}
