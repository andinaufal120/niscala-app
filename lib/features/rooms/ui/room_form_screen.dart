import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/tokens.dart';
import 'package:niscala/core/widgets/action_footer.dart';
import 'package:niscala/core/widgets/detail_app_bar.dart';
import 'package:niscala/core/widgets/error_view.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/core/widgets/section_card.dart';
import 'package:niscala/features/rooms/data/room_repository.dart';
import 'package:niscala/features/rooms/ui/room_widgets.dart';
import 'package:niscala_api/api.dart';

const _rateHelper =
    'Dipakai sebagai nilai awal saat mendaftarkan penyewa. Tarif tiap masa '
    'sewa bisa disesuaikan.';
const _rateHelperEdit =
    'Mengubah tarif dasar tidak mengubah tarif sewa masa sewa yang sudah ada.';
const _facilityHelper =
    'Ketik lalu ketuk Tambah. Maks. 15 fasilitas, 30 karakter per fasilitas.';
const _dimensionError =
    'Gunakan angka lebih dari 0 hingga 20, maksimal 2 desimal (contoh: 3,5).';
const _pairError = 'Isi panjang dan lebar, atau kosongkan keduanya.';
const _tagTooLong = 'Fasilitas maksimal 30 karakter.';
const _tagLimit = 'Sudah mencapai 15 fasilitas.';
const _maxTags = 15;
const _maxTagLength = 30;

/// A length or width in metres: a positive number of at most 2 decimals, up to
/// 20, with a decimal comma.
final _sizePattern = RegExp(r'^\d+(,\d{1,2})?$');

/// Adds a room when [roomId] is null, and edits the room with that id
/// otherwise.
class RoomFormScreen extends ConsumerWidget {
  const RoomFormScreen({super.key, required this.propertyId, this.roomId});

  final String propertyId;
  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = roomId;
    if (id == null) {
      return _RoomForm(propertyId: propertyId, roomId: null, room: null);
    }
    return ref
        .watch(roomDetailProvider(id))
        .when(
          skipLoadingOnReload: true,
          loading: () => _editPage(
            const Center(
              child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
            ),
          ),
          error: (error, _) => _editPage(
            ErrorView(
              message: errorMessageFor(error),
              onRetry: () => ref.invalidate(roomDetailProvider(id)),
            ),
          ),
          data: (room) =>
              _RoomForm(propertyId: propertyId, roomId: id, room: room),
        );
  }
}

Scaffold _editPage(Widget body) => Scaffold(
  appBar: const DetailAppBar(title: 'Ubah Kamar'),
  body: body,
);

/// The text of a dimension in the form, with a decimal comma.
String? _sizeText(num? value) => value == null ? null : formatMeasure(value);

/// The value of a dimension typed into the form, or null when it is empty or
/// not valid.
double? _parseSize(String text) {
  final trimmed = text.trim();
  if (!_sizePattern.hasMatch(trimmed)) return null;
  final value = double.parse(trimmed.replaceFirst(',', '.'));
  return value > 0 && value <= 20 ? value : null;
}

class _RoomForm extends ConsumerStatefulWidget {
  const _RoomForm({
    required this.propertyId,
    required this.roomId,
    required this.room,
  });

  final String propertyId;
  final String? roomId;
  final Room? room;

