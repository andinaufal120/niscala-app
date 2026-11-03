import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/core/widgets/tappable_date_field.dart';
import 'package:niscala/features/rooms/data/room_repository.dart';
import 'package:niscala/features/tenants/data/tenant_repository.dart';
import 'package:niscala/features/tenants/tenant_format.dart';
import 'package:niscala/features/tenants/ui/emergency_contact_fields.dart';
import 'package:niscala_api/api.dart';

const _phoneHelper =
    'Nomor ponsel Indonesia, diawali 08 atau 628. Contoh: 0812-5520-4471.';
const _contactsHelper =
    'Isi 2 sampai 4 kontak, atau kosongkan agar penyewa melengkapinya saat '
    'aktivasi.';
const _contactsCount = 'Isi minimal 2 kontak darurat, atau kosongkan semuanya.';
const _endBeforeStart = 'Tanggal berakhir tidak boleh sebelum tanggal mulai.';
const _nextBillHint =
    'Perubahan tarif sewa atau siklus penagihan berlaku mulai tagihan '
    'berikutnya.';

/// Adds a tenant to a vacant room of the property, or edits the tenant
/// [tenantId]. The room of a tenant cannot change, so an edit shows it without
/// a room picker.
class TenantFormScreen extends ConsumerWidget {
  const TenantFormScreen({
    super.key,
    required this.propertyId,
    this.preselectedRoomId,
    this.tenantId,
  });

  final String propertyId;

  /// Chooses the room of a new tenant when it is one of the vacant rooms.
  final String? preselectedRoomId;

  /// The tenant to edit, or null to add one.
  final String? tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = tenantId;
    if (id != null) return _editPage(ref, id);
    final rooms = ref.watch(roomListProvider(propertyId));
    return Scaffold(
      appBar: const DetailAppBar(title: 'Tambah Penyewa'),
      body: rooms.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(roomListProvider(propertyId)),
        ),
        data: (items) => _TenantForm(
          propertyId: propertyId,
          vacantRooms: [
            for (final room in items)
              if (room.occupancy == Occupancy.vacant && room.editable) room,
          ],
          preselectedRoomId: preselectedRoomId,
        ),
      ),
    );
  }

  /// Loads the tenant to edit before its form is shown. The rooms are not
  /// needed, because a tenant keeps the room it has.
  Widget _editPage(WidgetRef ref, String id) {
    final tenant = ref.watch(tenantDetailProvider(id));
    return Scaffold(
      appBar: const DetailAppBar(title: 'Ubah Data Penyewa'),
      body: tenant.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(tenantDetailProvider(id)),
        ),
        data: (t) => _TenantForm(
          propertyId: propertyId,
          vacantRooms: const [],
          preselectedRoomId: null,
          tenant: t,
        ),
      ),
    );
  }
}

/// The calendar day of [date] as a UTC date, the form a picked date takes.
DateTime _utcDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

String _dateText(DateTime? date) => date == null ? '' : formatDate(date);

EmergencyContactDraft _draftOf(EmergencyContact contact) =>
    EmergencyContactDraft()
      ..name.text = contact.name
      ..relationship.text = contact.relationship
      ..phone.text = contact.phone;

class _TenantForm extends ConsumerStatefulWidget {
  const _TenantForm({
    required this.propertyId,
    required this.vacantRooms,
    required this.preselectedRoomId,
    this.tenant,
  });

  final String propertyId;
  final List<RoomSummary> vacantRooms;
  final String? preselectedRoomId;

  /// The tenant being edited, or null when adding one.
  final Tenant? tenant;

  @override
  ConsumerState<_TenantForm> createState() => _TenantFormState();
}

