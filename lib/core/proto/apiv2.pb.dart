// This is a generated file - do not edit.
//
// Generated from apiv2.proto.

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

/// PC广告任务配置
/// POST /v2/account/pc/ad/config
class PcAdConfigRequest extends $pb.GeneratedMessage {
  factory PcAdConfigRequest() => create();

  PcAdConfigRequest._();

  factory PcAdConfigRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PcAdConfigRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PcAdConfigRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdConfigRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdConfigRequest copyWith(void Function(PcAdConfigRequest) updates) =>
      super.copyWith((message) => updates(message as PcAdConfigRequest))
          as PcAdConfigRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PcAdConfigRequest create() => PcAdConfigRequest._();
  @$core.override
  PcAdConfigRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PcAdConfigRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PcAdConfigRequest>(create);
  static PcAdConfigRequest? _defaultInstance;
}

class PcAdConfigItem extends $pb.GeneratedMessage {
  factory PcAdConfigItem({
    $fixnum.Int64? id,
    $fixnum.Int64? awardUnix,
    $fixnum.Int64? level,
    $core.bool? isWatch,
    $core.String? title,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (awardUnix != null) result.awardUnix = awardUnix;
    if (level != null) result.level = level;
    if (isWatch != null) result.isWatch = isWatch;
    if (title != null) result.title = title;
    return result;
  }

  PcAdConfigItem._();

  factory PcAdConfigItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PcAdConfigItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PcAdConfigItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'awardUnix')
    ..aInt64(3, _omitFieldNames ? '' : 'level')
    ..aOB(4, _omitFieldNames ? '' : 'isWatch')
    ..aOS(5, _omitFieldNames ? '' : 'title')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdConfigItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdConfigItem copyWith(void Function(PcAdConfigItem) updates) =>
      super.copyWith((message) => updates(message as PcAdConfigItem))
          as PcAdConfigItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PcAdConfigItem create() => PcAdConfigItem._();
  @$core.override
  PcAdConfigItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PcAdConfigItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PcAdConfigItem>(create);
  static PcAdConfigItem? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get awardUnix => $_getI64(1);
  @$pb.TagNumber(2)
  set awardUnix($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAwardUnix() => $_has(1);
  @$pb.TagNumber(2)
  void clearAwardUnix() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get level => $_getI64(2);
  @$pb.TagNumber(3)
  set level($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLevel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLevel() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isWatch => $_getBF(3);
  @$pb.TagNumber(4)
  set isWatch($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsWatch() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsWatch() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get title => $_getSZ(4);
  @$pb.TagNumber(5)
  set title($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTitle() => $_has(4);
  @$pb.TagNumber(5)
  void clearTitle() => $_clearField(5);
}

class PcAdConfigLevelItem extends $pb.GeneratedMessage {
  factory PcAdConfigLevelItem({
    $fixnum.Int64? level,
    $core.Iterable<PcAdConfigItem>? list,
    $fixnum.Int64? watchCnt,
    $core.String? text,
    $core.String? tag,
    $core.String? title,
  }) {
    final result = create();
    if (level != null) result.level = level;
    if (list != null) result.list.addAll(list);
    if (watchCnt != null) result.watchCnt = watchCnt;
    if (text != null) result.text = text;
    if (tag != null) result.tag = tag;
    if (title != null) result.title = title;
    return result;
  }

  PcAdConfigLevelItem._();

  factory PcAdConfigLevelItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PcAdConfigLevelItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PcAdConfigLevelItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'level')
    ..pPM<PcAdConfigItem>(2, _omitFieldNames ? '' : 'list',
        subBuilder: PcAdConfigItem.create)
    ..aInt64(3, _omitFieldNames ? '' : 'watchCnt')
    ..aOS(4, _omitFieldNames ? '' : 'text')
    ..aOS(5, _omitFieldNames ? '' : 'tag')
    ..aOS(6, _omitFieldNames ? '' : 'title')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdConfigLevelItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdConfigLevelItem copyWith(void Function(PcAdConfigLevelItem) updates) =>
      super.copyWith((message) => updates(message as PcAdConfigLevelItem))
          as PcAdConfigLevelItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PcAdConfigLevelItem create() => PcAdConfigLevelItem._();
  @$core.override
  PcAdConfigLevelItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PcAdConfigLevelItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PcAdConfigLevelItem>(create);
  static PcAdConfigLevelItem? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get level => $_getI64(0);
  @$pb.TagNumber(1)
  set level($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLevel() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<PcAdConfigItem> get list => $_getList(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get watchCnt => $_getI64(2);
  @$pb.TagNumber(3)
  set watchCnt($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWatchCnt() => $_has(2);
  @$pb.TagNumber(3)
  void clearWatchCnt() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get text => $_getSZ(3);
  @$pb.TagNumber(4)
  set text($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasText() => $_has(3);
  @$pb.TagNumber(4)
  void clearText() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get tag => $_getSZ(4);
  @$pb.TagNumber(5)
  set tag($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTag() => $_has(4);
  @$pb.TagNumber(5)
  void clearTag() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get title => $_getSZ(5);
  @$pb.TagNumber(6)
  set title($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTitle() => $_has(5);
  @$pb.TagNumber(6)
  void clearTitle() => $_clearField(6);
}

class PcAdConfigResponse extends $pb.GeneratedMessage {
  factory PcAdConfigResponse({
    $core.Iterable<PcAdConfigLevelItem>? list,
  }) {
    final result = create();
    if (list != null) result.list.addAll(list);
    return result;
  }

  PcAdConfigResponse._();

  factory PcAdConfigResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PcAdConfigResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PcAdConfigResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..pPM<PcAdConfigLevelItem>(1, _omitFieldNames ? '' : 'list',
        subBuilder: PcAdConfigLevelItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdConfigResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdConfigResponse copyWith(void Function(PcAdConfigResponse) updates) =>
      super.copyWith((message) => updates(message as PcAdConfigResponse))
          as PcAdConfigResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PcAdConfigResponse create() => PcAdConfigResponse._();
  @$core.override
  PcAdConfigResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PcAdConfigResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PcAdConfigResponse>(create);
  static PcAdConfigResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<PcAdConfigLevelItem> get list => $_getList(0);
}

/// PC广告奖励补发
/// POST /v2/account/pc/ad/callback/backup
class PcAdCallbackBackupRequest extends $pb.GeneratedMessage {
  factory PcAdCallbackBackupRequest({
    $core.String? adId,
    $fixnum.Int64? business,
  }) {
    final result = create();
    if (adId != null) result.adId = adId;
    if (business != null) result.business = business;
    return result;
  }

  PcAdCallbackBackupRequest._();

  factory PcAdCallbackBackupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PcAdCallbackBackupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PcAdCallbackBackupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'adId')
    ..aInt64(2, _omitFieldNames ? '' : 'business')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdCallbackBackupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdCallbackBackupRequest copyWith(
          void Function(PcAdCallbackBackupRequest) updates) =>
      super.copyWith((message) => updates(message as PcAdCallbackBackupRequest))
          as PcAdCallbackBackupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PcAdCallbackBackupRequest create() => PcAdCallbackBackupRequest._();
  @$core.override
  PcAdCallbackBackupRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PcAdCallbackBackupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PcAdCallbackBackupRequest>(create);
  static PcAdCallbackBackupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get adId => $_getSZ(0);
  @$pb.TagNumber(1)
  set adId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAdId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAdId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get business => $_getI64(1);
  @$pb.TagNumber(2)
  set business($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBusiness() => $_has(1);
  @$pb.TagNumber(2)
  void clearBusiness() => $_clearField(2);
}

class PcAdCallbackBackupResponse extends $pb.GeneratedMessage {
  factory PcAdCallbackBackupResponse({
    $core.bool? isVerify,
  }) {
    final result = create();
    if (isVerify != null) result.isVerify = isVerify;
    return result;
  }

  PcAdCallbackBackupResponse._();

  factory PcAdCallbackBackupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PcAdCallbackBackupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PcAdCallbackBackupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'isVerify')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdCallbackBackupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PcAdCallbackBackupResponse copyWith(
          void Function(PcAdCallbackBackupResponse) updates) =>
      super.copyWith(
              (message) => updates(message as PcAdCallbackBackupResponse))
          as PcAdCallbackBackupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PcAdCallbackBackupResponse create() => PcAdCallbackBackupResponse._();
  @$core.override
  PcAdCallbackBackupResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PcAdCallbackBackupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PcAdCallbackBackupResponse>(create);
  static PcAdCallbackBackupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isVerify => $_getBF(0);
  @$pb.TagNumber(1)
  set isVerify($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsVerify() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsVerify() => $_clearField(1);
}

/// PC加速时长
/// POST /v2/account/remain/duration
class GetUserRemainDurationRequest extends $pb.GeneratedMessage {
  factory GetUserRemainDurationRequest() => create();

  GetUserRemainDurationRequest._();

  factory GetUserRemainDurationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetUserRemainDurationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetUserRemainDurationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserRemainDurationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserRemainDurationRequest copyWith(
          void Function(GetUserRemainDurationRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetUserRemainDurationRequest))
          as GetUserRemainDurationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetUserRemainDurationRequest create() =>
      GetUserRemainDurationRequest._();
  @$core.override
  GetUserRemainDurationRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetUserRemainDurationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetUserRemainDurationRequest>(create);
  static GetUserRemainDurationRequest? _defaultInstance;
}

class GetUserRemainDurationResponse extends $pb.GeneratedMessage {
  factory GetUserRemainDurationResponse({
    $fixnum.Int64? vipDurationSecond,
    $fixnum.Int64? freeDurationSecond,
    $fixnum.Int64? timestamp,
    $fixnum.Int64? pauseState,
    $core.bool? isFirstAward,
    $fixnum.Int64? pcVipState,
  }) {
    final result = create();
    if (vipDurationSecond != null) result.vipDurationSecond = vipDurationSecond;
    if (freeDurationSecond != null)
      result.freeDurationSecond = freeDurationSecond;
    if (timestamp != null) result.timestamp = timestamp;
    if (pauseState != null) result.pauseState = pauseState;
    if (isFirstAward != null) result.isFirstAward = isFirstAward;
    if (pcVipState != null) result.pcVipState = pcVipState;
    return result;
  }

  GetUserRemainDurationResponse._();

  factory GetUserRemainDurationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetUserRemainDurationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetUserRemainDurationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'vipDurationSecond')
    ..aInt64(2, _omitFieldNames ? '' : 'freeDurationSecond')
    ..aInt64(3, _omitFieldNames ? '' : 'timestamp')
    ..aInt64(4, _omitFieldNames ? '' : 'pauseState')
    ..aOB(5, _omitFieldNames ? '' : 'isFirstAward')
    ..aInt64(7, _omitFieldNames ? '' : 'pcVipState')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserRemainDurationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserRemainDurationResponse copyWith(
          void Function(GetUserRemainDurationResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetUserRemainDurationResponse))
          as GetUserRemainDurationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetUserRemainDurationResponse create() =>
      GetUserRemainDurationResponse._();
  @$core.override
  GetUserRemainDurationResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetUserRemainDurationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetUserRemainDurationResponse>(create);
  static GetUserRemainDurationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get vipDurationSecond => $_getI64(0);
  @$pb.TagNumber(1)
  set vipDurationSecond($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVipDurationSecond() => $_has(0);
  @$pb.TagNumber(1)
  void clearVipDurationSecond() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get freeDurationSecond => $_getI64(1);
  @$pb.TagNumber(2)
  set freeDurationSecond($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFreeDurationSecond() => $_has(1);
  @$pb.TagNumber(2)
  void clearFreeDurationSecond() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set timestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestamp() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get pauseState => $_getI64(3);
  @$pb.TagNumber(4)
  set pauseState($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPauseState() => $_has(3);
  @$pb.TagNumber(4)
  void clearPauseState() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isFirstAward => $_getBF(4);
  @$pb.TagNumber(5)
  set isFirstAward($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsFirstAward() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsFirstAward() => $_clearField(5);

  @$pb.TagNumber(7)
  $fixnum.Int64 get pcVipState => $_getI64(5);
  @$pb.TagNumber(7)
  set pcVipState($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(7)
  $core.bool hasPcVipState() => $_has(5);
  @$pb.TagNumber(7)
  void clearPcVipState() => $_clearField(7);
}

/// 更新暂停状态
/// POST /v2/account/update/pause/state
class UpdatePauseStateRequest extends $pb.GeneratedMessage {
  factory UpdatePauseStateRequest({
    $fixnum.Int64? pauseState,
  }) {
    final result = create();
    if (pauseState != null) result.pauseState = pauseState;
    return result;
  }

  UpdatePauseStateRequest._();

  factory UpdatePauseStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdatePauseStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdatePauseStateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'pauseState')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePauseStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePauseStateRequest copyWith(
          void Function(UpdatePauseStateRequest) updates) =>
      super.copyWith((message) => updates(message as UpdatePauseStateRequest))
          as UpdatePauseStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdatePauseStateRequest create() => UpdatePauseStateRequest._();
  @$core.override
  UpdatePauseStateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdatePauseStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdatePauseStateRequest>(create);
  static UpdatePauseStateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get pauseState => $_getI64(0);
  @$pb.TagNumber(1)
  set pauseState($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPauseState() => $_has(0);
  @$pb.TagNumber(1)
  void clearPauseState() => $_clearField(1);
}

class UpdatePauseStateResponse extends $pb.GeneratedMessage {
  factory UpdatePauseStateResponse() => create();

  UpdatePauseStateResponse._();

  factory UpdatePauseStateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdatePauseStateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdatePauseStateResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePauseStateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePauseStateResponse copyWith(
          void Function(UpdatePauseStateResponse) updates) =>
      super.copyWith((message) => updates(message as UpdatePauseStateResponse))
          as UpdatePauseStateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdatePauseStateResponse create() => UpdatePauseStateResponse._();
  @$core.override
  UpdatePauseStateResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdatePauseStateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdatePauseStateResponse>(create);
  static UpdatePauseStateResponse? _defaultInstance;
}

/// PC产品列表
/// POST /v2/account/mobile/pc_product/list
class MobilePcProductListRequest extends $pb.GeneratedMessage {
  factory MobilePcProductListRequest() => create();

  MobilePcProductListRequest._();

  factory MobilePcProductListRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MobilePcProductListRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MobilePcProductListRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MobilePcProductListRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MobilePcProductListRequest copyWith(
          void Function(MobilePcProductListRequest) updates) =>
      super.copyWith(
              (message) => updates(message as MobilePcProductListRequest))
          as MobilePcProductListRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MobilePcProductListRequest create() => MobilePcProductListRequest._();
  @$core.override
  MobilePcProductListRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MobilePcProductListRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MobilePcProductListRequest>(create);
  static MobilePcProductListRequest? _defaultInstance;
}

class MobilePcProductItem extends $pb.GeneratedMessage {
  factory MobilePcProductItem() => create();

  MobilePcProductItem._();

  factory MobilePcProductItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MobilePcProductItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MobilePcProductItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MobilePcProductItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MobilePcProductItem copyWith(void Function(MobilePcProductItem) updates) =>
      super.copyWith((message) => updates(message as MobilePcProductItem))
          as MobilePcProductItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MobilePcProductItem create() => MobilePcProductItem._();
  @$core.override
  MobilePcProductItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MobilePcProductItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MobilePcProductItem>(create);
  static MobilePcProductItem? _defaultInstance;
}

class MobilePcProductListResponse extends $pb.GeneratedMessage {
  factory MobilePcProductListResponse({
    $core.Iterable<MobilePcProductItem>? list,
  }) {
    final result = create();
    if (list != null) result.list.addAll(list);
    return result;
  }

  MobilePcProductListResponse._();

  factory MobilePcProductListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MobilePcProductListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MobilePcProductListResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..pPM<MobilePcProductItem>(1, _omitFieldNames ? '' : 'list',
        subBuilder: MobilePcProductItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MobilePcProductListResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MobilePcProductListResponse copyWith(
          void Function(MobilePcProductListResponse) updates) =>
      super.copyWith(
              (message) => updates(message as MobilePcProductListResponse))
          as MobilePcProductListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MobilePcProductListResponse create() =>
      MobilePcProductListResponse._();
  @$core.override
  MobilePcProductListResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MobilePcProductListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MobilePcProductListResponse>(create);
  static MobilePcProductListResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MobilePcProductItem> get list => $_getList(0);
}

/// 手机端广告任务列表
/// GET /award/v1/ad/activity
class AdActivityRequest extends $pb.GeneratedMessage {
  factory AdActivityRequest() => create();

  AdActivityRequest._();

  factory AdActivityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AdActivityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdActivityRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdActivityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdActivityRequest copyWith(void Function(AdActivityRequest) updates) =>
      super.copyWith((message) => updates(message as AdActivityRequest))
          as AdActivityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AdActivityRequest create() => AdActivityRequest._();
  @$core.override
  AdActivityRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AdActivityRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdActivityRequest>(create);
  static AdActivityRequest? _defaultInstance;
}

class AdActivityItem extends $pb.GeneratedMessage {
  factory AdActivityItem({
    $fixnum.Int64? id,
    $core.bool? hasAward,
    $fixnum.Int64? award_3,
    $core.bool? isGet,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (hasAward != null) result.hasAward = hasAward;
    if (award_3 != null) result.award_3 = award_3;
    if (isGet != null) result.isGet = isGet;
    return result;
  }

  AdActivityItem._();

  factory AdActivityItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AdActivityItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdActivityItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOB(2, _omitFieldNames ? '' : 'hasAward')
    ..aInt64(3, _omitFieldNames ? '' : 'award')
    ..aOB(4, _omitFieldNames ? '' : 'isGet')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdActivityItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdActivityItem copyWith(void Function(AdActivityItem) updates) =>
      super.copyWith((message) => updates(message as AdActivityItem))
          as AdActivityItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AdActivityItem create() => AdActivityItem._();
  @$core.override
  AdActivityItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AdActivityItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdActivityItem>(create);
  static AdActivityItem? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get hasAward => $_getBF(1);
  @$pb.TagNumber(2)
  set hasAward($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHasAward() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasAward() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get award_3 => $_getI64(2);
  @$pb.TagNumber(3)
  set award_3($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAward_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearAward_3() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isGet => $_getBF(3);
  @$pb.TagNumber(4)
  set isGet($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsGet() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsGet() => $_clearField(4);
}

class AdActivityResponse extends $pb.GeneratedMessage {
  factory AdActivityResponse({
    $fixnum.Int64? userWatchCnt,
    $fixnum.Int64? videoCnt,
    $core.Iterable<AdActivityItem>? videoBar,
    $fixnum.Int64? activityStatus,
  }) {
    final result = create();
    if (userWatchCnt != null) result.userWatchCnt = userWatchCnt;
    if (videoCnt != null) result.videoCnt = videoCnt;
    if (videoBar != null) result.videoBar.addAll(videoBar);
    if (activityStatus != null) result.activityStatus = activityStatus;
    return result;
  }

  AdActivityResponse._();

  factory AdActivityResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AdActivityResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdActivityResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userWatchCnt')
    ..aInt64(2, _omitFieldNames ? '' : 'videoCnt')
    ..pPM<AdActivityItem>(3, _omitFieldNames ? '' : 'videoBar',
        subBuilder: AdActivityItem.create)
    ..aInt64(4, _omitFieldNames ? '' : 'activityStatus')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdActivityResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdActivityResponse copyWith(void Function(AdActivityResponse) updates) =>
      super.copyWith((message) => updates(message as AdActivityResponse))
          as AdActivityResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AdActivityResponse create() => AdActivityResponse._();
  @$core.override
  AdActivityResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AdActivityResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdActivityResponse>(create);
  static AdActivityResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userWatchCnt => $_getI64(0);
  @$pb.TagNumber(1)
  set userWatchCnt($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserWatchCnt() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserWatchCnt() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get videoCnt => $_getI64(1);
  @$pb.TagNumber(2)
  set videoCnt($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVideoCnt() => $_has(1);
  @$pb.TagNumber(2)
  void clearVideoCnt() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<AdActivityItem> get videoBar => $_getList(2);

  @$pb.TagNumber(4)
  $fixnum.Int64 get activityStatus => $_getI64(3);
  @$pb.TagNumber(4)
  set activityStatus($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasActivityStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearActivityStatus() => $_clearField(4);
}

/// 翻译次数查询
/// GET /v2/account/translate/product/list
class TranslateProductResponse extends $pb.GeneratedMessage {
  factory TranslateProductResponse({
    $fixnum.Int64? expireTime,
  }) {
    final result = create();
    if (expireTime != null) result.expireTime = expireTime;
    return result;
  }

  TranslateProductResponse._();

  factory TranslateProductResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TranslateProductResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TranslateProductResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'apiv2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'expireTime')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranslateProductResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TranslateProductResponse copyWith(
          void Function(TranslateProductResponse) updates) =>
      super.copyWith((message) => updates(message as TranslateProductResponse))
          as TranslateProductResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TranslateProductResponse create() => TranslateProductResponse._();
  @$core.override
  TranslateProductResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TranslateProductResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TranslateProductResponse>(create);
  static TranslateProductResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get expireTime => $_getI64(0);
  @$pb.TagNumber(1)
  set expireTime($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExpireTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearExpireTime() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