  @override
  ConsumerState<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends ConsumerState<_RoomForm> {
  late final _number = TextEditingController(text: widget.room?.number);
  late final _rate = TextEditingController(
    text: widget.room?.baseRate.toString(),
  );
  late final _length = TextEditingController(
    text: _sizeText(widget.room?.lengthM),
  );
  late final _width = TextEditingController(
    text: _sizeText(widget.room?.widthM),
  );
  late final _facility = TextEditingController();
  late final List<String> _tags = List.of(
    widget.room?.facilities ?? const <String>[],
  );
  var _busy = false;
  String? _numberError;
  String? _rateError;
  String? _lengthError;
  String? _widthError;
  String? _facilityError;
  String? _banner;

  @override
  void dispose() {
    _number.dispose();
    _rate.dispose();
    _length.dispose();
    _width.dispose();
    _facility.dispose();
    super.dispose();
  }

  /// The area for display, once both dimensions are valid.
  String? get _areaText {
    final length = _parseSize(_length.text);
    final width = _parseSize(_width.text);
    if (length == null || width == null) return null;
    return 'Luas: ${formatMeasure(length * width)} m²';
  }

  /// The tags of the property that are not chosen yet and match the typed
  /// text, ignoring case.
  List<String> _suggestions() {
    final all =
        ref.watch(facilitySuggestionsProvider(widget.propertyId)).value ??
        const <String>[];
    final query = _facility.text.trim().toLowerCase();
    return [
      for (final tag in all)
        if (!_tags.contains(tag) && tag.contains(query)) tag,
    ];
  }

  /// Why [tag] cannot be added, or null when it can. A tag already chosen is
  /// not an error: it is dropped.
  String? _tagError(String tag) {
    if (_tags.contains(tag)) return null;
    if (tag.length > _maxTagLength) return _tagTooLong;
    if (_tags.length >= _maxTags) return _tagLimit;
    return null;
  }

  /// Adds [raw] as a tag, normalised like the API does: trimmed, lowercase,
  /// with repeated spaces collapsed.
  void _addTag(String raw) {
    final tag = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (tag.isEmpty) return;
    final error = _tagError(tag);
    setState(() {
      _facilityError = error;
      if (error == null && !_tags.contains(tag)) _tags.add(tag);
    });
    if (error == null) _facility.clear();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final number = _number.text.trim();
    final rateText = _rate.text;
    final rate = int.tryParse(rateText);
    final lengthText = _length.text.trim();
    final widthText = _width.text.trim();
    final length = _parseSize(lengthText);
    final width = _parseSize(widthText);

    final numberError = number.isEmpty ? 'Nomor kamar wajib diisi.' : null;
    final rateError = rateText.isEmpty
        ? 'Tarif sewa wajib diisi.'
        : rate == null || rate <= 0
        ? 'Tarif sewa harus lebih dari 0.'
        : null;
    String? lengthError;
    String? widthError;
    if (lengthText.isNotEmpty && length == null) {
      lengthError = _dimensionError;
    } else if (widthText.isNotEmpty && width == null) {
      widthError = _dimensionError;
    } else if (lengthText.isEmpty && widthText.isNotEmpty) {
      lengthError = _pairError;
    } else if (widthText.isEmpty && lengthText.isNotEmpty) {
      widthError = _pairError;
    }

    final valid = [
      numberError,
      rateError,
      lengthError,
      widthError,
    ].every((error) => error == null);
    setState(() {
      _numberError = numberError;
      _rateError = rateError;
      _lengthError = lengthError;
      _widthError = widthError;
      _facilityError = null;
      _banner = null;
      _busy = valid;
    });
    if (!valid) return;

    final input = RoomInput(
      number: number,
      baseRate: rate!,
      lengthM: length,
      widthM: width,
      facilities: List.of(_tags),
    );
    final failure = await _attempt(input);
    if (!mounted) return;
    if (failure == null) {
      _finish();
    } else {
      _showFailure(failure);
    }
  }

  /// Sends the add or the edit. Returns the failure, or null on success.
  Future<ApiFailure?> _attempt(RoomInput input) async {
    final repo = ref.read(roomRepositoryProvider);
    final id = widget.roomId;
    try {
      if (id == null) {
        await repo.create(widget.propertyId, input);
      } else {
        await repo.update(id, input);
      }
      return null;
    } on ApiFailure catch (failure) {
      return failure;
    }
  }

  void _finish() {
    final id = widget.roomId;
    ref.invalidate(roomListProvider(widget.propertyId));
    if (id != null) ref.invalidate(roomDetailProvider(id));
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(id == null ? 'Kamar ditambahkan' : 'Perubahan tersimpan'),
      ),
    );
  }

  /// Shows a failure next to the field it belongs to, or as a banner.
  void _showFailure(ApiFailure failure) {
    final message = errorMessage(failure.code);
    final field = failure.field;
    setState(() {
      _busy = false;
      if (field == 'number') {
        _numberError = message;
      } else if (field == 'baseRate') {
        _rateError = message;
      } else if (field == 'lengthM') {
        _lengthError = message;
      } else if (field == 'widthM') {
        _widthError = message;
      } else if (field != null && field.startsWith('facilities')) {
        _facilityError = message;
      } else {
        _banner = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final isEdit = widget.roomId != null;
    final theme = Theme.of(context);
    final suggestions = _suggestions();
    final area = _areaText;
    return Scaffold(
      appBar: DetailAppBar(
        title: room == null ? 'Tambah Kamar' : 'Ubah Kamar ${room.number}',
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NiscalaSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_banner != null) ...[FormMessage(_banner!), formGap],
                  LabeledField(
                    label: 'Nomor kamar',
                    required: true,
                    child: TextField(
                      controller: _number,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 08',
                        errorText: _numberError,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  formGap,
                  LabeledField(
                    label: 'Tarif dasar per bulan',
                    required: true,
                    helper: isEdit
                        ? '$_rateHelper $_rateHelperEdit'
                        : _rateHelper,
                    child: TextField(
                      controller: _rate,
                      decoration: InputDecoration(
                        prefixIcon: const ExcludeSemantics(
                          child: Padding(
                            padding: EdgeInsets.only(left: 14, right: 4),
                            child: Text('Rp'),
                          ),
                        ),
                        errorText: _rateError,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  formGap,
                  SectionCard(
                    title: 'Ukuran kamar (opsional)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LabeledField(
                          label: 'Panjang (m)',
                          child: TextField(
                            controller: _length,
                            decoration: InputDecoration(
                              errorText: _lengthError,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        formGap,
                        LabeledField(
                          label: 'Lebar (m)',
                          child: TextField(
                            controller: _width,
                            decoration: InputDecoration(errorText: _widthError),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        if (area != null) ...[
                          formGap,
                          Semantics(
                            liveRegion: true,
                            child: Text(area, style: theme.textTheme.bodyLarge),
                          ),
                        ],
                      ],
                    ),
                  ),
                  formGap,
                  SectionCard(
                    title: 'Fasilitas (opsional)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LabeledField(
                          label: 'Tambah fasilitas',
                          helper: _facilityHelper,
                          child: TextField(
                            controller: _facility,
                            decoration: InputDecoration(
                              errorText: _facilityError,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _addTag(_facility.text),
                          child: const Text('Tambah'),
                        ),
                        if (_tags.isNotEmpty) ...[
                          formGap,
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in _tags)
                                _ChosenTag(
                                  tag: tag,
                                  onRemove: () =>
                                      setState(() => _tags.remove(tag)),
                                ),
                            ],
                          ),
                        ],
                        if (suggestions.isNotEmpty) ...[
                          formGap,
                          Semantics(
                            header: true,
                            child: Text(
                              'Saran fasilitas',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in suggestions)
                                ActionChip(
                                  label: Text(tag),
                                  onPressed: () => _addTag(tag),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ActionFooter(
            primary: BusyButton(
              label: isEdit ? 'Simpan Perubahan' : 'Simpan Kamar',
              busy: _busy,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

/// A chosen facility tag with its remove button.
class _ChosenTag extends StatelessWidget {
  const _ChosenTag({required this.tag, required this.onRemove});

  final String tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(tag),
            ),
          ),
          MergeSemantics(
            child: Semantics(
              label: 'Hapus fasilitas $tag',
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
