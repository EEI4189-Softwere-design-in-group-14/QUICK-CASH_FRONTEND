import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class UserSession {
  final String token;
  final String name;
  final String email;
  final String role;
  const UserSession({required this.token, required this.name, required this.email, required this.role});

  factory UserSession.fromJson(Map<String, dynamic> data) => UserSession(
        token: (data['token'] ?? '').toString(),
        name: (data['fullName'] ?? '').toString(),
        email: (data['email'] ?? '').toString(),
        role: (data['role'] ?? '').toString().toUpperCase(),
      );
}

class ApiClient {
  // Android emulator -> Windows host. On physical phones, supply --dart-define=API_BASE_URL=http://YOUR_PC_IP:8080/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL', defaultValue: 'http://10.0.2.2:8080/api',
  );

  final http.Client _client = http.Client();

  Future<dynamic> request(String method, String path, {String? token, Map<String, dynamic>? body}) async {
    try {
      final url = Uri.parse('$baseUrl$path');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      late http.Response response;
      switch (method) {
        case 'POST':
          response = await _client.post(url, headers: headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 15));
        case 'PUT':
          response = await _client.put(url, headers: headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 15));
        case 'GET':
          response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 15));
        default:
          throw const ApiException('Unsupported request method');
      }
      dynamic result;
      try { result = jsonDecode(response.body); } catch (_) { result = null; }
      if (response.statusCode >= 200 && response.statusCode < 300) return result;
      if (response.statusCode == 401) throw const ApiException('Invalid login or session expired.');
      if (response.statusCode == 403) throw const ApiException('Account not active, or permission denied.');
      String message = 'Request failed (HTTP ${response.statusCode})';
      if (result is Map) {
        final reason = result['detail'] ?? result['message'] ?? result['error'];
        if (reason is String && reason.isNotEmpty) message = reason;
      }
      throw ApiException(message);
    } on SocketException {
      throw const ApiException('Cannot connect to backend. Check Spring Boot and API address.');
    } on HttpException {
      throw const ApiException('Network error. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid API URL.');
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e.toString().contains('TimeoutException')) throw const ApiException('Server timeout. Please try again.');
      if (kDebugMode) debugPrint('API error: $e');
      throw const ApiException('Connection failed. Check backend and network settings.');
    }
  }

  Future<UserSession> login(String email, String password) async {
    final result = await request('POST', '/auth/login', body: {
      'email': email.trim().toLowerCase(), 'password': password,
    });
    if (result is! Map<String, dynamic>) throw const ApiException('Unexpected login response.');
    final session = UserSession.fromJson(result);
    if (session.token.isEmpty || session.role.isEmpty) throw const ApiException('Missing token or role in login response.');
    return session;
  }

  void close() => _client.close();
}
