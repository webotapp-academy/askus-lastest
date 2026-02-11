import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    required this.statusCode,
  });
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _storage = const FlutterSecureStorage();
  String? _token;

  Future<String?> get token async {
    if (_token != null) return _token;

    try {
      _token = await _storage.read(key: 'auth_token');
    } on PlatformException catch (e) {
      debugPrint('⚠️ Secure Storage Error (Likely corrupted data): $e');
      debugPrint('🗑️ Clearing all secure storage to recover...');
      try {
        await _storage.deleteAll();
      } catch (e) {
        debugPrint('❌ Failed to clear storage: $e');
      }
      _token = null;
    } catch (e) {
      debugPrint('⚠️ General Storage Error: $e');
      _token = null;
    }

    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'auth_token');
  }

  Future<Map<String, String>> _headers() async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint,
      {Map<String, String>? params}) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      if (params != null) {
        uri = uri.replace(queryParameters: params);
      }

      debugPrint('🌐 API GET Request:');
      debugPrint('📍 URL: $uri');
      debugPrint('📋 Headers: ${await _headers()}');
      if (params != null) debugPrint('🔍 Params: $params');

      final response = await http.get(uri, headers: await _headers()).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏰ GET Request timeout after 30 seconds');
          throw TimeoutException(
              'Request timeout - please check your internet connection');
        },
      );

      debugPrint('📥 API GET Response:');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ API GET Error: $e');
      String errorMessage = e.toString();
      if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error - please check your internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout - server is taking too long to respond';
      }
      return ApiResponse(success: false, message: errorMessage, statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final headers = await _headers();
      final jsonBody = jsonEncode(body);

      debugPrint('🌐 API POST Request:');
      debugPrint('📍 URL: $uri');
      debugPrint('📋 Headers: $headers');
      debugPrint('📦 Body: $jsonBody');

      // Add timeout and better error handling
      final response = await http
          .post(
        uri,
        headers: headers,
        body: jsonBody,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏰ Request timeout after 30 seconds');
          throw Exception(
              'Request timeout - please check your internet connection');
        },
      );

      debugPrint('📥 API POST Response:');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');
      debugPrint('📏 Response Length: ${response.body.length} characters');
      debugPrint('🏷️ Response Headers: ${response.headers}');

      // Log specific status code meanings
      if (response.statusCode == 500) {
        debugPrint(
            '🚨 SERVER ERROR (500): Internal server error - check server logs');
      } else if (response.statusCode == 401) {
        debugPrint(
            '🔒 UNAUTHORIZED (401): Invalid credentials or authentication failed');
      } else if (response.statusCode == 404) {
        debugPrint('🔍 NOT FOUND (404): API endpoint not found');
      } else if (response.statusCode == 422) {
        debugPrint('📝 VALIDATION ERROR (422): Request data validation failed');
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ API POST Error: $e');
      debugPrint('🔍 Error Type: ${e.runtimeType}');

      String errorMessage = e.toString();
      if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error - please check your internet connection';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout - server is taking too long to respond';
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage = 'SSL/TLS connection error';
      }

      return ApiResponse(success: false, message: errorMessage, statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> postMultipart(
    String endpoint,
    Map<String, String> fields,
    List<File> files,
    String fileField,
  ) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      final t = await token;
      debugPrint('🌐 API MULTIPART Request:');
      debugPrint('📍 URL: $uri');
      debugPrint(
          '🔑 Token: ${t != null ? "Present (${t.substring(0, 10)}...)" : "NULL - NOT AUTHENTICATED!"}');
      debugPrint('📋 Fields: $fields');
      debugPrint('📁 Files: ${files.length} file(s)');

      if (t != null) {
        request.headers['Authorization'] = 'Bearer $t';
      } else {
        debugPrint('⚠️ WARNING: No auth token - request will likely fail!');
      }

      request.fields.addAll(fields);

      for (var file in files) {
        debugPrint('📎 Adding file: ${file.path}');
        request.files
            .add(await http.MultipartFile.fromPath(fileField, file.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 API MULTIPART Response:');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint('📄 Response Body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ API MULTIPART Error: $e');
      return ApiResponse(success: false, message: e.toString(), statusCode: 0);
    }
  }

  ApiResponse<Map<String, dynamic>> _handleResponse(http.Response response) {
    try {
      debugPrint('🔄 Processing API Response...');

      // Check if response body is empty
      if (response.body.isEmpty) {
        debugPrint('⚠️ Empty response body');
        String errorMessage = 'Empty response from server';

        // Provide more specific error messages based on status code
        if (response.statusCode == 500) {
          errorMessage =
              'Server error (500) - The server encountered an internal error. Please try again later.';
        } else if (response.statusCode == 502) {
          errorMessage =
              'Bad Gateway (502) - Server is temporarily unavailable.';
        } else if (response.statusCode == 503) {
          errorMessage =
              'Service Unavailable (503) - Server is temporarily down for maintenance.';
        }

        return ApiResponse(
          success: false,
          message: errorMessage,
          statusCode: response.statusCode,
        );
      }

      // Try to decode JSON
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('📋 Parsed JSON Data: $data');

      // Handle different response formats
      bool success = false;
      String? message;

      if (data.containsKey('success')) {
        success = data['success'] == true ||
            data['success'] == 1 ||
            data['success'] == 'true';
        debugPrint('✅ Success field found: ${data['success']} -> $success');
      } else if (data.containsKey('status')) {
        success = data['status'] == 'success' ||
            data['status'] == true ||
            data['status'] == 1;
        debugPrint('✅ Status field found: ${data['status']} -> $success');
      } else if (response.statusCode >= 200 && response.statusCode < 300) {
        success = true;
        debugPrint(
            '✅ Success based on HTTP status code: ${response.statusCode}');
      }

      // Extract message
      message = data['message']?.toString() ??
          data['msg']?.toString() ??
          data['error']?.toString();
      debugPrint('💬 Extracted message: $message');

      final apiResponse = ApiResponse(
        success: success,
        message: message,
        data: data,
        statusCode: response.statusCode,
      );

      debugPrint('🎯 Final API Response: Success=$success, Message=$message');
      return apiResponse;
    } catch (e) {
      debugPrint('❌ JSON Parse Error: $e');
      debugPrint('📄 Raw response body: ${response.body}');
      return ApiResponse(
        success: false,
        message: 'Invalid response format: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }
}
