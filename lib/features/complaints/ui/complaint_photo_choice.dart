import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala/core/api/api_failure.dart';
import 'package:niscala/core/api/error_messages.dart';
import 'package:niscala/core/image_chooser.dart';
import 'package:niscala/core/widgets/image_source_sheet.dart';

const _typeInvalid = ApiFailure(code: 'PHOTO_TYPE_INVALID');
const _tooLarge = ApiFailure(code: 'PHOTO_TOO_LARGE');

/// The outcome of a photo choice: the accepted [photo], or the [error] message
/// to show when the photo was rejected or could not be chosen.
typedef PhotoChoice = ({PickedImage? photo, String? error});

/// Asks for the source of a complaint photo, then picks and checks the image.
///
/// Resolves to null when the user cancels. A rejected image, or a camera or
/// gallery that cannot be used, gives no photo and the message to show.
Future<PhotoChoice?> choosePhoto(BuildContext context, WidgetRef ref) async {
  final origin = await chooseImageSource(context);
  if (origin == null || !context.mounted) return null;
  final PickedImage? file;
  try {
    file = await ref.read(imageChooserProvider).pick(origin);
  } on PlatformException {
    return (photo: null, error: imageAccessDeniedMessage);
  }
  if (file == null) return null;
  final rejection = imageRejection(file);
  if (rejection == null) return (photo: file, error: null);
  final failure = rejection == ImageRejection.type ? _typeInvalid : _tooLarge;
  return (photo: null, error: errorMessageFor(failure));
}
