import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String _tokenKey = 'auth_token';
  String? _token;

  /// Được gọi khi server trả 401 (token hết hạn) -> app quay về màn hình đăng nhập.
  void Function()? onUnauthorized;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<dynamic> get(String path, {Map<String, String>? query, bool redirectOn401 = true}) =>
      _send('GET', path, query: query, redirectOn401: redirectOn401);

  Future<dynamic> post(String path, {Object? body}) => _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) => _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool redirectOn401 = true,
  }) async {
    var uri = Uri.parse('${AppConstants.baseUrl}$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...query});
    }

    http.Response res;
    try {
      final req = http.Request(method, uri);
      req.headers['Content-Type'] = 'application/json';
      req.headers['Accept'] = 'application/json';
      if (hasToken) req.headers['Authorization'] = 'Bearer $_token';
      if (body != null) req.body = jsonEncode(body);
      final streamed = await req.send().timeout(const Duration(seconds: 20));
      res = await http.Response.fromStream(streamed);
    } catch (_) {
      throw ApiException(
          'Không thể kết nối máy chủ. Hãy kiểm tra backend đã chạy chưa và địa chỉ ${AppConstants.baseUrl}');
    }

    dynamic decoded;
    if (res.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        decoded = null;
      }
    }

    if (res.statusCode == 401 && hasToken && redirectOn401) {
      await clearToken();
      onUnauthorized?.call();
    }

    if (res.statusCode >= 400) {
      final msg = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : 'Đã xảy ra lỗi (mã ${res.statusCode})';
      throw ApiException(msg, res.statusCode);
    }

    if (decoded is Map) return decoded['data'];
    return decoded;
  }
}
