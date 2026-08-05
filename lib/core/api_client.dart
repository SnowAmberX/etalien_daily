/// HTTP 客户端模块（对照 v1 client.py）。
///
/// 封装 ET API 的所有 HTTP 交互：
/// - 请求签名（URL + 参数）
/// - 客户端伪装（Headers 模拟 OkHttp/Android）
/// - Protobuf 请求体序列化 / 响应体反序列化
/// - 自动重试（网络错误 + 5xx）
/// - 统一错误返回格式
/// - Token 管理
library;

import 'dart:async';
import 'dart:io';

import 'package:fixnum/fixnum.dart' show Int64;
import 'package:http/http.dart' as http;

import 'proto/account.pb.dart';
import 'proto/apiv2.pb.dart';
import 'proto/error.pb.dart' as error_pb;
import 'sign.dart';

/// 标准化手机号：11 位国内号码自动加 +86 前缀（服务端要求 13 位）。
String normalizePhone(String phone) {
  final p = phone.trim();
  if (!p.startsWith('+') && p.length == 11 && RegExp(r'^\d+$').hasMatch(p)) {
    return '+86$p';
  }
  return p;
}

/// 解析翻译产品列表响应中的当前可用翻译次数。
///
/// 服务端实际返回（2026-08-04 实测）：
///   message TranslateProductListResponse {
///     repeated TranslateProductItem list = 1; // 产品目录
///     int64 expire_time = 2;                  // 当前可用翻译次数
///   }
/// Dart protobuf 对 wire 类型不符会抛异常，这里手动跳过未知字段，
/// 只读取顶层 field 2 的 varint。
int? parseTranslateCount(List<int> bytes) {
  var i = 0;
  while (i < bytes.length) {
    final tag = _readVarint(bytes, i);
    if (tag == null) return null;
    i = tag.$2;
    final field = tag.$1 >> 3;
    final wire = tag.$1 & 7;
    if (field == 2 && wire == 0) {
      return _readVarint(bytes, i)?.$1;
    }
    final next = _skipWireField(bytes, i, wire);
    if (next == null) return null;
    i = next;
  }
  return null;
}

/// 读取 protobuf varint，返回 (值, 下一字节下标)；数据截断返回 null。
(int, int)? _readVarint(List<int> bytes, int start) {
  var value = 0;
  var shift = 0;
  var i = start;
  while (i < bytes.length && shift < 64) {
    final b = bytes[i++];
    value |= (b & 0x7F) << shift;
    if ((b & 0x80) == 0) return (value, i);
    shift += 7;
  }
  return null;
}

/// 跳过指定 wire type 的字段，返回下一字段下标；非法输入返回 null。
int? _skipWireField(List<int> bytes, int start, int wire) {
  switch (wire) {
    case 0: // varint
      return _readVarint(bytes, start)?.$2;
    case 1: // fixed64
      if (start + 8 > bytes.length) return null;
      return start + 8;
    case 2: // length-delimited
      final len = _readVarint(bytes, start);
      if (len == null || len.$2 + len.$1 > bytes.length) return null;
      return len.$2 + len.$1;
    case 5: // fixed32
      if (start + 4 > bytes.length) return null;
      return start + 4;
    default:
      return null; // groups(3/4) 或非法 wire type
  }
}

/// 统一 API 返回结果。
class ApiResult<T> {
  ApiResult.ok(this.data)
      : isError = false,
        code = null,
        msg = null;

  ApiResult.failure({this.code, this.msg})
      : isError = true,
        data = null;

  /// 是否有错误（业务或网络）。
  final bool isError;

  /// 错误码（HTTP 状态码或 protobuf Error.code），网络错误为 null。
  final int? code;

  /// 错误信息。
  final String? msg;

  /// 成功时的响应消息（可能为 null 表示空响应）。
  final T? data;

  bool get isOk => !isError;

  /// 是否为认证错误：HTTP 401/403 或 protobuf Error code == 16。
  bool get isAuthError =>
      isError && const {16, 401, 403}.contains(code);

  /// 是否应该重试：HTTP 5xx 或网络错误；4xx（含认证错误）与成功不重试。
  bool get isRetryable {
    if (!isError) return false;
    final c = code;
    if (c != null && c >= 500 && c < 600) return true;
    // 网络错误（无 code，有 msg）
    if (c == null && msg != null) return true;
    return false;
  }
}

class ApiClient {
  /// 每个账号对应一个 ApiClient 实例（独立的 deviceId 和 authToken）。
  ApiClient({required this.deviceId, String? authToken, http.Client? client})
      : _client = client ?? http.Client(),
        _authToken = authToken;

