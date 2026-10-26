import 'package:json_annotation/json_annotation.dart';

part 'alice_device_info.g.dart';

/// Connected mobile device metadata packet
@JsonSerializable(explicitToJson: true)
class AliceDeviceInfo {
  final String appName;
  final String deviceName;
  final String platform;
  final String osVersion;
  final String? ipAddress;

  const AliceDeviceInfo({
    required this.appName,
    required this.deviceName,
    required this.platform,
    required this.osVersion,
    this.ipAddress,
  });

  factory AliceDeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$AliceDeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AliceDeviceInfoToJson(this);
}
