import 'package:flutter/material.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';

/// Whether [failure] says the record changed since the edit form read it.
bool isVersionConflict(ApiFailure failure) =>
    failure.code == 'RESOURCE_VERSION_CONFLICT';

/// Shows the conflict message of [failure] in [messenger]. An edit form calls
/// it after it has left the form, with the messenger it captured before
/// leaving, so the message reaches the screen it returns to.
void showVersionConflict(ScaffoldMessengerState messenger, ApiFailure failure) {
  messenger.showSnackBar(SnackBar(content: Text(errorMessageFor(failure))));
}