  static const String appVersion = '3.11.10';
  static const int maxRetries = 2; // 重试次数（共 3 次尝试）
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration requestTimeout = Duration(seconds: 30);

  /// 设备唯一标识（25 位 hex，与账号绑定持久化）。
  final String deviceId;

  final http.Client _client;
  String? _authToken;

  String? get authToken => _authToken;

  void updateAuthToken(String token) => _authToken = token;

  void clearAuthToken() => _authToken = null;

  Map<String, String> get _headers => {
        'User-Agent': 'okhttp/4.12.0',
        'Accept': 'application/x-protobuf',
        'Content-Type': 'application/x-protobuf',
        'x-eta': 'os=0&ver=$appVersion&dvc=$deviceId&ch=default',
        'Authorization': ?_authToken,
      };

  // ── API 方法 ───────────────────────────────────────────────

  /// 获取短信验证码。
  /// GET /account/v1/get_login_verification_code（GET 带 body，非标准但服务端接受）
  Future<ApiResult<GetLoginVerificationCodeResponse>> getVerificationCode(
    String phoneNumber,
  ) {
    final req =
        GetLoginVerificationCodeRequest(phoneNumber: normalizePhone(phoneNumber));
    return _retryRequest<GetLoginVerificationCodeResponse>(
      method: 'GET',
      path: '/account/v1/get_login_verification_code',
      bodyData: req.writeToBuffer(),
      isGetWithBody: true,
      parseResponse: GetLoginVerificationCodeResponse.fromBuffer,
    );
  }

  /// 验证码登录。成功时自动保存 authToken。
  Future<ApiResult<LoginResponse>> login(
    String phoneNumber,
    String verificationCode,
  ) async {
    final req = LoginRequest(
      phoneNumber: normalizePhone(phoneNumber),
      verificationCode: verificationCode,
    );
    final result = await _retryRequest<LoginResponse>(
      method: 'POST',
      path: '/account/v1/login',
      bodyData: req.writeToBuffer(),
      parseResponse: LoginResponse.fromBuffer,
    );
    final token = result.data?.authorization;
    if (result.isOk && token != null && token.isNotEmpty) {
      updateAuthToken(token);
    }
    return result;
  }

  /// 密码登录。成功时自动保存 authToken。
  Future<ApiResult<LoginV2Response>> loginByPassword(
    String phoneNumber,
    String password,
  ) async {
    final req =
        LoginV2Request(phoneNumber: normalizePhone(phoneNumber), password: password);
    final result = await _retryRequest<LoginV2Response>(
      method: 'POST',
      path: '/v2/account/login',
      bodyData: req.writeToBuffer(),
      parseResponse: LoginV2Response.fromBuffer,
    );
    final token = result.data?.authorization;
    if (result.isOk && token != null && token.isNotEmpty) {
      updateAuthToken(token);
    }
    return result;
  }

  /// 获取 PC 广告任务列表。
  Future<ApiResult<PcAdConfigResponse>> fetchPcAdConfig() {
    return _retryRequest<PcAdConfigResponse>(
      method: 'POST',
      path: '/v2/account/pc/ad/config',
      bodyData: PcAdConfigRequest().writeToBuffer(),
      parseResponse: PcAdConfigResponse.fromBuffer,
    );
  }

  /// 发送广告奖励补发回调（核心接口）。
  Future<ApiResult<PcAdCallbackBackupResponse>> pcAdCallbackBackup(
    String adId,
    int business,
  ) {
    final req =
        PcAdCallbackBackupRequest(adId: adId, business: Int64(business));
    return _retryRequest<PcAdCallbackBackupResponse>(
      method: 'POST',
      path: '/v2/account/pc/ad/callback/backup',
      bodyData: req.writeToBuffer(),
      parseResponse: PcAdCallbackBackupResponse.fromBuffer,
    );
  }

  /// 查询 PC 剩余时长。
  Future<ApiResult<GetUserRemainDurationResponse>> fetchPcDuration() {
    return _retryRequest<GetUserRemainDurationResponse>(
      method: 'POST',
      path: '/v2/account/remain/duration',
      bodyData: GetUserRemainDurationRequest().writeToBuffer(),
      parseResponse: GetUserRemainDurationResponse.fromBuffer,
    );
  }

  /// 检查当前 authToken 是否有效。
  Future<bool> checkTokenValid() async {
    if (_authToken == null) return false;
    final result = await fetchPcDuration();
    return !result.isAuthError;
  }

  /// 获取用户信息（含手机端加速时长余额）。
  Future<ApiResult<MyProfileResponse>> fetchMyProfile() {
    return _retryRequest<MyProfileResponse>(
      method: 'GET',
      path: '/account/v1/my_profile',
      parseResponse: MyProfileResponse.fromBuffer,
    );
  }

