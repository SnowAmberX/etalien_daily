// This is a generated file - do not edit.
//
// Generated from apiv2.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use pcAdConfigRequestDescriptor instead')
const PcAdConfigRequest$json = {
  '1': 'PcAdConfigRequest',
};

/// Descriptor for `PcAdConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pcAdConfigRequestDescriptor =
    $convert.base64Decode('ChFQY0FkQ29uZmlnUmVxdWVzdA==');

@$core.Deprecated('Use pcAdConfigItemDescriptor instead')
const PcAdConfigItem$json = {
  '1': 'PcAdConfigItem',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'award_unix', '3': 2, '4': 1, '5': 3, '10': 'awardUnix'},
    {'1': 'level', '3': 3, '4': 1, '5': 3, '10': 'level'},
    {'1': 'is_watch', '3': 4, '4': 1, '5': 8, '10': 'isWatch'},
    {'1': 'title', '3': 5, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `PcAdConfigItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pcAdConfigItemDescriptor = $convert.base64Decode(
    'Cg5QY0FkQ29uZmlnSXRlbRIOCgJpZBgBIAEoA1ICaWQSHQoKYXdhcmRfdW5peBgCIAEoA1IJYX'
    'dhcmRVbml4EhQKBWxldmVsGAMgASgDUgVsZXZlbBIZCghpc193YXRjaBgEIAEoCFIHaXNXYXRj'
    'aBIUCgV0aXRsZRgFIAEoCVIFdGl0bGU=');

@$core.Deprecated('Use pcAdConfigLevelItemDescriptor instead')
const PcAdConfigLevelItem$json = {
  '1': 'PcAdConfigLevelItem',
  '2': [
    {'1': 'level', '3': 1, '4': 1, '5': 3, '10': 'level'},
    {
      '1': 'list',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.apiv2.PcAdConfigItem',
      '10': 'list'
    },
    {'1': 'watch_cnt', '3': 3, '4': 1, '5': 3, '10': 'watchCnt'},
    {'1': 'text', '3': 4, '4': 1, '5': 9, '10': 'text'},
    {'1': 'tag', '3': 5, '4': 1, '5': 9, '10': 'tag'},
    {'1': 'title', '3': 6, '4': 1, '5': 9, '10': 'title'},
  ],
};

/// Descriptor for `PcAdConfigLevelItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pcAdConfigLevelItemDescriptor = $convert.base64Decode(
    'ChNQY0FkQ29uZmlnTGV2ZWxJdGVtEhQKBWxldmVsGAEgASgDUgVsZXZlbBIpCgRsaXN0GAIgAy'
    'gLMhUuYXBpdjIuUGNBZENvbmZpZ0l0ZW1SBGxpc3QSGwoJd2F0Y2hfY250GAMgASgDUgh3YXRj'
    'aENudBISCgR0ZXh0GAQgASgJUgR0ZXh0EhAKA3RhZxgFIAEoCVIDdGFnEhQKBXRpdGxlGAYgAS'
    'gJUgV0aXRsZQ==');

@$core.Deprecated('Use pcAdConfigResponseDescriptor instead')
const PcAdConfigResponse$json = {
  '1': 'PcAdConfigResponse',
  '2': [
    {
      '1': 'list',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.apiv2.PcAdConfigLevelItem',
      '10': 'list'
    },
  ],
};

/// Descriptor for `PcAdConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pcAdConfigResponseDescriptor = $convert.base64Decode(
    'ChJQY0FkQ29uZmlnUmVzcG9uc2USLgoEbGlzdBgBIAMoCzIaLmFwaXYyLlBjQWRDb25maWdMZX'
    'ZlbEl0ZW1SBGxpc3Q=');

@$core.Deprecated('Use pcAdCallbackBackupRequestDescriptor instead')
const PcAdCallbackBackupRequest$json = {
  '1': 'PcAdCallbackBackupRequest',
  '2': [
    {'1': 'ad_id', '3': 1, '4': 1, '5': 9, '10': 'adId'},
    {'1': 'business', '3': 2, '4': 1, '5': 3, '10': 'business'},
  ],
};

/// Descriptor for `PcAdCallbackBackupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pcAdCallbackBackupRequestDescriptor =
    $convert.base64Decode(
        'ChlQY0FkQ2FsbGJhY2tCYWNrdXBSZXF1ZXN0EhMKBWFkX2lkGAEgASgJUgRhZElkEhoKCGJ1c2'
        'luZXNzGAIgASgDUghidXNpbmVzcw==');

