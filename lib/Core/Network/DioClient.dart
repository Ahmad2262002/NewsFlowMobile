import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DioClient {
  String? token;
  final Duration _connectTimeout;
  final Duration _receiveTimeout;
  final Duration _sendTimeout;
  final int _maxRetries;
  final Duration _retryDelay;
  final bool _enableCircuitBreaker;

  late Dio _dio;
  final Connectivity _connectivity = Connectivity();
  bool _circuitOpen = false;
  DateTime? _lastFailureTime;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  DioClient({
    this.token,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    int? maxRetries,
    Duration? retryDelay,
    bool? enableCircuitBreaker,
  })  : _connectTimeout = connectTimeout ?? const Duration(seconds: 45),
        _receiveTimeout = receiveTimeout ?? const Duration(seconds: 45),
        _sendTimeout = sendTimeout ?? const Duration(seconds: 45),
        _maxRetries = maxRetries ?? 3,
        _retryDelay = retryDelay ?? const Duration(seconds: 2),
        _enableCircuitBreaker = enableCircuitBreaker ?? true {
    _initDio();
    _startConnectivityMonitoring();
  }

  Dio getInstance() {
    return _dio;
  }

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
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip',
      'Connection': 'keep-alive',
      if (token != null) 'Authorization': 'Bearer $token',
    };
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

        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          return handler.reject(DioException(
            requestOptions: options,
            error: 'No internet connection available',
            type: DioExceptionType.connectionError,
          ));
        }

        return handler.next(options);
      },
      onError: (error, handler) async {
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
        error.requestOptions.extra['lastRetry'] = DateTime.now();

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
        } catch (e) {
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
    _circuitOpen = true;
    _lastFailureTime = DateTime.now();
    Timer(const Duration(minutes: 1), () => _circuitOpen = false);
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && _circuitOpen) {
        _circuitOpen = false;
      }
    });
  }

  Options getLowBandwidthOptions() {
    return Options(
      headers: _getDefaultHeaders(),
      receiveTimeout: _receiveTimeout * 2,
      sendTimeout: _sendTimeout * 2,
    );
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