  /// 获取手机端广告任务列表。
  Future<ApiResult<AdActivityResponse>> fetchMobileAdActivity() {
    return _retryRequest<AdActivityResponse>(
      method: 'GET',
      path: '/award/v1/ad/activity',
      parseResponse: AdActivityResponse.fromBuffer,
    );
  }

  /// 获取当前可用翻译次数。
  ///
  /// 响应为产品目录 + 顶层 field 2（varint）= 当前可用翻译次数。
  Future<ApiResult<int>> fetchTranslateCount() {
    return _retryRequest<int>(
      method: 'POST',
      path: '/v2/account/translate/product/list',
      parseResponse: (bytes) {
        final count = parseTranslateCount(bytes);
        if (count == null) {
          throw const FormatException('translate product response malformed');
        }
        return count;
      },
    );
  }

  /// 获取翻译广告任务配置（多阶段，含 watched/unwatched 进度）。
  Future<ApiResult<PcAdConfigResponse>> fetchTranslateAdConfig() {
    return _retryRequest<PcAdConfigResponse>(
      method: 'POST',
      path: '/v2/account/translate/ad/config',
      parseResponse: PcAdConfigResponse.fromBuffer,
    );
  }

  // ── 内部方法 ───────────────────────────────────────────────

  /// 带重试的请求包装。
  ///
  /// 重试条件: 网络错误 / HTTP 5xx。不重试: HTTP 4xx（含认证错误）。
  Future<ApiResult<T>> _retryRequest<T>({
    required String method,
    required String path,
    List<int>? bodyData,
    bool isGetWithBody = false,
    required T Function(List<int>) parseResponse,
  }) async {
    ApiResult<T>? lastResult;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      final result = await _request<T>(
        method: method,
        path: path,
        bodyData: bodyData,
        isGetWithBody: isGetWithBody,
        parseResponse: parseResponse,
      );

      if (result.isRetryable && attempt < maxRetries) {
        lastResult = result;
        await Future<void>.delayed(retryDelay);
        continue;
      }
      return result;
    }
    return lastResult ?? ApiResult<T>.failure(msg: 'max retries exceeded');
  }

  /// 核心请求方法：签名 URL → 发送 → 解析响应。
  Future<ApiResult<T>> _request<T>({
    required String method,
    required String path,
    List<int>? bodyData,
    bool isGetWithBody = false,
    required T Function(List<int>) parseResponse,
  }) async {
    final (url, _) = signUrl(method, path);

    final request = http.Request(method.toUpperCase(), Uri.parse(url));
    request.headers.addAll(_headers);
    if (bodyData != null && (method.toUpperCase() != 'GET' || isGetWithBody)) {
      request.bodyBytes = bodyData;
    }

    final http.Response resp;
    try {
      final streamed = await _client.send(request).timeout(requestTimeout);
      resp = await http.Response.fromStream(streamed);
    } on TimeoutException catch (e) {
      return ApiResult<T>.failure(msg: 'timeout: $e');
    } on SocketException catch (e) {
      return ApiResult<T>.failure(msg: e.message);
    } on http.ClientException catch (e) {
      return ApiResult<T>.failure(msg: e.message);
    } catch (e) {
      return ApiResult<T>.failure(msg: e.toString());
    }

    return _parseResponse<T>(resp, parseResponse);
  }

  /// 解析 HTTP 响应。
  ///
  /// - HTTP >= 400: 反序列化 error.Error
  /// - HTTP 200 + 空 body: ok(data: null)
  /// - HTTP 200: 反序列化 protobuf
  ApiResult<T> _parseResponse<T>(
    http.Response resp,
    T Function(List<int>) parseResponse,
  ) {
    if (resp.statusCode >= 400) {
      var code = resp.statusCode;
      String? msg;
      if (resp.bodyBytes.isNotEmpty) {
        try {
          final err = error_pb.Error.fromBuffer(resp.bodyBytes);
          if (err.code != 0) code = err.code;
          msg = err.msg;
        } catch (_) {
          msg = resp.body;
        }
      }
      return ApiResult<T>.failure(
        code: code,
        msg: msg?.isNotEmpty == true ? msg : 'unknown error',
      );
    }

    // HTTP 200
    if (resp.bodyBytes.isEmpty) {
      return ApiResult<T>.ok(null);
    }

    try {
      return ApiResult<T>.ok(parseResponse(resp.bodyBytes));
    } catch (e) {
      return ApiResult<T>.failure(msg: 'protobuf parse error: $e');
    }
  }

  void close() => _client.close();
}
