import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'algo_config.dart';
import 'errors.dart';
import 'models/swap_models.dart';

/// Swap Alternatives Service HTTP istemcisi (ALG-001).
///
/// Ayrı Dio instance kullanır (ana ApiClient'tan bağımsız base URL).
/// Retry/backoff: 5xx ve timeout için 3 deneme (1s, 2s, 4s).
/// 422 → InsufficientPoolException (retry YOK).
/// 4xx diğer → retry YOK.
class AlgoClient {
  final Dio _dio;

  AlgoClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AlgoConfig.baseUrl,
              connectTimeout: AlgoConfig.timeout,
              receiveTimeout: AlgoConfig.timeout,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )) {
    if (dio == null) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) {
          if (kDebugMode) debugPrint('ALGO_LOG: $obj');
        },
      ));
    }
  }

  /// GET /health — backend sağlık kontrolü.
  Future<Map<String, dynamic>> health() async {
    final response = await _withRetry(() => _dio.get('/health'));
    return response.data as Map<String, dynamic>;
  }

  /// POST /get-alternatives — swap alternatifleri getir.
  ///
  /// 200 → [SwapAlternativesResponse] döner.
  /// 422 → [InsufficientPoolException] fırlatır.
  Future<SwapAlternativesResponse> getAlternatives(
    SwapAlternativesRequest request,
  ) async {
    final response = await _withRetry(
      () => _dio.post('/get-alternatives', data: request.toJson()),
    );
    return SwapAlternativesResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Retry wrapper: sadece 5xx ve timeout/connection hatalarında retry yapar.
  /// 422 ve diğer 4xx hataları anında fırlatır (business error).
  Future<Response<dynamic>> _withRetry(
    Future<Response<dynamic>> Function() request,
  ) async {
    for (int attempt = 0; attempt < AlgoConfig.maxRetries; attempt++) {
      try {
        return await request();
      } on DioException catch (e) {
        // 422 → InsufficientPoolException (retry YOK)
        if (e.response?.statusCode == 422) {
          final data = e.response?.data;
          if (data is Map<String, dynamic>) {
            throw InsufficientPoolException.fromJson(data);
          }
          throw InsufficientPoolException(
            'Alternatif havuzu yetersiz',
          );
        }

        // 4xx diğer → retry YOK
        if (e.response != null &&
            e.response!.statusCode != null &&
            e.response!.statusCode! >= 400 &&
            e.response!.statusCode! < 500) {
          throw _mapDioError(e);
        }

        // 5xx veya timeout → retry
        final isRetryable = _isRetryable(e);
        final isLastAttempt = attempt == AlgoConfig.maxRetries - 1;

        if (!isRetryable || isLastAttempt) {
          throw _mapDioError(e);
        }

        // Exponential backoff: 1s, 2s, 4s
        final delay = Duration(
          seconds: AlgoConfig.backoffSeconds[attempt],
        );
        if (kDebugMode) {
          debugPrint(
            'ALGO_RETRY: attempt ${attempt + 1}/${AlgoConfig.maxRetries}, '
            'waiting ${delay.inSeconds}s',
          );
        }
        await Future<void>.delayed(delay);
      }
    }

    // Buraya ulaşılmamalı ama güvenlik için
    throw NetworkException('Maksimum deneme sayısına ulaşıldı');
  }

  bool _isRetryable(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }
    // 5xx server hataları
    final statusCode = e.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return true;
    }
    return false;
  }

  AppBaseException _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkException(
        'Bağlantı zaman aşımına uğradı',
        details: e.message,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkException(
        'Sunucuya bağlanılamadı. Backend çalışıyor mu?',
        details: e.message,
      );
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (statusCode == 404) {
      return ValidationException(
        'Yemek bulunamadı',
        details: data,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ServerException(
        'Sunucu hatası',
        statusCode: statusCode,
        details: data,
      );
    }

    return NetworkException(
      'Beklenmeyen hata: ${e.message}',
      details: e,
    );
  }
}
