// This is a generated file - do not edit.
//
// Generated from account.proto.

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

@$core.Deprecated('Use getLoginVerificationCodeRequestDescriptor instead')
const GetLoginVerificationCodeRequest$json = {
  '1': 'GetLoginVerificationCodeRequest',
  '2': [
    {'1': 'phone_number', '3': 1, '4': 1, '5': 9, '10': 'phoneNumber'},
  ],
};

/// Descriptor for `GetLoginVerificationCodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLoginVerificationCodeRequestDescriptor =
    $convert.base64Decode(
        'Ch9HZXRMb2dpblZlcmlmaWNhdGlvbkNvZGVSZXF1ZXN0EiEKDHBob25lX251bWJlchgBIAEoCV'
        'ILcGhvbmVOdW1iZXI=');

@$core.Deprecated('Use getLoginVerificationCodeResponseDescriptor instead')
const GetLoginVerificationCodeResponse$json = {
  '1': 'GetLoginVerificationCodeResponse',
};

/// Descriptor for `GetLoginVerificationCodeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLoginVerificationCodeResponseDescriptor =
    $convert.base64Decode('CiBHZXRMb2dpblZlcmlmaWNhdGlvbkNvZGVSZXNwb25zZQ==');

@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = {
  '1': 'LoginRequest',
  '2': [
    {'1': 'phone_number', '3': 1, '4': 1, '5': 9, '10': 'phoneNumber'},
    {
      '1': 'verification_code',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'verificationCode'
    },
    {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
    {'1': 'channel', '3': 4, '4': 1, '5': 9, '10': 'channel'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode(
    'CgxMb2dpblJlcXVlc3QSIQoMcGhvbmVfbnVtYmVyGAEgASgJUgtwaG9uZU51bWJlchIrChF2ZX'
    'JpZmljYXRpb25fY29kZRgCIAEoCVIQdmVyaWZpY2F0aW9uQ29kZRIaCghwYXNzd29yZBgDIAEo'
    'CVIIcGFzc3dvcmQSGAoHY2hhbm5lbBgEIAEoCVIHY2hhbm5lbA==');

@$core.Deprecated('Use loginResponseDescriptor instead')
const LoginResponse$json = {
  '1': 'LoginResponse',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'authorization', '3': 2, '4': 1, '5': 9, '10': 'authorization'},
  ],
};

/// Descriptor for `LoginResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginResponseDescriptor = $convert.base64Decode(
    'Cg1Mb2dpblJlc3BvbnNlEhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBIkCg1hdXRob3JpemF0aW'
    '9uGAIgASgJUg1hdXRob3JpemF0aW9u');

@$core.Deprecated('Use loginV2RequestDescriptor instead')
const LoginV2Request$json = {
  '1': 'LoginV2Request',
  '2': [
    {'1': 'phone_number', '3': 1, '4': 1, '5': 9, '10': 'phoneNumber'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `LoginV2Request`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginV2RequestDescriptor = $convert.base64Decode(
    'Cg5Mb2dpblYyUmVxdWVzdBIhCgxwaG9uZV9udW1iZXIYASABKAlSC3Bob25lTnVtYmVyEhoKCH'
    'Bhc3N3b3JkGAIgASgJUghwYXNzd29yZA==');

@$core.Deprecated('Use loginV2ResponseDescriptor instead')
const LoginV2Response$json = {
  '1': 'LoginV2Response',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'authorization', '3': 2, '4': 1, '5': 9, '10': 'authorization'},
  ],
};

/// Descriptor for `LoginV2Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginV2ResponseDescriptor = $convert.base64Decode(
    'Cg9Mb2dpblYyUmVzcG9uc2USFwoHdXNlcl9pZBgBIAEoA1IGdXNlcklkEiQKDWF1dGhvcml6YX'
    'Rpb24YAiABKAlSDWF1dGhvcml6YXRpb24=');

@$core.Deprecated('Use loginByOneClickRequestDescriptor instead')
const LoginByOneClickRequest$json = {
  '1': 'LoginByOneClickRequest',
};

/// Descriptor for `LoginByOneClickRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginByOneClickRequestDescriptor =
    $convert.base64Decode('ChZMb2dpbkJ5T25lQ2xpY2tSZXF1ZXN0');

@$core.Deprecated('Use loginByOneClickResponseDescriptor instead')
const LoginByOneClickResponse$json = {
  '1': 'LoginByOneClickResponse',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'authorization', '3': 2, '4': 1, '5': 9, '10': 'authorization'},
  ],
};

