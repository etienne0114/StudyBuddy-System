// This is a simplified version that doesn't rely on code generation
// Replace generated methods with manual serialization/deserialization

/// Base API response model for all API responses
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
  });

  // Manual fromJson implementation
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null && fromJsonT != null 
          ? fromJsonT(json['data']) 
          : null,
      meta: json['meta'] != null 
          ? Map<String, dynamic>.from(json['meta'] as Map) 
          : null,
    );
  }
  
  // Manual toJson implementation
  Map<String, dynamic> toJson([dynamic Function(T)? toJsonT]) {
    return {
      'success': success,
      'message': message,
      if (data != null && toJsonT != null) 'data': toJsonT(data as T),
      if (meta != null) 'meta': meta,
    };
  }
}

/// API error model
class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  
  ApiError({
    required this.code,
    required this.message,
    this.details,
  });
  
  // Manual fromJson implementation
  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] != null 
          ? Map<String, dynamic>.from(json['details'] as Map) 
          : null,
    );
  }
  
  // Manual toJson implementation
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      if (details != null) 'details': details,
    };
  }
}

/// Authentication response model
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final Map<String, dynamic> user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });
  
  // Manual fromJson implementation
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: json['expires_in'] as int,
      user: Map<String, dynamic>.from(json['user'] as Map),
    );
  }
  
  // Manual toJson implementation
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user,
    };
  }
}

/// User profile model
class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
  });
  
  // Manual fromJson implementation
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      preferences: json['preferences'] != null 
          ? Map<String, dynamic>.from(json['preferences'] as Map) 
          : null,
    );
  }
  
  // Manual toJson implementation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (avatar != null) 'avatar': avatar,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (preferences != null) 'preferences': preferences,
    };
  }
}

/// Pagination metadata model
class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });
  
  // Manual fromJson implementation
  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
      from: json['from'] as int?,
      to: json['to'] as int?,
    );
  }
  
  // Manual toJson implementation
  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
  }
}

/// Study material category model
class MaterialCategory {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final int materialsCount;
  
  MaterialCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.materialsCount,
  });
  
  // Manual fromJson implementation
  factory MaterialCategory.fromJson(Map<String, dynamic> json) {
    return MaterialCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      materialsCount: json['materials_count'] as int,
    );
  }
  
  // Manual toJson implementation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      'materials_count': materialsCount,
    };
  }
}