@$core.Deprecated('Use pcAdCallbackBackupResponseDescriptor instead')
const PcAdCallbackBackupResponse$json = {
  '1': 'PcAdCallbackBackupResponse',
  '2': [
    {'1': 'is_verify', '3': 1, '4': 1, '5': 8, '10': 'isVerify'},
  ],
};

/// Descriptor for `PcAdCallbackBackupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pcAdCallbackBackupResponseDescriptor =
    $convert.base64Decode(
        'ChpQY0FkQ2FsbGJhY2tCYWNrdXBSZXNwb25zZRIbCglpc192ZXJpZnkYASABKAhSCGlzVmVyaW'
        'Z5');

@$core.Deprecated('Use getUserRemainDurationRequestDescriptor instead')
const GetUserRemainDurationRequest$json = {
  '1': 'GetUserRemainDurationRequest',
};

/// Descriptor for `GetUserRemainDurationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUserRemainDurationRequestDescriptor =
    $convert.base64Decode('ChxHZXRVc2VyUmVtYWluRHVyYXRpb25SZXF1ZXN0');

@$core.Deprecated('Use getUserRemainDurationResponseDescriptor instead')
const GetUserRemainDurationResponse$json = {
  '1': 'GetUserRemainDurationResponse',
  '2': [
    {
      '1': 'vip_duration_second',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'vipDurationSecond'
    },
    {
      '1': 'free_duration_second',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'freeDurationSecond'
    },
    {'1': 'timestamp', '3': 3, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'pause_state', '3': 4, '4': 1, '5': 3, '10': 'pauseState'},
    {'1': 'is_first_award', '3': 5, '4': 1, '5': 8, '10': 'isFirstAward'},
    {'1': 'pc_vip_state', '3': 7, '4': 1, '5': 3, '10': 'pcVipState'},
  ],
};

/// Descriptor for `GetUserRemainDurationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getUserRemainDurationResponseDescriptor = $convert.base64Decode(
    'Ch1HZXRVc2VyUmVtYWluRHVyYXRpb25SZXNwb25zZRIuChN2aXBfZHVyYXRpb25fc2Vjb25kGA'
    'EgASgDUhF2aXBEdXJhdGlvblNlY29uZBIwChRmcmVlX2R1cmF0aW9uX3NlY29uZBgCIAEoA1IS'
    'ZnJlZUR1cmF0aW9uU2Vjb25kEhwKCXRpbWVzdGFtcBgDIAEoA1IJdGltZXN0YW1wEh8KC3BhdX'
    'NlX3N0YXRlGAQgASgDUgpwYXVzZVN0YXRlEiQKDmlzX2ZpcnN0X2F3YXJkGAUgASgIUgxpc0Zp'
    'cnN0QXdhcmQSIAoMcGNfdmlwX3N0YXRlGAcgASgDUgpwY1ZpcFN0YXRl');

@$core.Deprecated('Use updatePauseStateRequestDescriptor instead')
const UpdatePauseStateRequest$json = {
  '1': 'UpdatePauseStateRequest',
  '2': [
    {'1': 'pause_state', '3': 1, '4': 1, '5': 3, '10': 'pauseState'},
  ],
};

/// Descriptor for `UpdatePauseStateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePauseStateRequestDescriptor =
    $convert.base64Decode(
        'ChdVcGRhdGVQYXVzZVN0YXRlUmVxdWVzdBIfCgtwYXVzZV9zdGF0ZRgBIAEoA1IKcGF1c2VTdG'
        'F0ZQ==');

@$core.Deprecated('Use updatePauseStateResponseDescriptor instead')
const UpdatePauseStateResponse$json = {
  '1': 'UpdatePauseStateResponse',
};

/// Descriptor for `UpdatePauseStateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePauseStateResponseDescriptor =
    $convert.base64Decode('ChhVcGRhdGVQYXVzZVN0YXRlUmVzcG9uc2U=');

@$core.Deprecated('Use mobilePcProductListRequestDescriptor instead')
const MobilePcProductListRequest$json = {
  '1': 'MobilePcProductListRequest',
};

/// Descriptor for `MobilePcProductListRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mobilePcProductListRequestDescriptor =
    $convert.base64Decode('ChpNb2JpbGVQY1Byb2R1Y3RMaXN0UmVxdWVzdA==');

