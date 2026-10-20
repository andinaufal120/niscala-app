import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/session/session_controller.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/auth/data/invitation_repository.dart';
import 'package:niscala/features/auth/invitation_link.dart';
import 'package:niscala/features/auth/ui/auth_widgets.dart';
import 'package:niscala/features/tenants/ui/emergency_contact_fields.dart';
import 'package:niscala_api/api.dart';

const _linkRequired = 'Tempel tautan undangan dari pemilik kost.';
const _expiredMessage =
    'Tautan undangan sudah kedaluwarsa. Minta pemilik kost membuat tautan baru.';
const _usedMessage = 'Tautan undangan ini sudah dipakai.';
const _contactsHelper = 'Isi 2 sampai 4 kontak.';
const _contactsMinimum = 'Isi minimal 2 kontak darurat.';
const _minimumContacts = 2;

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
      setState(() => _linkError = _linkRequired);
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
        _banner = errorMessage(failure.code);
      });
    }
  }

  String _statusMessage(InvitationLinkStatus status) {
    if (status == InvitationLinkStatus.expired) return _expiredMessage;
    if (status == InvitationLinkStatus.used) return _usedMessage;
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
        LabeledField(
          label: 'Tautan undangan',
          required: true,
          helper: 'Tempel tautan yang dibagikan pemilik kost.',
          child: TextField(
            controller: _link,
            decoration: InputDecoration(errorText: _linkError),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
        ),
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
        for (var i = 0; i < _minimumContacts; i++) EmergencyContactDraft(),
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
    final requiresContacts = widget.preview.emergencyContactsRequired;

    final nameError = name.isEmpty ? 'Nama wajib diisi.' : null;
    final emailError = signUpEmailError(email);
    final passwordError = newPasswordError(password);
    final confirmError = confirmPasswordError(password, _confirm.text);
    final contactsError =
        requiresContacts && _contacts.length < _minimumContacts
        ? _contactsMinimum
        : null;
    final contactsValid = [for (final draft in _contacts) draft.validate()]
        .every((valid) => valid);
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
            emergencyContacts: requiresContacts
                ? [
                    for (final draft in _contacts)
                      EmergencyContact(
                        name: draft.name.text.trim(),
                        relationship: draft.relationship.text.trim(),
                        phone: draft.phone.text.trim(),
                      ),
                  ]
                : null,
          );
      await ref.read(sessionControllerProvider.notifier).signIn(session);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      _showFailure(failure);
    }
  }

  /// Shows a failure next to the field it belongs to, or as a banner.
  void _showFailure(ApiFailure failure) {
    final message = errorMessage(failure.code);
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

  List<Widget> _contactSection(ThemeData theme) => [
    Semantics(
      header: true,
      child: Text('Kontak darurat (wajib)', style: theme.textTheme.titleSmall),
    ),
    const SizedBox(height: 4),
    Semantics(
      liveRegion: _contactsError != null,
      child: Text(
        _contactsError ?? _contactsHelper,
        style: _contactsError == null
            ? theme.textTheme.bodyMedium
            : theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
      ),
    ),
    const SizedBox(height: 8),
    for (var i = 0; i < _contacts.length; i++) ...[
      EmergencyContactBlock(
        key: ObjectKey(_contacts[i]),
        index: i + 1,
        draft: _contacts[i],
        onRemove: () => _removeContact(_contacts[i]),
      ),
      const SizedBox(height: 16),
    ],
    if (_contacts.length < maxEmergencyContacts)
      OutlinedButton(
        onPressed: _addContact,
        child: const Text('Tambah Kontak Darurat'),
      ),
  ];

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
          ..._contactSection(theme),
        ],
      ],
    );
  }
}
