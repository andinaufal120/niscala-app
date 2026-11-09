import 'package:flutter/material.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/core/widgets/labeled_field.dart';
import 'package:niscala/features/tenants/tenant_format.dart';

const maxEmergencyContacts = 4;

/// The fewest emergency contacts a form that asks for them accepts.
const minEmergencyContacts = 2;

const emergencyContactsHelper = 'Isi 2 sampai 4 kontak.';
const emergencyContactsMinimum = 'Isi minimal 2 kontak darurat.';

const invalidPhoneMessage =
    'Nomor telepon tidak valid. Contoh: 0812-5520-4471.';

const _contactPhoneRequired = 'Nomor telepon kontak wajib diisi.';

/// The text fields of one emergency contact, with the errors of its last
/// submit.
class EmergencyContactDraft {
  final name = TextEditingController();
  final relationship = TextEditingController();
  final phone = TextEditingController();
  String? nameError;
  String? relationshipError;
  String? phoneError;

  /// Checks the three fields, keeps each message on its field, and returns
  /// whether the contact is valid.
  bool validate() {
    final nameText = name.text.trim();
    final relationshipText = relationship.text.trim();
    final phoneText = phone.text.trim();
    nameError = nameText.isEmpty ? 'Nama kontak wajib diisi.' : null;
    relationshipError = relationshipText.isEmpty
        ? 'Hubungan wajib diisi.'
        : null;
    phoneError = phoneText.isEmpty
        ? _contactPhoneRequired
        : isValidIndonesianMobile(phoneText)
        ? null
        : invalidPhoneMessage;
    return nameError == null && relationshipError == null && phoneError == null;
  }

  void dispose() {
    name.dispose();
    relationship.dispose();
    phone.dispose();
  }
}

/// The emergency contacts of a form: a required heading, the help text or the
/// count error, one block per contact, and the button that adds one more.
class EmergencyContactsSection extends StatelessWidget {
  const EmergencyContactsSection({
    super.key,
    required this.drafts,
    required this.error,
    required this.onAdd,
    required this.onRemove,
  });

  final List<EmergencyContactDraft> drafts;

  /// The message of a failed count check. Null shows the help text.
  final String? error;
  final VoidCallback onAdd;
  final ValueChanged<EmergencyContactDraft> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Kontak darurat (wajib)',
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          liveRegion: error != null,
          child: Text(
            error ?? emergencyContactsHelper,
            style: error == null
                ? theme.textTheme.bodyMedium
                : theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        for (final (index, draft) in drafts.indexed) ...[
          EmergencyContactBlock(
            key: ObjectKey(draft),
            index: index + 1,
            draft: draft,
            onRemove: () => onRemove(draft),
          ),
          const SizedBox(height: 16),
        ],
        if (drafts.length < maxEmergencyContacts)
          OutlinedButton(
            onPressed: onAdd,
            child: const Text('Tambah Kontak Darurat'),
          ),
      ],
    );
  }
}

/// One emergency contact of a form, numbered for its remove button.
class EmergencyContactBlock extends StatelessWidget {
  const EmergencyContactBlock({
    super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
  });

  final int index;
  final EmergencyContactDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Kontak darurat $index',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Hapus kontak darurat $index',
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
            ),
          ],
        ),
        LabeledField(
          label: 'Nama kontak',
          required: true,
          child: TextField(
            controller: draft.name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(errorText: draft.nameError),
          ),
        ),
        formGap,
        LabeledField(
          label: 'Hubungan',
          required: true,
          child: TextField(
            controller: draft.relationship,
            decoration: InputDecoration(errorText: draft.relationshipError),
          ),
        ),
        formGap,
        LabeledField(
          label: 'Nomor telepon kontak',
          required: true,
          child: TextField(
            controller: draft.phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(errorText: draft.phoneError),
          ),
        ),
      ],
    );
  }
}
