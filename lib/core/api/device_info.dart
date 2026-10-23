import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niscala_api/api.dart';

final deviceInfoProvider = FutureProvider<DeviceInfo>((ref) async {
  final info = await DeviceInfoPlugin().androidInfo;
  return DeviceInfo(
    name: info.model,
    platform: 'Android ${info.version.release}',
  );
});