@$core.Deprecated('Use mobilePcProductItemDescriptor instead')
const MobilePcProductItem$json = {
  '1': 'MobilePcProductItem',
};

/// Descriptor for `MobilePcProductItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mobilePcProductItemDescriptor =
    $convert.base64Decode('ChNNb2JpbGVQY1Byb2R1Y3RJdGVt');

@$core.Deprecated('Use mobilePcProductListResponseDescriptor instead')
const MobilePcProductListResponse$json = {
  '1': 'MobilePcProductListResponse',
  '2': [
    {
      '1': 'list',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.apiv2.MobilePcProductItem',
      '10': 'list'
    },
  ],
};

/// Descriptor for `MobilePcProductListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mobilePcProductListResponseDescriptor =
    $convert.base64Decode(
        'ChtNb2JpbGVQY1Byb2R1Y3RMaXN0UmVzcG9uc2USLgoEbGlzdBgBIAMoCzIaLmFwaXYyLk1vYm'
        'lsZVBjUHJvZHVjdEl0ZW1SBGxpc3Q=');

@$core.Deprecated('Use adActivityRequestDescriptor instead')
const AdActivityRequest$json = {
  '1': 'AdActivityRequest',
};

/// Descriptor for `AdActivityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adActivityRequestDescriptor =
    $convert.base64Decode('ChFBZEFjdGl2aXR5UmVxdWVzdA==');

@$core.Deprecated('Use adActivityItemDescriptor instead')
const AdActivityItem$json = {
  '1': 'AdActivityItem',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'has_award', '3': 2, '4': 1, '5': 8, '10': 'hasAward'},
    {'1': 'award', '3': 3, '4': 1, '5': 3, '10': 'award'},
    {'1': 'is_get', '3': 4, '4': 1, '5': 8, '10': 'isGet'},
  ],
};

/// Descriptor for `AdActivityItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adActivityItemDescriptor = $convert.base64Decode(
    'Cg5BZEFjdGl2aXR5SXRlbRIOCgJpZBgBIAEoA1ICaWQSGwoJaGFzX2F3YXJkGAIgASgIUghoYX'
    'NBd2FyZBIUCgVhd2FyZBgDIAEoA1IFYXdhcmQSFQoGaXNfZ2V0GAQgASgIUgVpc0dldA==');

@$core.Deprecated('Use adActivityResponseDescriptor instead')
const AdActivityResponse$json = {
  '1': 'AdActivityResponse',
  '2': [
    {'1': 'user_watch_cnt', '3': 1, '4': 1, '5': 3, '10': 'userWatchCnt'},
    {'1': 'video_cnt', '3': 2, '4': 1, '5': 3, '10': 'videoCnt'},
    {
      '1': 'video_bar',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.apiv2.AdActivityItem',
      '10': 'videoBar'
    },
    {'1': 'activity_status', '3': 4, '4': 1, '5': 3, '10': 'activityStatus'},
  ],
};

/// Descriptor for `AdActivityResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adActivityResponseDescriptor = $convert.base64Decode(
    'ChJBZEFjdGl2aXR5UmVzcG9uc2USJAoOdXNlcl93YXRjaF9jbnQYASABKANSDHVzZXJXYXRjaE'
    'NudBIbCgl2aWRlb19jbnQYAiABKANSCHZpZGVvQ250EjIKCXZpZGVvX2JhchgDIAMoCzIVLmFw'
    'aXYyLkFkQWN0aXZpdHlJdGVtUgh2aWRlb0JhchInCg9hY3Rpdml0eV9zdGF0dXMYBCABKANSDm'
    'FjdGl2aXR5U3RhdHVz');

@$core.Deprecated('Use translateProductResponseDescriptor instead')
const TranslateProductResponse$json = {
  '1': 'TranslateProductResponse',
  '2': [
    {'1': 'expire_time', '3': 1, '4': 1, '5': 3, '10': 'expireTime'},
  ],
};

/// Descriptor for `TranslateProductResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List translateProductResponseDescriptor =
    $convert.base64Decode(
        'ChhUcmFuc2xhdGVQcm9kdWN0UmVzcG9uc2USHwoLZXhwaXJlX3RpbWUYASABKANSCmV4cGlyZV'
        'RpbWU=');