/// Descriptor for `LoginByOneClickResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginByOneClickResponseDescriptor =
    $convert.base64Decode(
        'ChdMb2dpbkJ5T25lQ2xpY2tSZXNwb25zZRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSJAoNYX'
        'V0aG9yaXphdGlvbhgCIAEoCVINYXV0aG9yaXphdGlvbg==');

@$core.Deprecated('Use myProfileResponseDescriptor instead')
const MyProfileResponse$json = {
  '1': 'MyProfileResponse',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'nickname', '3': 2, '4': 1, '5': 9, '10': 'nickname'},
    {'1': 'avatar', '3': 3, '4': 1, '5': 9, '10': 'avatar'},
    {'1': 'steamid', '3': 4, '4': 1, '5': 9, '10': 'steamid'},
    {'1': 'register_time', '3': 5, '4': 1, '5': 3, '10': 'registerTime'},
    {
      '1': 'members',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.account.Member',
      '10': 'members'
    },
    {
      '1': 'member',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.account.Member',
      '10': 'member'
    },
    {
      '1': 'video_award',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.account.UserVideoAward',
      '10': 'videoAward'
    },
    {
      '1': 'mobile_not_get_ad_duration',
      '3': 9,
      '4': 1,
      '5': 3,
      '10': 'mobileNotGetAdDuration'
    },
  ],
};

/// Descriptor for `MyProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List myProfileResponseDescriptor = $convert.base64Decode(
    'ChFNeVByb2ZpbGVSZXNwb25zZRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSGgoIbmlja25hbW'
    'UYAiABKAlSCG5pY2tuYW1lEhYKBmF2YXRhchgDIAEoCVIGYXZhdGFyEhgKB3N0ZWFtaWQYBCAB'
    'KAlSB3N0ZWFtaWQSIwoNcmVnaXN0ZXJfdGltZRgFIAEoA1IMcmVnaXN0ZXJUaW1lEikKB21lbW'
    'JlcnMYBiADKAsyDy5hY2NvdW50Lk1lbWJlclIHbWVtYmVycxInCgZtZW1iZXIYByABKAsyDy5h'
    'Y2NvdW50Lk1lbWJlclIGbWVtYmVyEjgKC3ZpZGVvX2F3YXJkGAggASgLMhcuYWNjb3VudC5Vc2'
    'VyVmlkZW9Bd2FyZFIKdmlkZW9Bd2FyZBI6Chptb2JpbGVfbm90X2dldF9hZF9kdXJhdGlvbhgJ'
    'IAEoA1IWbW9iaWxlTm90R2V0QWREdXJhdGlvbg==');

@$core.Deprecated('Use memberDescriptor instead')
const Member$json = {
  '1': 'Member',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 3, '10': 'type'},
    {'1': 'expire_time', '3': 2, '4': 1, '5': 3, '10': 'expireTime'},
  ],
};

/// Descriptor for `Member`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List memberDescriptor = $convert.base64Decode(
    'CgZNZW1iZXISEgoEdHlwZRgBIAEoA1IEdHlwZRIfCgtleHBpcmVfdGltZRgCIAEoA1IKZXhwaX'
    'JlVGltZQ==');

@$core.Deprecated('Use userVideoAwardDescriptor instead')
const UserVideoAward$json = {
  '1': 'UserVideoAward',
  '2': [
    {'1': 'award', '3': 1, '4': 1, '5': 3, '10': 'award'},
    {'1': 'has', '3': 2, '4': 1, '5': 8, '10': 'has'},
  ],
};

/// Descriptor for `UserVideoAward`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userVideoAwardDescriptor = $convert.base64Decode(
    'Cg5Vc2VyVmlkZW9Bd2FyZBIUCgVhd2FyZBgBIAEoA1IFYXdhcmQSEAoDaGFzGAIgASgIUgNoYX'
    'M=');

@$core.Deprecated('Use refreshTokenRequestDescriptor instead')
const RefreshTokenRequest$json = {
  '1': 'RefreshTokenRequest',
};

/// Descriptor for `RefreshTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshTokenRequestDescriptor =
    $convert.base64Decode('ChNSZWZyZXNoVG9rZW5SZXF1ZXN0');

@$core.Deprecated('Use refreshTokenResponseDescriptor instead')
const RefreshTokenResponse$json = {
  '1': 'RefreshTokenResponse',
  '2': [
    {'1': 'authorization', '3': 1, '4': 1, '5': 9, '10': 'authorization'},
  ],
};

/// Descriptor for `RefreshTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshTokenResponseDescriptor = $convert.base64Decode(
    'ChRSZWZyZXNoVG9rZW5SZXNwb25zZRIkCg1hdXRob3JpemF0aW9uGAEgASgJUg1hdXRob3Jpem'
    'F0aW9u');
