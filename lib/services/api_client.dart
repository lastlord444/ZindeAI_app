import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'errors.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio _dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    // Load base URL from .env or use a default
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.zindeai.com/v1';
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('API_LOG: $obj'),
    ));
    
    // Add Auth Interceptor here later
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout || 
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Connection timed out', details: error.message);
    }

    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = (data is Map && data['message'] != null) 
          ? data['message'] 
          : error.message;

      if (statusCode == 401 || statusCode == 403) {
        return AuthException('Unauthorized: $message');
      }
      if (statusCode == 400) {
        return ValidationException('Validation Error: $message', details: data);
      }
      if (statusCode != null && statusCode >= 500) {
        return ServerException('Server Error: $message', statusCode: statusCode, details: data);
      }
    }

    return NetworkException('Network Error: ${error.message}', details: error);
  }
}
