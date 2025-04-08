import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:study_scheduler/services/local_storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  late Dio _dio;
  final LocalStorageService _storageService = LocalStorageService();
  
  // Base URL from environment variables
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.studyscheduler.com/v1';
  
  ApiClient._internal() {
    _initDio();
  }
  
  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
    ));
    
    // Add interceptors for authentication, logging, etc.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests if available
        final token = await _storageService.getAuthToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Process successful responses
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        // Handle authentication errors (401)
        if (e.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            return handler.resolve(await _retryRequest(e.requestOptions));
          }
        }
        
        // Handle other errors
        return handler.next(e);
      },
    ));
    
    // Add logging interceptor for development
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
  
  // Generic GET request
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  // Generic POST request
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  // Generic PUT request
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  // Generic DELETE request
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  // Upload file
  Future<dynamic> uploadFile(String path, File file, {String fieldName = 'file'}) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      
      final response = await _dio.post(
        path,
        data: formData,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  // Refresh authentication token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }
      
      // Create a new Dio instance for token refresh to avoid interceptors
      final tokenDio = Dio(BaseOptions(baseUrl: baseUrl));
      
      final response = await tokenDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      
      if (response.statusCode == 200) {
        final newToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        
        // Save new tokens
        await _storageService.setAuthToken(newToken);
        await _storageService.setRefreshToken(newRefreshToken);
        
        return true;
      }
      
      return false;
    } catch (e) {
      // Clear tokens on refresh failure
      await _storageService.clearTokens();
      return false;
    }
  }
  
  // Retry a failed request with new token
  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final token = await _storageService.getAuthToken();
    
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
  
  // Error handling
  void _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        // API returned error response
        print('API Error: ${error.response?.statusCode} - ${error.response?.statusMessage}');
        print('Data: ${error.response?.data}');
      } else {
        // Error in setting up request or no response received
        print('Request Error: ${error.message}');
      }
    } else {
      // Something else went wrong
      print('Unexpected Error: $error');
    }
  }
}