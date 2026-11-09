import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/image_chooser.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/empty_state.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/complaints/data/complaint_repository.dart';
import 'package:niscala/features/complaints/ui/complaint_photo_choice.dart';
import 'package:niscala/features/complaints/ui/complaint_widgets.dart';
import 'package:niscala/features/lease/data/lease_repository.dart';
import 'package:niscala/features/lease/ui/lease_card.dart';
import 'package:niscala_api/api.dart';

const _helper = 'Ceritakan masalahnya, minimal 10 karakter.';
const _required = 'Deskripsi keluhan wajib diisi.';
const _tooShort = 'Tulis minimal 10 karakter.';
const _tooLong = 'Keluhan terlalu panjang. Maksimal 2000 karakter.';
const _roomRequired = 'Pilih kamar.';
const _minLength = 10;
const _maxLength = 2000;

/// Submits a complaint about one room of the tenant, with an optional photo.
/// The complaint is saved first and the photo uploaded to it. On success the
/// detail screen opens at once, while the AI classification may still be
/// running. If only the upload fails, the detail opens with a warning.
class ComplaintFormScreen extends ConsumerStatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  ConsumerState<ComplaintFormScreen> createState() =>
      _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends ConsumerState<ComplaintFormScreen> {
  final _description = TextEditingController();

  var _busy = false;
  String? _descriptionError;

  /// The room picked when the tenant has several leases. Null until chosen.
  String? _roomId;
  String? _roomError;

  /// Failures that are not about the description or the room. The banner stays
  /// until the next submit, and the text the user wrote is kept.
  String? _banner;

  /// The photo sent with the complaint, and the message for a rejected choice.
  PickedImage? _photo;
  String? _photoError;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final choice = await choosePhoto(context, ref);
    if (choice == null || !mounted) return;
    setState(() {
      _photo = choice.photo;
      _photoError = choice.error;
    });
  }

  void _removePhoto() => setState(() {
    _photo = null;
    _photoError = null;
  });

  Future<void> _submit(List<CurrentLease> leases) async {
    if (_busy) return;
    final text = _description.text.trim();
    final descriptionError = text.isEmpty
        ? _required
        : text.length < _minLength
        ? _tooShort
        : text.length > _maxLength
        ? _tooLong
        : null;
    final roomId = leases.length == 1 ? leases.single.room.id : _roomId;
    final roomError = roomId == null ? _roomRequired : null;
    setState(() {
      _descriptionError = descriptionError;
      _roomError = roomError;
      _banner = null;
      _busy = descriptionError == null && roomError == null;
    });
    if (_busy) await _send(text, roomId!);
  }

  Future<void> _send(String description, String roomId) async {
    final repository = ref.read(complaintRepositoryProvider);
    final Complaint complaint;
    try {
      complaint = await repository.submit(description, roomId);
    } on ApiFailure catch (failure) {
      if (mounted) _showFailure(failure);
      return;
    }
    final photo = _photo;
    var photoFailed = false;
    if (photo != null) {
      try {
        await repository.uploadPhoto(complaint.id, photo);
      } on ApiFailure {
        photoFailed = true;
      }
    }
    if (!mounted) return;
    ref.invalidate(complaintListProvider);
    final query = photoFailed ? 'terkirim=1&fotoGagal=1' : 'terkirim=1';
    context.go('/penyewa/keluhan/${complaint.id}?$query');
  }

  /// Shows a failure next to the field it names, or as a banner.
  void _showFailure(ApiFailure failure) {
    final message = errorMessageFor(failure);
    setState(() {
      _busy = false;
      switch (failure.field) {
        case 'description':
          _descriptionError = message;
        case 'roomId':
          _roomError = message;
        default:
          _banner = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leases = ref.watch(myLeasesProvider);
    return Scaffold(
      appBar: const DetailAppBar(title: 'Ajukan Keluhan'),
      body: leases.when(
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
        ),
        error: (error, _) => ErrorView(
          message: errorMessageFor(error),
          onRetry: () => ref.invalidate(myLeasesProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(message: noActiveLeaseMessage)
            : _form(items),
      ),
    );
  }

  Widget _form(List<CurrentLease> leases) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NiscalaSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_banner != null) ...[FormMessage(_banner!), formGap],
                _RoomPicker(
                  leases: leases,
                  selected: _roomId,
                  error: _roomError,
                  onChanged: (roomId) => setState(() => _roomId = roomId),
                ),
                formGap,
                LabeledField(
                  label: 'Deskripsi keluhan',
                  required: true,
                  helper: _helper,
                  child: TextField(
                    controller: _description,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 4,
                    maxLines: null,
                    decoration: InputDecoration(errorText: _descriptionError),
                  ),
                ),
                formGap,
                _photoField(Theme.of(context)),
              ],
            ),
          ),
        ),
        ActionFooter(
          primary: BusyButton(
            label: 'Kirim Keluhan',
            busy: _busy,
            onPressed: () => _submit(leases),
          ),
        ),
      ],
    );
  }

  /// The optional photo: a preview of the chosen image, the choice of camera or
  /// gallery, and the rejection or access message.
  Widget _photoField(ThemeData theme) {
    final photo = _photo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Foto (opsional)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        if (photo != null) ...[
          SizedBox(
            height: 240,
            child: Image.memory(
              photo.bytes,
              fit: BoxFit.contain,
              semanticLabel: 'Pratinjau foto yang dipilih',
              errorBuilder: (_, _, _) =>
                  const Center(child: Text(unreadablePhotoMessage)),
            ),
          ),
          const SizedBox(height: NiscalaSpacing.s),
        ],
        OutlinedButton.icon(
          onPressed: _busy ? null : _choosePhoto,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Ambil atau pilih foto'),
        ),
        if (photo != null)
          TextButton(
            onPressed: _busy ? null : _removePhoto,
            child: const Text('Hapus foto'),
          ),
        if (_photoError != null) ...[
          const SizedBox(height: NiscalaSpacing.s),
          FieldMessage(_photoError!),
        ],
      ],
    );
  }
}

/// The room of the complaint. One lease shows its room read-only. Several
/// leases offer one choice each, and the tenant must pick one.
class _RoomPicker extends StatelessWidget {
  const _RoomPicker({
    required this.leases,
    required this.selected,
    required this.error,
    required this.onChanged,
  });

  final List<CurrentLease> leases;
  final String? selected;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorText = error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leases.length == 1)
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kamar', style: theme.textTheme.titleSmall),
                Text(_placeOf(leases.single)),
              ],
            ),
          )
        else
          RadioGroup<String>(
            groupValue: selected,
            onChanged: (roomId) => onChanged(roomId!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Kamar (wajib)', style: theme.textTheme.titleSmall),
                for (final lease in leases)
                  RadioListTile<String>(
                    value: lease.room.id,
                    title: Text(_placeOf(lease)),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        if (errorText != null)
          Text(
            errorText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }
}

String _placeOf(CurrentLease lease) =>
    '${lease.property.name} · Kamar ${lease.room.number}';
