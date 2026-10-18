import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/features/tenants/tenant_format.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a text to the platform share sheet. Tests replace it to record what
/// would be shared.
final invitationSharerProvider = Provider<Future<void> Function(String text)>(
  (ref) => (text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  },
);

/// The message that sends an invitation link to a tenant.
String invitationShareText({required String tenantName, required String url}) =>
    'Halo ${firstNameOf(tenantName)}, ini tautan undangan untuk mengaktifkan '
    'akun Niscala Anda: $url';