class _TenantFormState extends ConsumerState<_TenantForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _occupation = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _grace = TextEditingController(text: '0');
  final _rent = TextEditingController();
  final _contacts = <EmergencyContactDraft>[];

  String? _roomId;
  DateTime? _startDate;
  DateTime? _endDate;
  BillingCycle _cycle = BillingCycle.monthly;

  /// Once the user types a rent, it is never filled in again by the room or
  /// the billing cycle.
  var _rentEdited = false;
  var _busy = false;
  String? _roomError;
  String? _nameError;
  String? _phoneError;
  String? _contactsError;
  String? _endError;
  String? _rentError;
  String? _banner;

  bool get _editing => widget.tenant != null;

  @override
  void initState() {
    super.initState();
    final tenant = widget.tenant;
    if (tenant == null) {
      final preselected = widget.preselectedRoomId;
      _roomId = widget.vacantRooms.any((room) => room.id == preselected)
          ? preselected
          : null;
    } else {
      _fillFrom(tenant);
    }
    _applyRentDefault();
  }

  /// Fills the fields with the values of the tenant being edited.
  void _fillFrom(Tenant tenant) {
    final lease = tenant.lease;
    final start = lease.startDate;
    final end = lease.endDate;
    _name.text = tenant.name;
    _phone.text = tenant.phone;
    _occupation.text = tenant.occupation ?? '';
    _startDate = start == null ? null : _utcDay(start);
    _endDate = end == null ? null : _utcDay(end);
    _start.text = _dateText(_startDate);
    _end.text = _dateText(_endDate);
    _cycle = lease.billingCycle;
    _grace.text = '${lease.gracePeriodDays}';
    _rent.text = '${lease.rent}';
    _contacts.addAll(tenant.emergencyContacts.map(_draftOf));
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _occupation,
      _start,
      _end,
      _grace,
      _rent,
    ]) {
      controller.dispose();
    }
    for (final draft in _contacts) {
      draft.dispose();
    }
    super.dispose();
  }

  RoomSummary? get _room {
    for (final room in widget.vacantRooms) {
      if (room.id == _roomId) return room;
    }
    return null;
  }

  /// A monthly rent starts at the base rate of the chosen room. Other cycles
  /// start empty. Nothing changes once the user has typed a rent, and a tenant
  /// being edited keeps the rent of its lease.
  void _applyRentDefault() {
    if (_editing || _rentEdited) return;
    final room = _room;
    _rent.text = room != null && _cycle == BillingCycle.monthly
        ? '${room.baseRate}'
        : '';
  }

  void _chooseRoom(String? roomId) {
    setState(() {
      _roomId = roomId;
      _roomError = null;
      _applyRentDefault();
    });
  }

  void _chooseCycle(BillingCycle? cycle) {
    if (cycle == null) return;
    setState(() {
      _cycle = cycle;
      _applyRentDefault();
    });
  }

  void _addContact() => setState(() => _contacts.add(EmergencyContactDraft()));

  void _removeContact(EmergencyContactDraft draft) {
    setState(() => _contacts.remove(draft));
    // The removed block still holds its controllers until this frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) => draft.dispose());
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    // A UTC date keeps the calendar day when the lease is sent to the API.
    final date = DateTime.utc(picked.year, picked.month, picked.day);
    setState(() {
      if (start) {
        _startDate = date;
        _start.text = formatDate(date);
      } else {
        _endDate = date;
        _end.text = formatDate(date);
        _endError = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final tenant = widget.tenant;
    final roomId = _roomId;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final occupation = _occupation.text.trim();
    final rentText = _rent.text;
    final rent = int.tryParse(rentText);
    final start = _startDate;
    final end = _endDate;

    final roomError = tenant == null && roomId == null ? 'Pilih kamar.' : null;
    final nameError = name.isEmpty ? 'Nama wajib diisi.' : null;
    final phoneError = phone.isEmpty
        ? 'Nomor telepon wajib diisi.'
        : isValidIndonesianMobile(phone)
        ? null
        : invalidPhoneMessage;
    final rentError = rentText.isEmpty
        ? 'Tarif sewa wajib diisi.'
        : rent == null || rent <= 0
        ? 'Tarif sewa harus lebih dari 0.'
        : null;
    final endError = start != null && end != null && end.isBefore(start)
        ? _endBeforeStart
        : null;
    final contactsError = _contacts.length == 1 ? _contactsCount : null;
    final contactsValid = [for (final draft in _contacts) draft.validate()]
        .every((valid) => valid);

    final valid =
        roomError == null &&
        nameError == null &&
        phoneError == null &&
        rentError == null &&
        endError == null &&
        contactsError == null &&
        contactsValid;
    setState(() {
      _roomError = roomError;
      _nameError = nameError;
      _phoneError = phoneError;
      _contactsError = contactsError;
      _endError = endError;
      _rentError = rentError;
      _banner = null;
      _busy = valid;
    });
    if (!valid) return;

    final occupationValue = occupation.isEmpty ? null : occupation;
    final contacts = [
      for (final draft in _contacts)
        EmergencyContact(
          name: draft.name.text.trim(),
          relationship: draft.relationship.text.trim(),
          phone: draft.phone.text.trim(),
        ),
    ];
    final lease = LeaseInput(
      startDate: start,
      endDate: end,
      billingCycle: _cycle,
      rent: rent!,
      gracePeriodDays: int.tryParse(_grace.text.trim()) ?? 0,
    );
    if (tenant == null) {
      await _create(
        NewTenantInput(
          roomId: roomId!,
          name: name,
          phone: phone,
          occupation: occupationValue,
          emergencyContacts: contacts,
          lease: lease,
        ),
      );
    } else {
      await _update(
        tenant.id,
        TenantInput(
          name: name,
          phone: phone,
          occupation: occupationValue,
          emergencyContacts: contacts,
          lease: lease,
        ),
      );
    }
  }

  /// Sends the new tenant. On success the share screen opens in place of the
  /// form, marked as new.
  Future<void> _create(NewTenantInput input) async {
    try {
      final tenant = await ref
          .read(tenantRepositoryProvider)
          .create(widget.propertyId, input);
      if (!mounted) return;
      ref.invalidate(tenantListProvider(widget.propertyId));
      ref.invalidate(roomListProvider(widget.propertyId));
      context.go(
        '/properti/${widget.propertyId}/penyewa/${tenant.id}/undangan?baru=1',
      );
    } on ApiFailure catch (failure) {
      if (mounted) _showFailure(failure);
    }
  }

  /// Saves the edited tenant. On success the detail opens in place of the form,
  /// and the lists and the detail are reloaded.
  Future<void> _update(String tenantId, TenantInput input) async {
    try {
      await ref.read(tenantRepositoryProvider).update(tenantId, input);
      if (!mounted) return;
      ref.invalidate(tenantDetailProvider(tenantId));
      ref.invalidate(tenantListProvider(widget.propertyId));
      context.go('/properti/${widget.propertyId}/penyewa/$tenantId');
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
      if (field == 'roomId') {
        _roomError = message;
      } else if (field == 'name') {
        _nameError = message;
      } else if (field == 'phone') {
        _phoneError = message;
      } else if (field != null && field.startsWith('emergencyContacts')) {
        _contactsError = message;
      } else if (field == 'lease.rent') {
        _rentError = message;
      } else if (field == 'lease.endDate') {
        _endError = message;
      } else {
        _banner = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tenant = widget.tenant;
    final noRooms = tenant == null && widget.vacantRooms.isEmpty;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NiscalaSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_banner != null) ...[FormMessage(_banner!), formGap],
                if (tenant == null) ...[
                  if (noRooms) ...[
                    Text(
                      'Tidak ada kamar kosong. Tambahkan kamar terlebih dahulu.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    formGap,
                  ],
                  LabeledField(
                    label: 'Kamar',
                    required: true,
                    child: DropdownButtonFormField<String>(
                      initialValue: _roomId,
                      isExpanded: true,
                      decoration: InputDecoration(errorText: _roomError),
                      items: [
                        for (final room in widget.vacantRooms)
                          DropdownMenuItem(
                            value: room.id,
                            child: Text('Kamar ${room.number}'),
                          ),
                      ],
                      onChanged: noRooms ? null : _chooseRoom,
                    ),
                  ),
                  formGap,
                ] else ...[
                  Text('Kamar', style: theme.textTheme.labelLarge),
                  Text('Kamar ${tenant.room.number}'),
                  formGap,
                ],
                LabeledField(
                  label: 'Nama lengkap',
                  required: true,
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(errorText: _nameError),
                  ),
                ),
                formGap,
                LabeledField(
                  label: 'Nomor telepon',
                  required: true,
                  helper: _phoneHelper,
                  child: TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(errorText: _phoneError),
                  ),
                ),
                formGap,
                LabeledField(
                  label: 'Pekerjaan / instansi',
                  required: false,
                  child: TextField(
                    controller: _occupation,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                formGap,
                Semantics(
                  header: true,
                  child: Text(
                    'Kontak darurat (opsional)',
                    style: theme.textTheme.titleSmall,
                  ),
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
                formGap,
                Semantics(
                  header: true,
                  child: Text('Masa sewa', style: theme.textTheme.titleSmall),
                ),
                const SizedBox(height: 8),
                if (tenant != null) ...[
                  Text(_nextBillHint, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                ],
                TappableDateField(
                  label: 'Tanggal mulai',
                  required: false,
                  controller: _start,
                  onTap: () => _pickDate(start: true),
                ),
                formGap,
                TappableDateField(
                  label: 'Tanggal berakhir',
                  required: false,
                  controller: _end,
                  onTap: () => _pickDate(start: false),
                  errorText: _endError,
                ),
                formGap,
                LabeledField(
                  label: 'Siklus penagihan',
                  required: true,
                  child: DropdownButtonFormField<BillingCycle>(
                    initialValue: _cycle,
                    isExpanded: true,
                    items: [
                      for (final cycle in BillingCycle.values)
                        DropdownMenuItem(
                          value: cycle,
                          child: Text(billingCycleLabel(cycle)),
                        ),
                    ],
                    onChanged: _chooseCycle,
                  ),
                ),
                formGap,
                LabeledField(
                  label: 'Masa tenggang dalam hari',
                  required: false,
                  child: TextField(
                    controller: _grace,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                formGap,
                LabeledField(
                  label: 'Tarif sewa per siklus',
                  required: true,
                  child: TextField(
                    controller: _rent,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) {
                      _rentEdited = true;
                    },
                    decoration: InputDecoration(
                      prefixIcon: const ExcludeSemantics(
                        child: Padding(
                          padding: EdgeInsets.only(left: 14, right: 4),
                          child: Text('Rp'),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(),
                      errorText: _rentError,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ActionFooter(
          primary: BusyButton(
            label: tenant == null ? 'Simpan Penyewa' : 'Simpan Perubahan',
            busy: _busy,
            onPressed: noRooms ? null : _submit,
          ),
        ),
      ],
    );
  }
}
