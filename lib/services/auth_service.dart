import 'package:flutter/foundation.dart';
import 'package:study_scheduler/api/api_client.dart';
import 'package:study_scheduler/services/local_storage_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final LocalStorageService _storageService = LocalStorageService();
  
  AuthStatus _status = AuthStatus.unknown;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  Map<String, dynamic>? get userData => _userData;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Constructor - Check if user is already authenticated
  AuthService() {
    _checkAuthStatus();
  }

  // Check auth status from stored token
  Future<void> _checkAuthStatus() async {
    final token = await _storageService.getAuthToken();
    
    if (token != null && token.isNotEmpty) {
      try {
        // Validate token by fetching user profile
        final response = await _apiClient.get('/user/profile');
        _userData = response['data'];
        _status = AuthStatus.authenticated;
      } catch (e) {
        // Token might be invalid or expired
        await _storageService.clearTokens();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _errorMessage = null;
      
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response['success'] == true) {
        final accessToken = response['data']['access_token'];
        final refreshToken = response['data']['refresh_token'];
        
        // Save tokens
        await _storageService.setAuthToken(accessToken);
        await _storageService.setRefreshToken(refreshToken);
        
        // Save user data
        _userData = response['data']['user'];
        
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Unknown error occurred';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to sign in: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Register new user
  Future<bool> register(String name, String email, String password) async {
    try {
      _errorMessage = null;
      
      final response = await _apiClient.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      
      if (response['success'] == true) {
        // Auto sign-in after registration
        return await signInWithEmailAndPassword(email, password);
      } else {
        _errorMessage = response['message'] ?? 'Failed to register';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Call sign out endpoint if available
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Ignore errors during sign out
      if (kDebugMode) {
        print('Error during sign out: $e');
      }
    } finally {
      // Clear tokens and user data
      await _storageService.clearTokens();
      _userData = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.put('/user/profile', data: userData);
      
      if (response['success'] == true) {
        _userData = response['data'];
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update profile';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Profile update failed: ${e.toString()}';
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      final response = await _apiClient.post('/auth/reset-password', data: {
        'email': email,
      });
      
      return response['success'] == true;
    } catch (e) {
      _errorMessage = 'Password reset failed: ${e.toString()}';
      return false;
    }
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}