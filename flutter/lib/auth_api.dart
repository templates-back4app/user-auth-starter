// Stack: Flutter 3.x / Dart 3.x, package:http | File: lib/auth_api.dart
// The same six REST calls the web page makes, with no SDK: the backend's REST API is the contract.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class AuthError implements Exception {
  final int status;
  final int? code;
  final String message;
  AuthError(this.status, this.code, this.message);
  @override
  String toString() => '$code $message';
}

class AuthApi {
  static const _base = backendUrl;
  static const _headers = {
    'X-Parse-Application-Id': appId,
    'X-Parse-Client-Key': clientKey,      // a client key: identifies the app, not the user
    'X-Parse-Revocable-Session': '1',
    'Content-Type': 'application/json',
  };
  String? sessionToken;                   // kept in memory; persist it with flutter_secure_storage in a real app

  Future<Map<String, dynamic>> _call(String method, String path, {Map<String, dynamic>? body}) async {
    final headers = {..._headers, if (sessionToken != null) 'X-Parse-Session-Token': sessionToken!};
    final uri = Uri.parse('$_base$path');
    final r = switch (method) {
      'GET' => await http.get(uri, headers: headers),
      'POST' => await http.post(uri, headers: headers, body: jsonEncode(body ?? {})),
      _ => throw ArgumentError(method),
    };
    final data = r.body.isEmpty ? <String, dynamic>{} : jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 400) throw AuthError(r.statusCode, data['code'] as int?, data['error']?.toString() ?? r.reasonPhrase ?? '');
    return data;
  }

  Future<Map<String, dynamic>> signUp(String username, String email, String password) async {
    final u = await _call('POST', '/users', body: {'username': username, 'email': email, 'password': password});
    sessionToken = u['sessionToken'] as String;
    return u;
  }

  Future<Map<String, dynamic>> logIn(String username, String password) async {
    final u = await _call('POST', '/login', body: {'username': username, 'password': password});
    sessionToken = u['sessionToken'] as String;
    return u;
  }

  Future<Map<String, dynamic>> me() => _call('GET', '/users/me');
  Future<void> requestPasswordReset(String email) => _call('POST', '/requestPasswordReset', body: {'email': email});
  Future<void> requestVerificationEmail(String email) => _call('POST', '/verificationEmailRequest', body: {'email': email});

  Future<void> logOut() async {
    try { await _call('POST', '/logout'); } finally { sessionToken = null; }   // revoked server-side, then forgotten
  }
}
