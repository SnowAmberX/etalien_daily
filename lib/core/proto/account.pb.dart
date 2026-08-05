// This is a generated file - do not edit.
//
// Generated from account.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// 获取登录验证码请求
/// POST /account/v1/get_login_verification_code
class GetLoginVerificationCodeRequest extends $pb.GeneratedMessage {
  factory GetLoginVerificationCodeRequest({
    $core.String? phoneNumber,
  }) {
    final result = create();
    if (phoneNumber != null) result.phoneNumber = phoneNumber;
    return result;
  }

  GetLoginVerificationCodeRequest._();

  factory GetLoginVerificationCodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetLoginVerificationCodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLoginVerificationCodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'phoneNumber')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLoginVerificationCodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLoginVerificationCodeRequest copyWith(
          void Function(GetLoginVerificationCodeRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetLoginVerificationCodeRequest))
          as GetLoginVerificationCodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLoginVerificationCodeRequest create() =>
      GetLoginVerificationCodeRequest._();
  @$core.override
  GetLoginVerificationCodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetLoginVerificationCodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLoginVerificationCodeRequest>(
          create);
  static GetLoginVerificationCodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get phoneNumber => $_getSZ(0);
  @$pb.TagNumber(1)
  set phoneNumber($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPhoneNumber() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhoneNumber() => $_clearField(1);
}

class GetLoginVerificationCodeResponse extends $pb.GeneratedMessage {
  factory GetLoginVerificationCodeResponse() => create();

  GetLoginVerificationCodeResponse._();

  factory GetLoginVerificationCodeResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetLoginVerificationCodeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLoginVerificationCodeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLoginVerificationCodeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLoginVerificationCodeResponse copyWith(
          void Function(GetLoginVerificationCodeResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetLoginVerificationCodeResponse))
          as GetLoginVerificationCodeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLoginVerificationCodeResponse create() =>
      GetLoginVerificationCodeResponse._();
  @$core.override
  GetLoginVerificationCodeResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetLoginVerificationCodeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLoginVerificationCodeResponse>(
          create);
  static GetLoginVerificationCodeResponse? _defaultInstance;
}

/// 验证码登录请求
/// POST /account/v1/login
class LoginRequest extends $pb.GeneratedMessage {
  factory LoginRequest({
    $core.String? phoneNumber,
    $core.String? verificationCode,
    $core.String? password,
    $core.String? channel,
  }) {
    final result = create();
    if (phoneNumber != null) result.phoneNumber = phoneNumber;
    if (verificationCode != null) result.verificationCode = verificationCode;
    if (password != null) result.password = password;
    if (channel != null) result.channel = channel;
    return result;
  }

  LoginRequest._();

