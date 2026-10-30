import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  static const base = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:5080',
  );
  static const _storage = FlutterSecureStorage();
  String? token;
  String? refreshToken;
  Map<String, dynamic>? me;
  Future<dynamic> request(
    String path, {
    Object? body,
    bool retry = true,
  }) async {
    final uri = Uri.parse('$base/api$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response =
        await (body == null
                ? http.get(uri, headers: headers)
                : http.post(uri, headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401 &&
        retry &&
        refreshToken != null &&
        !path.startsWith('/auth/')) {
      try {
        final data = await request(
          '/auth/refresh',
          body: {'refreshToken': refreshToken},
          retry: false,
        );
        await saveTokens(data);
        return request(path, body: body, retry: false);
      } catch (_) {
        await logout();
        throw Exception('Your session expired. Please sign in again.');
      }
    }
    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      data = null;
    }
    if (response.statusCode >= 400) {
      var error = response.statusCode == 401
          ? 'Please sign in to continue.'
          : 'Request failed (${response.statusCode}).';
      if (data is Map) {
        if (data['error'] != null) {
          error = '${data['error']}';
        } else if (data['errors'] is Map) {
          error = (data['errors'] as Map).values
              .expand((v) => v is List ? v : [v])
              .join(' ');
        } else if (data['detail'] != null) {
          error = '${data['detail']}';
        }
      }
      throw Exception(error);
    }
    return data;
  }

  Future<void> saveTokens(dynamic data) async {
    token = data['accessToken'];
    refreshToken = data['refreshToken'];
    await _storage.write(key: 'localpro_refresh', value: refreshToken);
  }

  Future<void> restore() async {
    refreshToken = await _storage.read(key: 'localpro_refresh');
    if (refreshToken == null) return;
    try {
      await saveTokens(
        await request(
          '/auth/refresh',
          body: {'refreshToken': refreshToken},
          retry: false,
        ),
      );
      me = Map<String, dynamic>.from(await request('/me'));
    } catch (_) {
      await logout();
    }
  }

  Future<void> login(String email, String password) async {
    await saveTokens(
      await request(
        '/auth/login?useCookies=false',
        body: {'email': email, 'password': password},
      ),
    );
    me = Map<String, dynamic>.from(await request('/me'));
  }

  Future<void> socialLogin(String provider, bool Function() cancelled) async {
    final random = Random.secure();
    final secret = base64UrlEncode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final started = await request(
      '/social/mobile/start',
      body: {'provider': provider, 'secret': secret},
    );
    final url = Uri.parse('$base${started['path']}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open the sign-in browser.');
    }
    final deadline = DateTime.now().add(const Duration(minutes: 5));
    while (DateTime.now().isBefore(deadline) && !cancelled()) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (cancelled()) return;
      final result = await request(
        '/social/mobile/complete',
        body: {'ticket': started['ticket'], 'secret': secret},
      );
      if (result['pending'] == true) continue;
      await saveTokens(result);
      me = Map<String, dynamic>.from(await request('/me'));
      return;
    }
    if (!cancelled()) throw Exception('Sign-in expired. Please try again.');
  }

  Future<void> logout() async {
    token = null;
    refreshToken = null;
    me = null;
    await _storage.delete(key: 'localpro_refresh');
  }
}

final api = Api();
