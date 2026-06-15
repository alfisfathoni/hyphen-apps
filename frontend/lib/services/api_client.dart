import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:hyphen/managers/auth_manager.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  // Android emulator accesses host machine via 10.0.2.2.
  // For physical devices, this needs to be the actual IP of the machine on the local network.
  static String get baseUrl {
    return 'https://hyphen-apps-production.up.railway.app';
  }

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Automatically inject JWT token to every request if available
        final token = await secureStorage.read(key: 'accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        debugPrint(' API Request: [${options.method}] ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(' API Response: [${response.statusCode}] ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        debugPrint(' API Error: [${e.response?.statusCode}] ${e.requestOptions.path} - ${e.response?.data ?? e.message}');
        if (e.response?.statusCode == 401) {
          debugPrint(' Session expired (401). Triggering auto-logout.');
          AuthManager().logout();
        }
        return handler.next(e);
      },
    ));
  }

  Future<void> saveToken(String token) async {
    await secureStorage.write(key: 'accessToken', value: token);
  }

  Future<void> clearToken() async {
    await secureStorage.delete(key: 'accessToken');
  }
}
