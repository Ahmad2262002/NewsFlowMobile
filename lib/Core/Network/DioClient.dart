import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http_parser/http_parser.dart';

class DioClient {
  String? token;
  final Duration _connectTimeout;
  final Duration _receiveTimeout;
  final Duration _sendTimeout;
  final int _maxRetries;
  final Duration _retryDelay;
  final bool _enableCircuitBreaker;
  final Duration _circuitBreakerCooldown;

  late Dio _dio;
  final Connectivity _connectivity = Connectivity();
  bool _circuitOpen = false;
  DateTime? _lastFailureTime;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription; // UPDATED

  DioClient({
    this.token,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    int? maxRetries,
    Duration? retryDelay,
    bool? enableCircuitBreaker,
    Duration? circuitBreakerCooldown,
  })  : _connectTimeout = connectTimeout ?? const Duration(seconds: 45),
        _receiveTimeout = receiveTimeout ?? const Duration(seconds: 45),
        _sendTimeout = sendTimeout ?? const Duration(seconds: 45),
        _maxRetries = maxRetries ?? 3,
        _retryDelay = retryDelay ?? const Duration(seconds: 2),
        _enableCircuitBreaker = enableCircuitBreaker ?? true,
        _circuitBreakerCooldown = circuitBreakerCooldown ?? const Duration(minutes: 1) {
    _initDio();
    _checkInitialConnectivity();
    _startConnectivityMonitoring();
  }

  Dio getInstance() => _dio;

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://172.20.10.3:8000/api',
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _sendTimeout,
        headers: _getDefaultHeaders(),
        persistentConnection: true,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.addAll([
      _createRetryInterceptor(),
      if (kDebugMode) _createLoggerInterceptor(),
    ]);
  }

  Map<String, String> _getDefaultHeaders() {
    return {
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip',
      'Connection': 'keep-alive',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _logConnectivity(result);

      if (result == ConnectivityResult.none) {
        _activateCircuitBreaker();
        throw DioException(
          requestOptions: RequestOptions(path: '/'),
          error: 'No internet connection available',
          type: DioExceptionType.connectionError,
        );
      }
    } catch (e) {
      _activateCircuitBreaker();
      rethrow;
    }
  }

  void _logConnectivity(ConnectivityResult result) {
    print('📡 Connectivity changed: $result');
    if (result == ConnectivityResult.none) {
      print('⚠️ No internet connection!');
    } else {
      print('✅ Back online: $result');
    }
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
          final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
          _logConnectivity(result);

          if (result != ConnectivityResult.none) {
            if (_circuitOpen &&
                _lastFailureTime != null &&
                DateTime.now().difference(_lastFailureTime!) >= _circuitBreakerCooldown) {
              _circuitOpen = false;
              print('🔄 Circuit breaker reset due to restored connection.');
            }
          } else {
            _activateCircuitBreaker();
          }
        });
  }

  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_circuitOpen) {
          return handler.reject(DioException(
            requestOptions: options,
            error: 'Service temporarily unavailable. Please try again later.',
          ));
        }

        if (options.data is! FormData) {
          try {
            final results = await _connectivity.checkConnectivity();
            final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
            if (result == ConnectivityResult.none) {
              _activateCircuitBreaker();
              return handler.reject(DioException(
                requestOptions: options,
                error: 'No internet connection available',
                type: DioExceptionType.connectionError,
              ));
            }
          } catch (e) {
            _activateCircuitBreaker();
            return handler.reject(DioException(
              requestOptions: options,
              error: 'Network connectivity check failed',
              type: DioExceptionType.connectionError,
            ));
          }
        }

        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.requestOptions.data is FormData) {
          return handler.next(error);
        }

        if (!_shouldRetry(error)) {
          return handler.next(error);
        }

        final retryCount = (error.requestOptions.extra['retryCount'] as int?) ?? 0;
        if (retryCount >= _maxRetries) {
          if (_enableCircuitBreaker) _activateCircuitBreaker();
          return handler.next(error);
        }

        final delay = _calculateRetryDelay(retryCount);
        await Future.delayed(delay);

        error.requestOptions.extra['retryCount'] = retryCount + 1;

        try {
          final response = await _dio.request(
            error.requestOptions.path,
            data: error.requestOptions.data,
            options: Options(
              method: error.requestOptions.method,
              headers: error.requestOptions.headers,
              extra: error.requestOptions.extra,
            ),
          );
          return handler.resolve(response);
        } catch (_) {
          return handler.next(error);
        }
      },
    );
  }

  PrettyDioLogger _createLoggerInterceptor() {
    return PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    );
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode ?? 0) >= 500;
  }

  Duration _calculateRetryDelay(int retryCount) {
    final exponentialDelay = _retryDelay * (1 << retryCount);
    final jitter = Duration(milliseconds: (Random().nextDouble() * 1000).round());
    return exponentialDelay + jitter;
  }

  void _activateCircuitBreaker() {
    if (!_circuitOpen) {
      _circuitOpen = true;
      _lastFailureTime = DateTime.now();
      Timer(_circuitBreakerCooldown, _resetCircuitBreaker);
      print('🛑 Circuit breaker activated!');
    }
  }

  void _resetCircuitBreaker() {
    if (_lastFailureTime != null &&
        DateTime.now().difference(_lastFailureTime!) >= _circuitBreakerCooldown) {
      _circuitOpen = false;
      print('✅ Circuit breaker cooldown expired, back to normal.');
    }
  }

  Future<Response> updateProfile({
    String? username,
    String? email,
    String? imagePath,
  }) async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result == ConnectivityResult.none) {
        throw DioException(
          requestOptions: RequestOptions(path: '/profile'),
          error: 'No internet connection available',
          type: DioExceptionType.connectionError,
        );
      }

      final formData = FormData.fromMap({
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (imagePath != null)
          'profile_picture': await MultipartFile.fromFile(
            imagePath,
            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
      });

      final response = await _dio.put(
        '/profile',
        data: formData,
        options: Options(
          headers: {
            ..._getDefaultHeaders(),
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        _activateCircuitBreaker();
      }
      rethrow;
    }
  }

  Future<void> updateToken(String newToken) async {
    token = newToken;
    _dio.options.headers['Authorization'] = 'Bearer $newToken';
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _dio.close();
  }
}
