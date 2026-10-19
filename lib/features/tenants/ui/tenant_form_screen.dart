import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/format.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
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

/// Adds a tenant to a vacant room of the property. [preselectedRoomId] chooses
/// the room when it is one of the vacant rooms.
class TenantFormScreen extends ConsumerWidget {
  const TenantFormScreen({
    super.key,
    required this.propertyId,
    this.preselectedRoomId,
  });

  final String propertyId;
  final String? preselectedRoomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomListProvider(propertyId));
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Penyewa')),
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
}

class _TenantForm extends ConsumerStatefulWidget {
  const _TenantForm({
    required this.propertyId,
    required this.vacantRooms,
    required this.preselectedRoomId,
  });

  final String propertyId;
  final List<RoomSummary> vacantRooms;
  final String? preselectedRoomId;

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

  @override
  void initState() {
    super.initState();
    final preselected = widget.preselectedRoomId;
    _roomId = widget.vacantRooms.any((room) => room.id == preselected)
        ? preselected
        : null;
    _applyRentDefault();
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
  /// start empty. Nothing changes once the user has typed a rent.
  void _applyRentDefault() {
    if (_rentEdited) return;
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
    final roomId = _roomId;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final occupation = _occupation.text.trim();
    final rentText = _rent.text;
    final rent = int.tryParse(rentText);
    final start = _startDate;
    final end = _endDate;

    final roomError = roomId == null ? 'Pilih kamar.' : null;
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

    final input = NewTenantInput(
      roomId: roomId!,
      name: name,
      phone: phone,
      occupation: occupation.isEmpty ? null : occupation,
      emergencyContacts: [
        for (final draft in _contacts)
          EmergencyContact(
            name: draft.name.text.trim(),
            relationship: draft.relationship.text.trim(),
            phone: draft.phone.text.trim(),
          ),
      ],
      lease: LeaseInput(
        startDate: start,
        endDate: end,
        billingCycle: _cycle,
        rent: rent!,
        gracePeriodDays: int.tryParse(_grace.text.trim()) ?? 0,
      ),
    );
    await _send(input);
  }

  /// Sends the new tenant. On success the share screen opens in place of the
  /// form, marked as new.
  Future<void> _send(NewTenantInput input) async {
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

  /// Shows a failure next to the field it belongs to, or as a banner.
  void _showFailure(ApiFailure failure) {
    final message = errorMessage(failure.code);
    final field = failure.field;
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
    final noRooms = widget.vacantRooms.isEmpty;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NiscalaSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_banner != null) ...[FormMessage(_banner!), formGap],
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
                LabeledField(
                  label: 'Tanggal mulai',
                  required: false,
                  child: TextField(
                    controller: _start,
                    readOnly: true,
                    onTap: () => _pickDate(start: true),
                  ),
                ),
                formGap,
                LabeledField(
                  label: 'Tanggal berakhir',
                  required: false,
                  child: TextField(
                    controller: _end,
                    readOnly: true,
                    onTap: () => _pickDate(start: false),
                    decoration: InputDecoration(errorText: _endError),
                  ),
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
            label: 'Simpan Penyewa',
            busy: _busy,
            onPressed: noRooms ? null : _submit,
          ),
        ),
      ],
    );
  }
}
