import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/navigation.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/managers/data/manager_repository.dart';
import 'package:niscala/features/properties/data/property_repository.dart';
import 'package:niscala/features/tenants/tenant_format.dart';
import 'package:niscala/features/tenants/ui/emergency_contact_fields.dart';
import 'package:niscala_api/api.dart';

const _phoneHelper =
    'Nomor ponsel Indonesia, diawali 08 atau 628. Contoh: 0812-5520-4471.';
const _group = 'Properti yang ditugaskan (wajib)';
const _nameRequired = 'Nama wajib diisi.';
const _phoneRequired = 'Nomor telepon wajib diisi.';
const _noProperty = 'Pilih minimal satu properti.';

/// The text shown under the name of an active manager, which cannot change.
final _nameLockedHint = errorMessageFor(
  const ApiFailure(code: 'MANAGER_NAME_NOT_EDITABLE'),
);

/// Adds a manager, or edits the manager [managerId]. The properties of the
/// Owner are offered as checkboxes. When adding, [propertyId] is the one
/// property checked from the start.
class ManagerFormScreen extends ConsumerWidget {
  const ManagerFormScreen({
    super.key,
    required this.propertyId,
    this.managerId,
  });

  final String propertyId;
  final String? managerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = managerId;
    final properties = ref.watch(propertyListProvider);
    final listPath = '/properti/$propertyId/pengelola';
    return Scaffold(
      appBar: DetailAppBar(
        title: id == null ? 'Tambah Pengelola' : 'Ubah Pengelola',
        // Kembali returns to the page the form was opened from. A new manager's
        // form is not nested under the list, so the list is named here.
        leading: BackButton(
          onPressed: () =>
              leavePageTo(context, id == null ? listPath : '$listPath/$id'),
        ),
      ),
      body: properties.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(propertyListProvider),
        ),
        data: (items) => id == null
            ? _ManagerForm(propertyId: propertyId, properties: items)
            : _EditLoader(
                propertyId: propertyId,
                managerId: id,
                properties: items,
              ),
      ),
    );
  }
}

/// Loads the manager to edit before its form is shown.
class _EditLoader extends ConsumerWidget {
  const _EditLoader({
    required this.propertyId,
    required this.managerId,
    required this.properties,
  });

  final String propertyId;
  final String managerId;
  final List<PropertySummary> properties;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(managerDetailProvider(managerId));
    return manager.when(
      skipLoadingOnReload: true,
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
      ),
      error: (error, _) => ErrorView(
        message: errorMessageFor(error),
        onRetry: () => ref.invalidate(managerDetailProvider(managerId)),
      ),
      data: (manager) => _ManagerForm(
        propertyId: propertyId,
        properties: properties,
        manager: manager,
      ),
    );
  }
}

class _ManagerForm extends ConsumerStatefulWidget {
  const _ManagerForm({
    required this.propertyId,
    required this.properties,
    this.manager,
  });

  final String propertyId;
  final List<PropertySummary> properties;

  /// Null when adding a manager.
  final Manager? manager;

  @override
  ConsumerState<_ManagerForm> createState() => _ManagerFormState();
}

class _ManagerFormState extends ConsumerState<_ManagerForm> {
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _phone = TextEditingController();

  /// The properties the manager is assigned to.
  final _checked = <String>{};

  var _busy = false;
  String? _nameError;
  String? _phoneError;
  String? _propertyError;
  String? _banner;

  @override
  void initState() {
    super.initState();
    final manager = widget.manager;
    if (manager == null) {
      _checked.add(widget.propertyId);
    } else {
      _name.text = manager.name;
      _nickname.text = manager.nickname ?? '';
      _phone.text = manager.phone;
      _checked.addAll(manager.properties.map((property) => property.id));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// An active manager keeps the name it activated with.
  bool get _nameLocked =>
      widget.manager?.accountStatus == ManagerAccountStatus.active;

  void _toggle(String propertyId, bool checked) => setState(() {
    if (checked) {
      _checked.add(propertyId);
    } else {
      _checked.remove(propertyId);
    }
  });

  Future<void> _submit() async {
    if (_busy) return;
    final name = _name.text.trim();
    final nickname = _nickname.text.trim();
    final phone = _phone.text.trim();

    final nameError = name.isEmpty ? _nameRequired : null;
    final phoneError = phone.isEmpty
        ? _phoneRequired
        : isValidIndonesianMobile(phone)
        ? null
        : invalidPhoneMessage;
    final propertyError = _checked.isEmpty ? _noProperty : null;

    final valid =
        nameError == null && phoneError == null && propertyError == null;
    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _propertyError = propertyError;
      _banner = null;
      _busy = valid;
    });
    if (!valid) return;

    final input = ManagerInput(
      name: name,
      nickname: nickname.isEmpty ? null : nickname,
      phone: phone,
      propertyIds: _checked.toList(),
    );
    await _send(input);
  }

  /// Saves the manager. A new manager opens its invitation; an edited one goes
  /// back to its detail.
  Future<void> _send(ManagerInput input) async {
    final manager = widget.manager;
    final repository = ref.read(managerRepositoryProvider);
    try {
      final saved = manager == null
          ? await repository.create(input)
          : await repository.update(manager.id, input);
      if (!mounted) return;
      ref.invalidate(managerListProvider);
      if (manager == null) {
        context.go(
          '/properti/${widget.propertyId}/pengelola/${saved.id}/undangan'
          '?baru=1',
        );
      } else {
        ref.invalidate(managerDetailProvider(manager.id));
        context.go('/properti/${widget.propertyId}/pengelola/${manager.id}');
      }
    } on ApiFailure catch (failure) {
      if (mounted) _showFailure(failure);
    }
  }

  /// Shows a failure next to the field it belongs to, or as a banner.
  void _showFailure(ApiFailure failure) {
    final field = failure.field;
    final message = errorMessageFor(failure, labels: personFormLabels);
    setState(() {
      _busy = false;
      if (field == 'name') {
        _nameError = message;
      } else if (field == 'phone') {
        _phoneError = message;
      } else if (field != null && field.startsWith('propertyIds')) {
        _propertyError = message;
      } else {
        _banner = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = _nameLocked;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NiscalaSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_banner != null) ...[FormMessage(_banner!), formGap],
                LabeledField(
                  label: 'Nama lengkap',
                  required: true,
                  helper: locked ? _nameLockedHint : null,
                  child: TextField(
                    controller: _name,
                    readOnly: locked,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(errorText: _nameError),
                  ),
                ),
                formGap,
                LabeledField(
                  label: 'Nama panggilan',
                  required: false,
                  child: TextField(
                    controller: _nickname,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                formGap,
                LabeledField(
                  label: 'Nomor telepon (WhatsApp)',
                  required: true,
                  helper: _phoneHelper,
                  child: TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(errorText: _phoneError),
                  ),
                ),
                formGap,
                Semantics(
                  header: true,
                  child: Text(_group, style: theme.textTheme.titleSmall),
                ),
                const SizedBox(height: 4),
                if (_propertyError != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _propertyError!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                for (final property in widget.properties)
                  CheckboxListTile(
                    value: _checked.contains(property.id),
                    onChanged: (checked) =>
                        _toggle(property.id, checked ?? false),
                    title: Text(property.name),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
        ActionFooter(
          primary: BusyButton(label: 'Simpan', busy: _busy, onPressed: _submit),
        ),
      ],
    );
  }
}