  factory LoginRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoginRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'phoneNumber')
    ..aOS(2, _omitFieldNames ? '' : 'verificationCode')
    ..aOS(3, _omitFieldNames ? '' : 'password')
    ..aOS(4, _omitFieldNames ? '' : 'channel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest copyWith(void Function(LoginRequest) updates) =>
      super.copyWith((message) => updates(message as LoginRequest))
          as LoginRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginRequest create() => LoginRequest._();
  @$core.override
  LoginRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoginRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginRequest>(create);
  static LoginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get phoneNumber => $_getSZ(0);
  @$pb.TagNumber(1)
  set phoneNumber($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPhoneNumber() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhoneNumber() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get verificationCode => $_getSZ(1);
  @$pb.TagNumber(2)
  set verificationCode($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVerificationCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearVerificationCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get channel => $_getSZ(3);
  @$pb.TagNumber(4)
  set channel($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChannel() => $_has(3);
  @$pb.TagNumber(4)
  void clearChannel() => $_clearField(4);
}

class LoginResponse extends $pb.GeneratedMessage {
  factory LoginResponse({
    $fixnum.Int64? userId,
    $core.String? authorization,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (authorization != null) result.authorization = authorization;
    return result;
  }

  LoginResponse._();

  factory LoginResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoginResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'authorization')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse copyWith(void Function(LoginResponse) updates) =>
      super.copyWith((message) => updates(message as LoginResponse))
          as LoginResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginResponse create() => LoginResponse._();
  @$core.override
  LoginResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoginResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginResponse>(create);
  static LoginResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get authorization => $_getSZ(1);
  @$pb.TagNumber(2)
  set authorization($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuthorization() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthorization() => $_clearField(2);
}

/// 密码登录请求
/// POST /v2/account/login
class LoginV2Request extends $pb.GeneratedMessage {
  factory LoginV2Request({
    $core.String? phoneNumber,
    $core.String? password,
  }) {
    final result = create();
    if (phoneNumber != null) result.phoneNumber = phoneNumber;
    if (password != null) result.password = password;
    return result;
  }

  LoginV2Request._();

  factory LoginV2Request.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoginV2Request.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginV2Request',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'phoneNumber')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginV2Request clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginV2Request copyWith(void Function(LoginV2Request) updates) =>
      super.copyWith((message) => updates(message as LoginV2Request))
          as LoginV2Request;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginV2Request create() => LoginV2Request._();
  @$core.override
  LoginV2Request createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoginV2Request getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginV2Request>(create);
  static LoginV2Request? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get phoneNumber => $_getSZ(0);
  @$pb.TagNumber(1)
  set phoneNumber($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPhoneNumber() => $_has(0);
  @$pb.TagNumber(1)
  void clearPhoneNumber() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);
}

class LoginV2Response extends $pb.GeneratedMessage {
  factory LoginV2Response({
    $fixnum.Int64? userId,
    $core.String? authorization,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (authorization != null) result.authorization = authorization;
    return result;
  }

  LoginV2Response._();

  factory LoginV2Response.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoginV2Response.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginV2Response',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'authorization')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginV2Response clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginV2Response copyWith(void Function(LoginV2Response) updates) =>
      super.copyWith((message) => updates(message as LoginV2Response))
          as LoginV2Response;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginV2Response create() => LoginV2Response._();
  @$core.override
  LoginV2Response createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoginV2Response getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginV2Response>(create);
  static LoginV2Response? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get authorization => $_getSZ(1);
  @$pb.TagNumber(2)
  set authorization($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuthorization() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthorization() => $_clearField(2);
}

/// 一键登录请求
/// POST /account/v1/login/by-one-click
class LoginByOneClickRequest extends $pb.GeneratedMessage {
  factory LoginByOneClickRequest() => create();

  LoginByOneClickRequest._();

  factory LoginByOneClickRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoginByOneClickRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginByOneClickRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginByOneClickRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginByOneClickRequest copyWith(
          void Function(LoginByOneClickRequest) updates) =>
      super.copyWith((message) => updates(message as LoginByOneClickRequest))
          as LoginByOneClickRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginByOneClickRequest create() => LoginByOneClickRequest._();
  @$core.override
  LoginByOneClickRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoginByOneClickRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginByOneClickRequest>(create);
  static LoginByOneClickRequest? _defaultInstance;
}

class LoginByOneClickResponse extends $pb.GeneratedMessage {
  factory LoginByOneClickResponse({
    $fixnum.Int64? userId,
    $core.String? authorization,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (authorization != null) result.authorization = authorization;
    return result;
  }

  LoginByOneClickResponse._();

  factory LoginByOneClickResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoginByOneClickResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginByOneClickResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'authorization')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginByOneClickResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginByOneClickResponse copyWith(
          void Function(LoginByOneClickResponse) updates) =>
      super.copyWith((message) => updates(message as LoginByOneClickResponse))
          as LoginByOneClickResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginByOneClickResponse create() => LoginByOneClickResponse._();
  @$core.override
  LoginByOneClickResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoginByOneClickResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginByOneClickResponse>(create);
  static LoginByOneClickResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get authorization => $_getSZ(1);
  @$pb.TagNumber(2)
  set authorization($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuthorization() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthorization() => $_clearField(2);
}

/// 获取用户信息
/// GET /account/v1/my_profile
class MyProfileResponse extends $pb.GeneratedMessage {
  factory MyProfileResponse({
    $fixnum.Int64? userId,
    $core.String? nickname,
    $core.String? avatar,
    $core.String? steamid,
    $fixnum.Int64? registerTime,
    $core.Iterable<Member>? members,
    Member? member,
    UserVideoAward? videoAward,
    $fixnum.Int64? mobileNotGetAdDuration,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (nickname != null) result.nickname = nickname;
    if (avatar != null) result.avatar = avatar;
    if (steamid != null) result.steamid = steamid;
    if (registerTime != null) result.registerTime = registerTime;
    if (members != null) result.members.addAll(members);
    if (member != null) result.member = member;
    if (videoAward != null) result.videoAward = videoAward;
    if (mobileNotGetAdDuration != null)
      result.mobileNotGetAdDuration = mobileNotGetAdDuration;
    return result;
  }

  MyProfileResponse._();

  factory MyProfileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MyProfileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MyProfileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'nickname')
    ..aOS(3, _omitFieldNames ? '' : 'avatar')
    ..aOS(4, _omitFieldNames ? '' : 'steamid')
    ..aInt64(5, _omitFieldNames ? '' : 'registerTime')
    ..pPM<Member>(6, _omitFieldNames ? '' : 'members',
        subBuilder: Member.create)
    ..aOM<Member>(7, _omitFieldNames ? '' : 'member', subBuilder: Member.create)
    ..aOM<UserVideoAward>(8, _omitFieldNames ? '' : 'videoAward',
        subBuilder: UserVideoAward.create)
    ..aInt64(9, _omitFieldNames ? '' : 'mobileNotGetAdDuration')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MyProfileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MyProfileResponse copyWith(void Function(MyProfileResponse) updates) =>
      super.copyWith((message) => updates(message as MyProfileResponse))
          as MyProfileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MyProfileResponse create() => MyProfileResponse._();
  @$core.override
  MyProfileResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MyProfileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MyProfileResponse>(create);
  static MyProfileResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get nickname => $_getSZ(1);
  @$pb.TagNumber(2)
  set nickname($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNickname() => $_has(1);
  @$pb.TagNumber(2)
  void clearNickname() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get avatar => $_getSZ(2);
  @$pb.TagNumber(3)
  set avatar($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatar() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatar() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get steamid => $_getSZ(3);
  @$pb.TagNumber(4)
  set steamid($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSteamid() => $_has(3);
  @$pb.TagNumber(4)
  void clearSteamid() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get registerTime => $_getI64(4);
  @$pb.TagNumber(5)
  set registerTime($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRegisterTime() => $_has(4);
  @$pb.TagNumber(5)
  void clearRegisterTime() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<Member> get members => $_getList(5);

  @$pb.TagNumber(7)
  Member get member => $_getN(6);
  @$pb.TagNumber(7)
  set member(Member value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasMember() => $_has(6);
  @$pb.TagNumber(7)
  void clearMember() => $_clearField(7);
  @$pb.TagNumber(7)
  Member ensureMember() => $_ensure(6);

  @$pb.TagNumber(8)
  UserVideoAward get videoAward => $_getN(7);
  @$pb.TagNumber(8)
  set videoAward(UserVideoAward value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasVideoAward() => $_has(7);
  @$pb.TagNumber(8)
  void clearVideoAward() => $_clearField(8);
  @$pb.TagNumber(8)
  UserVideoAward ensureVideoAward() => $_ensure(7);

  @$pb.TagNumber(9)
  $fixnum.Int64 get mobileNotGetAdDuration => $_getI64(8);
  @$pb.TagNumber(9)
  set mobileNotGetAdDuration($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMobileNotGetAdDuration() => $_has(8);
  @$pb.TagNumber(9)
  void clearMobileNotGetAdDuration() => $_clearField(9);
}

/// 会员信息
class Member extends $pb.GeneratedMessage {
  factory Member({
    $fixnum.Int64? type,
    $fixnum.Int64? expireTime,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (expireTime != null) result.expireTime = expireTime;
    return result;
  }

  Member._();

  factory Member.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Member.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Member',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'type')
    ..aInt64(2, _omitFieldNames ? '' : 'expireTime')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Member clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Member copyWith(void Function(Member) updates) =>
      super.copyWith((message) => updates(message as Member)) as Member;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Member create() => Member._();
  @$core.override
  Member createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Member getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Member>(create);
  static Member? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get type => $_getI64(0);
  @$pb.TagNumber(1)
  set type($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get expireTime => $_getI64(1);
  @$pb.TagNumber(2)
  set expireTime($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExpireTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpireTime() => $_clearField(2);
}

/// 视频奖励信息
class UserVideoAward extends $pb.GeneratedMessage {
  factory UserVideoAward({
    $fixnum.Int64? award,
    $core.bool? has,
  }) {
    final result = create();
    if (award != null) result.award = award;
    if (has != null) result.has = has;
    return result;
  }

  UserVideoAward._();

  factory UserVideoAward.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserVideoAward.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserVideoAward',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'award')
    ..aOB(2, _omitFieldNames ? '' : 'has')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserVideoAward clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserVideoAward copyWith(void Function(UserVideoAward) updates) =>
      super.copyWith((message) => updates(message as UserVideoAward))
          as UserVideoAward;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserVideoAward create() => UserVideoAward._();
  @$core.override
  UserVideoAward createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UserVideoAward getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserVideoAward>(create);
  static UserVideoAward? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get award => $_getI64(0);
  @$pb.TagNumber(1)
  set award($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAward() => $_has(0);
  @$pb.TagNumber(1)
  void clearAward() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get has => $_getBF(1);
  @$pb.TagNumber(2)
  set has($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHas() => $_has(1);
  @$pb.TagNumber(2)
  void clearHas() => $_clearField(2);
}

/// 刷新token
/// POST /v2/account/refresh/token
class RefreshTokenRequest extends $pb.GeneratedMessage {
  factory RefreshTokenRequest() => create();

  RefreshTokenRequest._();

  factory RefreshTokenRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshTokenRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshTokenRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshTokenRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshTokenRequest copyWith(void Function(RefreshTokenRequest) updates) =>
      super.copyWith((message) => updates(message as RefreshTokenRequest))
          as RefreshTokenRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshTokenRequest create() => RefreshTokenRequest._();
  @$core.override
  RefreshTokenRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshTokenRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshTokenRequest>(create);
  static RefreshTokenRequest? _defaultInstance;
}

class RefreshTokenResponse extends $pb.GeneratedMessage {
  factory RefreshTokenResponse({
    $core.String? authorization,
  }) {
    final result = create();
    if (authorization != null) result.authorization = authorization;
    return result;
  }

  RefreshTokenResponse._();

  factory RefreshTokenResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RefreshTokenResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshTokenResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'account'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'authorization')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshTokenResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshTokenResponse copyWith(void Function(RefreshTokenResponse) updates) =>
      super.copyWith((message) => updates(message as RefreshTokenResponse))
          as RefreshTokenResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshTokenResponse create() => RefreshTokenResponse._();
  @$core.override
  RefreshTokenResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RefreshTokenResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshTokenResponse>(create);
  static RefreshTokenResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get authorization => $_getSZ(0);
  @$pb.TagNumber(1)
  set authorization($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAuthorization() => $_has(0);
  @$pb.TagNumber(1)
  void clearAuthorization() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
