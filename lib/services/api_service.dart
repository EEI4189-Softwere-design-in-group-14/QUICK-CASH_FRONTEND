
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  final http.Client _client = http.Client();

  // ==============================
  // TOKEN MANAGEMENT
  // ==============================

  Future<void> saveToken(String token) async {
    await _storage.write(
      key: 'auth_token',
      value: token,
    );
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'auth_token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  // ==============================
  // LOGIN
  // POST /api/auth/login
  // ==============================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await post(
      ApiConstants.login,
      {
        'email': email.trim(),
        'password': password,
      },
      authenticated: false,
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('Invalid login response');
    }

    final token = response['token'];

    if (token is! String || token.isEmpty) {
      throw ApiException('Token not found in response');
    }

    await saveToken(token);

    return response;
  }

  // ==============================
  // BORROWER REGISTRATION
  // KAN-31
  // POST /api/auth/register
  // ==============================

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String nic,
    required String address,
    required String password,
    String? dateOfBirth,
    String? gender,
    String? occupation,
    double? monthlyIncome,
  }) async {
    final data = <String, dynamic>{
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'nic': nic.trim(),
      'address': address.trim(),
      'password': password,
    };

    // Optional Date of Birth
    if (dateOfBirth != null &&
        dateOfBirth.isNotEmpty) {
      data['dateOfBirth'] = dateOfBirth;
    }

    // Optional Gender
    if (gender != null && gender.isNotEmpty) {
      data['gender'] = gender;
    }

    // Optional Occupation
    if (occupation != null &&
        occupation.isNotEmpty) {
      data['occupation'] = occupation.trim();
    }

    // Optional Monthly Income
    if (monthlyIncome != null) {
      data['monthlyIncome'] = monthlyIncome;
    }

    final response = await post(
      ApiConstants.register,
      data,
      authenticated: false,
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException(
        'Invalid registration response',
      );
    }

    return response;
  }

  // ==============================
  // BORROWER DASHBOARD
  // GET /api/borrower/dashboard
  // ==============================

  Future<Map<String, dynamic>> getBorrowerDashboard() async {
    final response = await get(ApiConstants.borrowerDashboard);
    if (response is! Map<String, dynamic>) {
      throw ApiException('Invalid borrower dashboard response');
    }
    return response;
  }

  // ==============================
  // BORROWER LOANS
  // GET /api/borrower/loans
  // ==============================

  Future<List<dynamic>> getMyLoans() async {
    final response = await get(ApiConstants.borrowerLoans);
    if (response is! List) {
      throw ApiException('Invalid loans response');
    }
    return response;
  }

  // ==============================
  // APPLY FOR A LOAN
  // POST /api/borrower/loans
  // Guarantor details are part of this request.
  // ==============================

  Future<Map<String, dynamic>> applyForLoan({
    required double requestedAmount,
    required String purpose,
    required int repaymentMonths,
    required String guarantorFullName,
    required String guarantorNic,
    required String guarantorPhone,
    required String guarantorAddress,
    String? guarantorOccupation,
  }) async {
    final response = await post(
      ApiConstants.borrowerLoans,
      {
        'requestedAmount': requestedAmount,
        'purpose': purpose.trim(),
        'repaymentMonths': repaymentMonths,
        'guarantorFullName': guarantorFullName.trim(),
        'guarantorNic': guarantorNic.trim(),
        'guarantorPhone': guarantorPhone.trim(),
        'guarantorAddress': guarantorAddress.trim(),
        'guarantorOccupation': guarantorOccupation?.trim() ?? '',
      },
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('Invalid loan application response');
    }
    return response;
  }

  // ==============================
  // GET REQUEST
  // ==============================

  Future<dynamic> get(
      String endpoint, {
        bool authenticated = true,
      }) {
    return _request(
      'GET',
      endpoint,
      authenticated: authenticated,
    );
  }

  // ==============================
  // POST REQUEST
  // ==============================

  Future<dynamic> post(
      String endpoint,
      Map<String, dynamic> data, {
        bool authenticated = true,
      }) {
    return _request(
      'POST',
      endpoint,
      body: data,
      authenticated: authenticated,
    );
  }

  // ==============================
  // PUT REQUEST
  // ==============================

  Future<dynamic> put(
      String endpoint,
      Map<String, dynamic> data, {
        bool authenticated = true,
      }) {
    return _request(
      'PUT',
      endpoint,
      body: data,
      authenticated: authenticated,
    );
  }

  // ==============================
  // COMMON API REQUEST HANDLER
  // ==============================

  Future<dynamic> _request(
      String method,
      String endpoint, {
        Map<String, dynamic>? body,
        required bool authenticated,
      }) async {
    try {
      final token =
      authenticated ? await getToken() : null;

      if (authenticated &&
          (token == null || token.isEmpty)) {
        throw ApiException(
          'Please login first',
          401,
        );
      }

      final request = http.Request(
        method,
        Uri.parse(
          '${ApiConstants.baseUrl}$endpoint',
        ),
      );

      request.headers['Content-Type'] =
      'application/json';

      request.headers['Accept'] =
      'application/json';

      if (authenticated && token != null) {
        request.headers['Authorization'] =
        'Bearer $token';
      }

      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse = await _client
          .send(request)
          .timeout(
        const Duration(seconds: 15),
      );

      final response =
      await http.Response.fromStream(
        streamedResponse,
      );

      dynamic result;

      try {
        result = response.body.isEmpty
            ? null
            : jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          'Invalid response from server',
          response.statusCode,
        );
      }

      // Successful HTTP response
      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return result;
      }

      // Backend error message
      String message = 'Request failed';

      if (result is Map) {
        final serverMessage = result['message'];
        final detail = result['detail'];

        if (serverMessage is String &&
            serverMessage.isNotEmpty) {
          message = serverMessage;
        } else if (detail is String &&
            detail.isNotEmpty) {
          message = detail;
        }
      }

      throw ApiException(
        message,
        response.statusCode,
      );
    } on SocketException {
      throw ApiException(
        'Cannot connect to backend server',
      );
    } on TimeoutException {
      throw ApiException(
        'Server connection timed out',
      );
    } on http.ClientException {
      throw ApiException(
        'Network request failed',
      );
    }
  }

  // ==============================
  // CLOSE HTTP CLIENT
  // ==============================

  void dispose() {
    _client.close();
  }
}
