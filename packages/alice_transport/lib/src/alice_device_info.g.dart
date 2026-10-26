// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alice_device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AliceDeviceInfo _$AliceDeviceInfoFromJson(Map<String, dynamic> json) =>
    AliceDeviceInfo(
      appName: json['appName'] as String,
      deviceName: json['deviceName'] as String,
      platform: json['platform'] as String,
      osVersion: json['osVersion'] as String,
      ipAddress: json['ipAddress'] as String?,
    );

Map<String, dynamic> _$AliceDeviceInfoToJson(AliceDeviceInfo instance) =>
    <String, dynamic>{
      'appName': instance.appName,
      'deviceName': instance.deviceName,
      'platform': instance.platform,
      'osVersion': instance.osVersion,
      'ipAddress': instance.ipAddress,
    };
