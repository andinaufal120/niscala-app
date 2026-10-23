import 'package:flutter/material.dart';
import 'package:niscala/core/widgets/form_widgets.dart';
import 'package:niscala/features/tenants/tenant_format.dart';

const maxEmergencyContacts = 4;

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
        TextField(
          controller: draft.name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Nama kontak (wajib)',
            errorText: draft.nameError,
          ),
        ),
        formGap,
        TextField(
          controller: draft.relationship,
          decoration: InputDecoration(
            labelText: 'Hubungan (wajib)',
            errorText: draft.relationshipError,
          ),
        ),
        formGap,
        TextField(
          controller: draft.phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Nomor telepon kontak (wajib)',
            errorText: draft.phoneError,
          ),
        ),
      ],
    );
  }
}
