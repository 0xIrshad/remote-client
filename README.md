# Remote Client

<div align="left">

**A high-performance, enterprise-grade HTTP client package for Flutter/Dart**

[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)   [![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg)](https://flutter.dev/)   [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)



</div>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration Guide A-Z](#configuration-guide-a-z)
  - [Authentication](#authentication-configuration)
  - [Connectivity Service](#connectivity-service-configuration)
  - [Error Handling](#error-handling-configuration)
  - [Logging](#logging-configuration)
  - [Network Configuration](#network-configuration)
  - [Request Timeouts](#request-timeouts-configuration)
  - [Response Parsing](#response-parsing-configuration)
  - [Retry Policies](#retry-policies-configuration)
  - [Transformation Hooks](#transformation-hooks-configuration)
- [API Reference](#api-reference)
  - [HTTP Methods](#http-methods)
  - [File Operations](#file-operations)
  - [Error Handling](#error-handling)
  - [Request Cancellation](#request-cancellation)
- [Advanced Topics](#advanced-topics)
  - [Custom Components](#custom-components)
  - [Multi-Environment Setup](#multi-environment-setup)
  - [Performance Optimization](#performance-optimization)
  - [Testing](#testing)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)
- [License](#license)

---

## Overview

**Remote Client** is a production-ready HTTP client package built on Dio, designed for enterprise Flutter/Dart applications. It provides a comprehensive set of features including retry mechanisms, authentication, error handling, connectivity checking, and performance optimizations out of the box.

### Key Benefits

- ✅ **Zero External Dependencies** - Only depends on Dio (well-maintained, popular package)
- ✅ **Production-Ready** - Enterprise-grade features with sensible defaults
- ✅ **Type-Safe** - Full type safety with sealed classes and generics
- ✅ **Performance-Optimized** - Connection pooling, caching, and efficient algorithms
- ✅ **Highly Extensible** - Pluggable components following SOLID principles
- ✅ **Developer-Friendly** - Simple API with comprehensive documentation

### Architecture

The package follows **Clean Architecture** principles with clear separation of concerns:

- **Contracts** - Interfaces defining contracts for all components
- **Implementations** - Concrete implementations of contracts
- **Interceptors** - Cross-cutting concerns (auth, retry, logging, transformation)
- **Models** - Data structures and configuration models
- **Services** - Business logic services
- **Types** - Type definitions (Either monad, Failure types)

---

## Features

### Core Features

- ✅ **HTTP Methods** - GET, POST, PUT, PATCH, DELETE with full type safety
- ✅ **File Operations** - Upload (multipart) and download with progress tracking
- ✅ **Authentication** - Token-based authentication with refresh handling
- ✅ **Retry Mechanism** - Exponential backoff with jitter, configurable policies
- ✅ **Error Handling** - Type-safe error handling with sealed classes
- ✅ **Connectivity Checking** - Pre-request validation with TTL-based caching
- ✅ **Response Parsing** - Flexible parser system (default, direct, custom)
- ✅ **Request/Response Transformation** - Hooks for data transformation
- ✅ **Request Timeouts** - Per-request and global timeout configuration
- ✅ **Request Cancellation** - CancelToken support for request cancellation
- ✅ **Logging** - Structured logging with configurable levels
- ✅ **Request ID Tracking** - Unique IDs for debugging and correlation

### Performance Features

- ✅ **Connection Pooling** - Automatic connection pooling via Dio
- ✅ **Connectivity Caching** - TTL-based caching (default: 5 seconds)
- ✅ **Efficient Request IDs** - Timestamp + counter + random for uniqueness
- ✅ **Early Exits** - Connectivity check before requests

---

## Installation

### Add Dependency

```yaml
dependencies:
  remote_client:
    path: ../packages/remote_client  # For local development
  # Or from pub.dev when published:
  # remote_client: ^1.0.0
```

### Import

```dart
import 'package:remote_client/remote_client.dart';
```

### Requirements

- Dart SDK: `>=3.0.0 <4.0.0`
- Flutter: `>=3.0.0` (for Flutter projects)

---

## Quick Start

### Basic Usage

```dart
import 'package:remote_client/remote_client.dart';

// Create client with minimal configuration
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  enableLogging: true,
);

// Make a GET request
final result = await client.get('/users');

// Handle result using Either monad
result.fold(
  (failure) => print('Error: ${failure.errorMessage}'),
  (response) => print('Success: ${response.data}'),
);
```

### With Authentication

```dart
class MyTokenProvider implements TokenProvider {
  @override
  String? getAccessToken() => 'your-access-token';
  
  @override
  bool get hasValidToken => true;
}

class MyUnauthorizedHandler implements UnauthorizedHandler {
  @override
  Future<void> handleUnauthorized() async {
    // Handle unauthorized (e.g., navigate to login)
    print('Unauthorized - redirecting to login');
  }
}

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  tokenProvider: MyTokenProvider(),
  unauthorizedHandler: MyUnauthorizedHandler(),
);
```

### Builder Pattern

```dart
final client = RemoteClientFactory.builder()
  .baseUrl('https://api.example.com')
  .withAuth(
    tokenProvider: MyTokenProvider(),
    unauthorizedHandler: MyUnauthorizedHandler(),
  )
  .withRetry(RetryPolicy.aggressive)
  .withTransformationHooks(myHooks)
  .enableLogging()
  .build();
```

---

## Configuration Guide A-Z

### Authentication Configuration

#### Overview

Authentication is handled through the `TokenProvider` and `UnauthorizedHandler` interfaces, allowing complete customization of authentication logic.

#### Token Provider

**Purpose**: Provides access tokens for authenticated requests.

**Implementation**:

```dart
class SecureTokenProvider implements TokenProvider {
  final SecureStorage _storage;
  
  SecureTokenProvider(this._storage);
  
  @override
  String? getAccessToken() {
    // Retrieve token from secure storage
    return _storage.getAccessToken();
  }
  
  @override
  bool get hasValidToken {
    final token = getAccessToken();
    if (token == null) return false;
    
    // Check token expiration
    return !_isTokenExpired(token);
  }
  
  bool _isTokenExpired(String token) {
    // Implement token expiration check
    return false;
  }
}
```

**Usage**:

```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  tokenProvider: SecureTokenProvider(secureStorage),
  unauthorizedHandler: MyUnauthorizedHandler(),
);
```

#### Unauthorized Handler

**Purpose**: Handles 401 Unauthorized responses.

**Implementation**:

```dart
class AppUnauthorizedHandler implements UnauthorizedHandler {
  final AuthService _authService;
  final NavigationService _navigationService;
  
  AppUnauthorizedHandler(this._authService, this._navigationService);
  
  @override
  Future<void> handleUnauthorized() async {
    // Attempt token refresh
    final refreshed = await _authService.refreshToken();
    
    if (!refreshed) {
      // If refresh fails, navigate to login
      await _navigationService.navigateToLogin();
    }
  }
}
```

**Usage**:

```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  tokenProvider: MyTokenProvider(),
  unauthorizedHandler: AppUnauthorizedHandler(authService, navService),
);
```

#### Locale Support

Add locale header to all requests:

```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  tokenProvider: MyTokenProvider(),
  unauthorizedHandler: MyUnauthorizedHandler(),
  locale: 'en-US', // Adds 'locale: en-US' header
);
```

#### No Authentication

For public APIs without authentication:

```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  // TokenProvider and UnauthorizedHandler are optional
);
```

---

### Connectivity Service Configuration

#### Overview

The connectivity service checks internet connectivity before making requests, preventing unnecessary network calls.

#### Default Configuration

Uses multiple fallback hosts with DNS lookup:

```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  // Uses default ConnectivityServiceImpl with:
  // - Multiple fallback hosts (Google DNS, Cloudflare DNS, etc.)
  // - 3-second timeout per host
  // - 5-second cache TTL
);
```

#### Custom Hosts

```dart
final connectivity = ConnectivityServiceImpl.withHosts(
  [
    '8.8.8.8',           // Google DNS
    '1.1.1.1',           // Cloudflare DNS
    'your-api-host.com', // Your API host
  ],
  timeout: Duration(seconds: 3),
  cacheTTL: Duration(seconds: 10), // Custom cache duration
);

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  connectivityService: connectivity,
);
```

#### Custom Cache TTL

```dart
// Longer cache (10 seconds) - fewer connectivity checks
final connectivity = ConnectivityServiceImpl(
  cacheTTL: Duration(seconds: 10),
);

// Shorter cache (2 seconds) - more frequent checks
final connectivity = ConnectivityServiceImpl(
  cacheTTL: Duration(seconds: 2),
);

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  connectivityService: connectivity,
);
```

#### Disable Caching

For always-fresh connectivity checks:

```dart
final connectivity = ConnectivityServiceImpl.noCache();

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  connectivityService: connectivity,
);
```

#### Custom Connectivity Service

Implement your own connectivity checking logic:

```dart
class CustomConnectivityService implements ConnectivityService {
  @override
  Future<bool> isConnected() async {
    // Your custom connectivity check logic
    // e.g., check specific API endpoint
    try {
      final response = await http.get(Uri.parse('https://your-api.com/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  connectivityService: CustomConnectivityService(),
);
```

#### Clear Cache

Manually clear connectivity cache:

```dart
final connectivity = ConnectivityServiceImpl();
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  connectivityService: connectivity,
);

// Clear cache when needed
(connectivity as ConnectivityServiceImpl).clearCache();
```

---

### Error Handling Configuration

#### Overview

Error handling is type-safe using sealed classes. All errors are wrapped in `Either<Failure, BaseResponse<T>>` for functional error handling.

#### Error Types

The package provides comprehensive error types:

```dart
// Network Errors
ConnectionTimeout    // Connection timeout
SendTimeout         // Send timeout
ReceiveTimeout      // Receive timeout
ConnectionError     // Connection error
NoInternet          // No internet connection

// HTTP Errors
BadRequest          // 400 Bad Request
Unauthorized        // 401 Unauthorized
NotFound            // 404 Not Found
InternalServerError // 500 Internal Server Error
ServiceUnavailable  // 503 Service Unavailable
BadResponse         // Invalid response

// Other Errors
BadCertificate      // SSL/TLS certificate error
Cancelled           // Request cancelled
Unexpected          // Unexpected error
```

#### Basic Error Handling

```dart
final result = await client.get('/users');

result.fold(
  (failure) {
    switch (failure) {
      case ConnectionTimeout():
        print('Connection timeout: ${failure.errorMessage}');
      case NoInternet():
        print('No internet: ${failure.errorMessage}');
      case Unauthorized():
        print('Unauthorized: ${failure.errorMessage}');
      case NotFound():
        print('Not found: ${failure.errorMessage}');
      case InternalServerError():
        print('Server error: ${failure.errorMessage}');
      default:
        print('Error: ${failure.errorMessage}');
    }
  },
  (response) {
    print('Success: ${response.data}');
  },
);
```

#### Pattern Matching (Dart 3.0+)

```dart
final result = await client.get('/users');

result.fold(
  (failure) {
    final message = switch (failure) {
      ConnectionTimeout() => 'Connection timeout. Please try again.',
      NoInternet() => 'No internet connection. Please check your network.',
      Unauthorized() => 'Session expired. Please login again.',
      NotFound() => 'Resource not found.',
      InternalServerError() => 'Server error. Please try again later.',
      _ => 'An error occurred: ${failure.errorMessage}',
    };
    showErrorDialog(message);
  },
  (response) => handleSuccess(response),
);
```

#### Custom Error Handler

Implement custom error handling logic:

```dart
class CustomErrorHandler implements ErrorHandler {
  final AnalyticsService _analytics;
  
  CustomErrorHandler(this._analytics);
  
  @override
  Failure handleDioException(DioException exception) {
    // Log error to analytics
    _analytics.logError(exception);
    
    // Use default error handler
    final defaultHandler = ErrorHandlerImpl();
    return defaultHandler.handleDioException(exception);
  }
  
  @override
  Either<Failure, BaseResponse<T>> validateResponse<T>(BaseResponse<T> response) {
    // Custom validation logic
    if (response.statusCode == 200 && !response.success) {
      return Left(BadResponse(message: response.message ?? 'Request failed'));
    }
    
    // Use default validation
    final defaultHandler = ErrorHandlerImpl();
    return defaultHandler.validateResponse<T>(response);
  }
}

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  errorHandler: CustomErrorHandler(analyticsService),
);
```

#### Error Response Access

Access full error response data:

```dart
final result = await client.get('/users');

result.fold(
  (failure) {
    // Access response data if available
    final response = failure.response;
    if (response != null) {
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
    }
    
    print('Error: ${failure.errorMessage}');
  },
  (response) => handleSuccess(response),
);
```

---

### Logging Configuration

#### Overview

Structured logging with configurable log levels for debugging and monitoring.

#### Enable Logging

```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  enableLogging: true, // Enables debug-level logging
);
```

#### Log Levels

Configure log levels:

```dart
import 'package:remote_client/remote_client.dart';

// Debug logging (all requests, responses, errors, headers)
final debugClient = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  enableLogging: true,
);
// Default: LogLevel.debug

// Info logging (requests and responses only)
// Create client, then replace logging interceptor
final dio = Dio(); // Your Dio instance
dio.interceptors.removeWhere((i) => i is LoggingInterceptor);
dio.interceptors.add(LoggingInterceptor(
  enabled: true,
  minLogLevel: LogLevel.info,
));

// Error logging only (production)
dio.interceptors.removeWhere((i) => i is LoggingInterceptor);
dio.interceptors.add(LoggingInterceptor(
  enabled: true,
  minLogLevel: LogLevel.error,
));
```

#### Custom Logging

Implement custom logging:

```dart
final customLogger = LoggingInterceptor(
  enabled: true,
  minLogLevel: LogLevel.debug,
  logPrint: (message, level) {
    // Send to your logging service
    myLoggingService.log(
      message: message,
      level: level.name,
      timestamp: DateTime.now(),
    );
  },
);

// Add to Dio interceptors manually
dio.interceptors.add(customLogger);
```

#### Log Output Format

Logs include:
- Request ID: `[1234567890_0_1234]`
- HTTP Method: `GET`, `POST`, etc.
- URI: Full request URI
- Status Code: Response status code
- Headers: Request headers (debug level only)
- Error Details: Error messages and stack traces

Example log output:
```
→ [1234567890_0_1234] GET https://api.example.com/users
← [1234567890_0_1234] 200 GET https://api.example.com/users
✗ [1234567890_0_1234] connectionTimeout GET https://api.example.com/users - Connection timeout
```

---

### Network Configuration

#### Overview

Configure network timeouts, headers, and connection pooling.

#### Basic Configuration

```dart
final config = NetworkConfig(
  baseUrl: 'https://api.example.com',
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
  sendTimeout: Duration(seconds: 30),
);

final client = RemoteClientFactory.create(
  baseUrl: config.baseUrl,
  networkConfig: config,
);
```

#### Complete Configuration

```dart
final config = NetworkConfig(
  baseUrl: 'https://api.example.com',
  
  // Timeouts
  connectTimeout: Duration(seconds: 30),    // Connection establishment
  receiveTimeout: Duration(seconds: 60),    // Data reception
  sendTimeout: Duration(seconds: 30),       // Data sending
  
  // Headers
  defaultHeaders: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Client-Version': '1.0.0',
    'X-Platform': 'mobile',
  },
  
  // Connection Pooling
  maxConnectionsPerHost: 10,  // Connections per host
  enableHttp2: true,          // Enable HTTP/2
);

final client = RemoteClientFactory.create(
  baseUrl: config.baseUrl,
  networkConfig: config,
);
```

#### Connection Pooling

**Mobile Apps (Recommended)**:
```dart
final config = NetworkConfig(
  baseUrl: 'https://api.example.com',
  maxConnectionsPerHost: 5, // Optimal for mobile
);
```

**High-Traffic Apps**:
```dart
final config = NetworkConfig(
  baseUrl: 'https://api.example.com',
  maxConnectionsPerHost: 10, // More concurrent requests
);
```

**Low-Resource Environments**:
```dart
final config = NetworkConfig(
  baseUrl: 'https://api.example.com',
  maxConnectionsPerHost: 3, // Conservative
);
```

#### Custom Headers

```dart
final config = NetworkConfig(
  baseUrl: 'https://api.example.com',
  defaultHeaders: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': 'your-api-key',
    'X-Client-ID': 'mobile-app-v1',
  },
);
```

#### Update Configuration

```dart
final config = NetworkConfig(
  baseUrl: 'https://api.example.com',
);

// Update with new values
final updatedConfig = config.copyWith(
  connectTimeout: Duration(seconds: 60),
  defaultHeaders: {
    ...config.defaultHeaders,
    'X-New-Header': 'value',
  },
);
```

---

### Request Timeouts Configuration

#### Overview

Configure timeouts per request or globally. Useful for different request types (quick queries, file uploads, etc.).

#### Global Timeouts

Set in `NetworkConfig`:

```dart
final config = NetworkConfig(
  baseUrl: 'https://api.example.com',
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
  sendTimeout: Duration(seconds: 30),
);
```

#### Per-Request Timeouts

Use `RequestTimeoutConfig` presets:

```dart
// Quick operations (5 seconds)
final result = await client.get(
  '/users',
  timeout: RequestTimeoutConfig.quick,
);

// Normal operations (default)
final result = await client.get(
  '/users',
  timeout: RequestTimeoutConfig.normal,
);

// Extended operations (120 seconds)
final result = await client.get(
  '/large-dataset',
  timeout: RequestTimeoutConfig.extended,
);

// File upload (300s send, 30s receive)
final result = await client.multiPartPost(
  '/upload',
  data: formData,
  timeout: RequestTimeoutConfig.fileUpload,
);

// File download (30s send, 300s receive)
final result = await client.download(
  'https://api.example.com/file.pdf',
  '/path/to/save.pdf',
  timeout: RequestTimeoutConfig.fileDownload,
);
```

#### Custom Timeouts

```dart
final customTimeout = RequestTimeoutConfig(
  sendTimeout: Duration(seconds: 45),
  receiveTimeout: Duration(seconds: 90),
);

final result = await client.post(
  '/data',
  data: largeData,
  timeout: customTimeout,
);
```

#### Timeout from Milliseconds

```dart
final timeout = RequestTimeoutConfig.fromMilliseconds(
  sendTimeoutMs: 30000,
  receiveTimeoutMs: 60000,
);

final result = await client.get('/users', timeout: timeout);
```

---

### Response Parsing Configuration

#### Overview

Flexible response parsing system supporting different API response formats.

#### Default Parser (Wrapped Response)

For APIs with wrapped responses:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John"
  },
  "message": "Success",
  "meta": {
    "page": 1,
    "total": 100
  }
}
```

**Usage**:

```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  responseParser: DefaultResponseParser(),
);

// Or use default (DefaultResponseParser is the default)
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
);
```

**Custom Keys**:

```dart
final parser = DefaultResponseParser(
  dataKey: 'result',      // Default: 'data'
  successKey: 'ok',       // Default: 'success'
  messageKey: 'msg',      // Default: 'message'
  metaKey: 'metadata',    // Default: 'meta'
  defaultSuccess: true,   // Default success value if key missing
);

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  responseParser: parser,
);
```

#### Direct Parser (No Wrapper)

For APIs returning data directly:

```json
{
  "id": 1,
  "name": "John"
}
```

**Usage**:

```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  responseParser: DirectResponseParser(),
);
```

#### Custom Parser

Implement custom parsing logic:

```dart
class CustomResponseParser implements ResponseParser {
  @override
  BaseResponse<T> parse<T>(Response response, T Function(Object?)? fromJson) {
    final responseData = response.data;
    
    // Your custom parsing logic
    if (responseData is Map<String, dynamic>) {
      // Extract data from custom structure
      final data = responseData['payload']?['items'];
      final success = responseData['status'] == 'ok';
      final message = responseData['payload']?['message'];
      
      T? parsedData;
      if (data != null && fromJson != null) {
        parsedData = fromJson(data);
      }
      
      return BaseResponse<T>(
        statusCode: response.statusCode ?? 0,
        success: success,
        data: parsedData,
        message: message,
        meta: responseData['payload']?['meta'],
      );
    }
    
    // Fallback
    return BaseResponse<T>(
      statusCode: response.statusCode ?? 0,
      success: false,
      data: null,
      message: 'Invalid response format',
    );
  }
}

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  responseParser: CustomResponseParser(),
);
```

#### Type-Safe Parsing

Use `fromJson` for type-safe data parsing:

```dart
class User {
  final int id;
  final String name;
  
  User({required this.id, required this.name});
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

final result = await client.get<User>(
  '/users/1',
  fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
);

result.fold(
  (failure) => print('Error: ${failure.errorMessage}'),
  (response) {
    final user = response.data; // Type: User?
    print('User: ${user?.name}');
  },
);
```

---

### Retry Policies Configuration

#### Overview

Configurable retry mechanism with exponential backoff and jitter to handle transient failures.

#### Pre-Built Policies

**Default Policy (Balanced)**:
```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  retryPolicy: RetryPolicy.defaultPolicy,
  // - 3 retries max
  // - 1s initial delay
  // - 10s max delay
  // - Exponential backoff with jitter
  // - Retries on network errors, timeouts, 5xx errors
);
```

**Aggressive Policy (High Reliability)**:
```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  retryPolicy: RetryPolicy.aggressive,
  // - 5 retries max
  // - 500ms initial delay
  // - 30s max delay
  // - Includes 429 (Too Many Requests) in retryable codes
);
```

**Conservative Policy (Cost-Sensitive)**:
```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  retryPolicy: RetryPolicy.conservative,
  // - 1 retry only
  // - 2s initial delay
  // - 5s max delay
  // - Only retries on 503, 504 and connection errors
);
```

**No Retry**:
```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  retryPolicy: RetryPolicy.noRetry,
  // Disables retry mechanism
);
```

#### Custom Retry Policy

```dart
final customPolicy = RetryPolicy(
  maxRetries: 4,
  initialDelayMs: 500,
  maxDelayMs: 15000,
  backoffMultiplier: 2.5,
  useJitter: true,
  retryableStatusCodes: {500, 502, 503, 504, 429},
  retryOnConnectionError: true,
  retryOnTimeout: true,
  retryOnServerError: true,
  shouldRetry: (error) {
    // Custom retry logic
    if (error is DioException) {
      // Don't retry on 4xx errors except 429
      if (error.response?.statusCode != null) {
        final statusCode = error.response!.statusCode!;
        if (statusCode >= 400 && statusCode < 500 && statusCode != 429) {
          return false;
        }
      }
    }
    return true;
  },
);

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  retryPolicy: customPolicy,
);
```

#### Retry Policy Parameters

- `maxRetries`: Maximum number of retry attempts
- `initialDelayMs`: Initial delay before first retry (milliseconds)
- `maxDelayMs`: Maximum delay between retries (milliseconds)
- `backoffMultiplier`: Exponential backoff multiplier
- `useJitter`: Enable jitter to prevent thundering herd
- `retryableStatusCodes`: HTTP status codes that trigger retry
- `retryOnConnectionError`: Retry on connection errors
- `retryOnTimeout`: Retry on timeout errors
- `retryOnServerError`: Retry on 5xx server errors
- `shouldRetry`: Custom function to determine if error should be retried

---

### Transformation Hooks Configuration

#### Overview

Transform request data before sending and response data after receiving. Useful for encryption, decryption, data formatting, and field mapping.

#### Request Transformation

Transform data before sending:

```dart
final hooks = TransformationHooks(
  onRequestTransform: (endpoint, data, options) {
    // Example: Encrypt sensitive fields
    if (data is Map<String, dynamic>) {
      final transformed = <String, dynamic>{...data};
      
      // Encrypt password
      if (transformed.containsKey('password')) {
        transformed['password'] = encrypt(transformed['password']);
      }
      
      // Add timestamp
      transformed['timestamp'] = DateTime.now().toIso8601String();
      
      return transformed;
    }
    return data;
  },
);

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  transformationHooks: hooks,
);
```

#### Response Transformation

Transform data after receiving:

```dart
final hooks = TransformationHooks(
  onResponseTransform: (endpoint, response) {
    // Example: Decrypt response data
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final transformed = <String, dynamic>{...data};
      
      // Decrypt encrypted fields
      if (transformed.containsKey('encryptedData')) {
        transformed['data'] = decrypt(transformed['encryptedData']);
        transformed.remove('encryptedData');
      }
      
      return transformed;
    }
    return response.data;
  },
);

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  transformationHooks: hooks,
);
```

#### Combined Transformations

Use both request and response transformations:

```dart
final hooks = TransformationHooks(
  onRequestTransform: (endpoint, data, options) {
    // Normalize request data
    return normalizeRequestData(data);
  },
  onResponseTransform: (endpoint, response) {
    // Normalize response data
    return normalizeResponseData(response.data);
  },
);

final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  transformationHooks: hooks,
);
```

#### Conditional Transformations

Transform based on endpoint:

```dart
final hooks = TransformationHooks(
  onRequestTransform: (endpoint, data, options) {
    // Only encrypt sensitive endpoints
    if (endpoint.contains('/auth/') || endpoint.contains('/payment/')) {
      return encryptSensitiveData(data);
    }
    return data;
  },
  onResponseTransform: (endpoint, response) {
    // Only decrypt sensitive endpoints
    if (endpoint.contains('/auth/') || endpoint.contains('/payment/')) {
      return decryptSensitiveData(response.data);
    }
    return response.data;
  },
);
```

#### Field Mapping

Rename or restructure fields:

```dart
final hooks = TransformationHooks(
  onRequestTransform: (endpoint, data, options) {
    if (data is Map<String, dynamic>) {
      // Map fields to API format
      return {
        'user_name': data['username'],
        'user_email': data['email'],
        'user_password': data['password'],
      };
    }
    return data;
  },
  onResponseTransform: (endpoint, response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      // Map fields from API format
      return {
        'username': data['user_name'],
        'email': data['user_email'],
        'id': data['user_id'],
      };
    }
    return response.data;
  },
);
```

#### Builder Pattern

```dart
final client = RemoteClientFactory.builder()
  .baseUrl('https://api.example.com')
  .withTransformationHooks(
    TransformationHooks(
      onRequestTransform: (endpoint, data, options) => transformRequest(data),
      onResponseTransform: (endpoint, response) => transformResponse(response.data),
    ),
  )
  .build();
```

---

## API Reference

### HTTP Methods

#### GET Request

```dart
// Basic GET
final result = await client.get('/users');

// GET with query parameters
final result = await client.get(
  '/users',
  queryParams: {
    'page': 1,
    'limit': 20,
    'sort': 'name',
  },
);

// GET with type-safe parsing
final result = await client.get<User>(
  '/users/1',
  fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
);

// GET with timeout
final result = await client.get(
  '/users',
  timeout: RequestTimeoutConfig.quick,
);

// GET with cancellation
final cancelToken = CancelToken();
final result = await client.get(
  '/users',
  cancelToken: cancelToken,
);
// Cancel if needed
cancelToken.cancel('User cancelled');
```

#### POST Request

```dart
// Basic POST
final result = await client.post(
  '/users',
  data: {
    'name': 'John Doe',
    'email': 'john@example.com',
  },
);

// POST with type-safe parsing
final result = await client.post<User>(
  '/users',
  data: userData,
  fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
);

// POST with custom options
final result = await client.post(
  '/users',
  data: userData,
  options: Options(
    headers: {'X-Custom-Header': 'value'},
  ),
);
```

#### PUT Request

```dart
final result = await client.put(
  '/users/1',
  data: {
    'name': 'Jane Doe',
    'email': 'jane@example.com',
  },
);
```

#### PATCH Request

```dart
final result = await client.patch(
  '/users/1',
  data: {
    'name': 'Jane Doe', // Partial update
  },
);
```

#### DELETE Request

```dart
final result = await client.delete('/users/1');
```

---

### File Operations

#### File Upload (Multipart POST)

```dart
import 'package:dio/dio.dart';

// Single file upload
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(
    '/path/to/file.pdf',
    filename: 'document.pdf',
  ),
  'description': 'Document description',
});

final result = await client.multiPartPost(
  '/upload',
  data: formData,
  onSendProgress: (sent, total) {
    final percent = (sent / total * 100).toStringAsFixed(0);
    print('Upload progress: $percent%');
  },
  timeout: RequestTimeoutConfig.fileUpload,
);

// Multiple files upload
final formData = FormData.fromMap({
  'files': [
    await MultipartFile.fromFile('/path/to/file1.pdf'),
    await MultipartFile.fromFile('/path/to/file2.jpg'),
  ],
  'title': 'Multiple files',
});

final result = await client.multiPartPost('/upload', data: formData);
```

#### File Upload (Multipart PATCH)

```dart
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile('/path/to/file.pdf'),
});

final result = await client.multiPartPatch(
  '/files/1',
  data: formData,
  onSendProgress: (sent, total) {
    print('Progress: ${(sent / total * 100).toStringAsFixed(0)}%');
  },
);
```

#### File Download

```dart
final result = await client.download(
  'https://api.example.com/files/document.pdf',
  '/path/to/save/document.pdf',
  onReceiveProgress: (received, total) {
    if (total != -1) {
      final percent = (received / total * 100).toStringAsFixed(0);
      print('Download progress: $percent%');
    } else {
      print('Downloaded: ${received} bytes');
    }
  },
  timeout: RequestTimeoutConfig.fileDownload,
);

result.fold(
  (failure) => print('Download failed: ${failure.errorMessage}'),
  (response) => print('Download completed'),
);
```

---

### Error Handling

See [Error Handling Configuration](#error-handling-configuration) for detailed error handling examples.

---

### Request Cancellation

```dart
import 'package:dio/dio.dart';

// Create cancel token
final cancelToken = CancelToken();

// Start request
final future = client.get(
  '/users',
  cancelToken: cancelToken,
);

// Cancel request
cancelToken.cancel('User cancelled operation');

// Handle cancellation
final result = await future;
result.fold(
  (failure) {
    if (failure is Cancelled) {
      print('Request was cancelled: ${failure.errorMessage}');
    } else {
      print('Error: ${failure.errorMessage}');
    }
  },
  (response) => print('Success: ${response.data}'),
);
```

**Use Cases**:
- Cancel requests when user navigates away
- Cancel requests when new search is initiated
- Cancel long-running requests on user action

---

## Advanced Topics

### Custom Components

#### Custom Token Provider

See [Authentication Configuration](#authentication-configuration) for examples.

#### Custom Error Handler

See [Error Handling Configuration](#error-handling-configuration) for examples.

#### Custom Response Parser

See [Response Parsing Configuration](#response-parsing-configuration) for examples.

#### Custom Connectivity Service

See [Connectivity Service Configuration](#connectivity-service-configuration) for examples.

---

### Multi-Environment Setup

#### Environment-Based Configuration

```dart
enum Environment { dev, staging, prod }

class AppConfig {
  static Environment get environment {
    // Determine environment from build config or environment variable
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    return Environment.values.firstWhere(
      (e) => e.name == env,
      orElse: () => Environment.dev,
    );
  }
  
  static String get baseUrl {
    switch (environment) {
      case Environment.dev:
        return 'https://dev-api.example.com';
      case Environment.staging:
        return 'https://staging-api.example.com';
      case Environment.prod:
        return 'https://api.example.com';
    }
  }
  
  static RetryPolicy get retryPolicy {
    switch (environment) {
      case Environment.dev:
        return RetryPolicy.conservative; // Fewer retries in dev
      case Environment.staging:
      case Environment.prod:
        return RetryPolicy.defaultPolicy;
    }
  }
  
  static bool get enableLogging {
    return environment != Environment.prod;
  }
}

// Create client with environment-specific config
final client = RemoteClientFactory.create(
  baseUrl: AppConfig.baseUrl,
  retryPolicy: AppConfig.retryPolicy,
  enableLogging: AppConfig.enableLogging,
);
```

#### Dependency Injection

```dart
// Using Riverpod
final remoteClientProvider = Provider<RemoteClient>((ref) {
  final config = ref.watch(appConfigProvider);
  
  return RemoteClientFactory.create(
    baseUrl: config.baseUrl,
    tokenProvider: ref.watch(tokenProviderProvider),
    unauthorizedHandler: ref.watch(unauthorizedHandlerProvider),
    retryPolicy: config.retryPolicy,
    enableLogging: config.enableLogging,
  );
});
```

---

### Performance Optimization

#### Connection Pooling

See [Network Configuration](#network-configuration) for connection pooling details.

#### Connectivity Caching

See [Connectivity Service Configuration](#connectivity-service-configuration) for caching options.

#### Request Batching

For multiple requests, consider batching:

```dart
// Instead of sequential requests
final user1 = await client.get('/users/1');
final user2 = await client.get('/users/2');
final user3 = await client.get('/users/3');

// Use Future.wait for parallel requests
final results = await Future.wait([
  client.get('/users/1'),
  client.get('/users/2'),
  client.get('/users/3'),
]);
```

#### Request ID Optimization

Disable request ID tracking if not needed:

```dart
// Request IDs are enabled by default
// They can be disabled for performance (not recommended for production)
// This is handled internally and cannot be disabled via public API
// as it's essential for debugging and error tracking
```

---

### Testing

#### Mock Client for Testing

```dart
class MockRemoteClient implements RemoteClient {
  @override
  Future<Either<Failure, BaseResponse<T>>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    // Return mock response
    return Right(BaseResponse<T>(
      statusCode: 200,
      success: true,
      data: mockData,
    ));
  }
  
  // Implement other methods...
}
```

#### Test Utilities

```dart
// Test helper for creating test clients
RemoteClient createTestClient({
  String baseUrl = 'https://test-api.example.com',
  bool enableLogging = false,
}) {
  return RemoteClientFactory.create(
    baseUrl: baseUrl,
    enableLogging: enableLogging,
    retryPolicy: RetryPolicy.noRetry, // No retries in tests
  );
}
```

---

## Best Practices

### 1. Error Handling

✅ **Do**: Use pattern matching for type-safe error handling
```dart
result.fold(
  (failure) => handleError(failure),
  (response) => handleSuccess(response),
);
```

❌ **Don't**: Ignore errors or use try-catch unnecessarily
```dart
// Don't do this
try {
  final result = await client.get('/users');
  // ...
} catch (e) {
  // Either monad handles errors, no need for try-catch
}
```

### 2. Authentication

✅ **Do**: Implement proper token refresh logic
```dart
class SecureTokenProvider implements TokenProvider {
  Future<void> refreshToken() async {
    // Refresh token logic
  }
}
```

❌ **Don't**: Hardcode tokens or store them insecurely

### 3. Configuration

✅ **Do**: Use builder pattern for complex configurations
```dart
final client = RemoteClientFactory.builder()
  .baseUrl(baseUrl)
  .withAuth(...)
  .withRetry(...)
  .build();
```

❌ **Don't**: Create multiple client instances unnecessarily

### 4. Logging

✅ **Do**: Use appropriate log levels for different environments
```dart
final client = RemoteClientFactory.create(
  baseUrl: baseUrl,
  enableLogging: !kReleaseMode, // Disable in production
);
```

❌ **Don't**: Log sensitive data (tokens, passwords)

### 5. Timeouts

✅ **Do**: Use appropriate timeouts for different operations
```dart
// Quick operations
client.get('/status', timeout: RequestTimeoutConfig.quick);

// File operations
client.download(url, path, timeout: RequestTimeoutConfig.fileDownload);
```

❌ **Don't**: Use very long timeouts for all requests

### 6. Retry Policies

✅ **Do**: Choose retry policy based on use case
```dart
// Critical operations
retryPolicy: RetryPolicy.aggressive

// Non-critical operations
retryPolicy: RetryPolicy.conservative
```

❌ **Don't**: Retry on all errors (4xx client errors should not be retried)

---

## Troubleshooting

### Common Issues

#### 1. Connection Timeout

**Problem**: Requests timeout frequently

**Solutions**:
- Increase timeout values in `NetworkConfig`
- Check network connectivity
- Verify server is reachable
- Check firewall/proxy settings

```dart
final config = NetworkConfig(
  baseUrl: baseUrl,
  connectTimeout: Duration(seconds: 60),
  receiveTimeout: Duration(seconds: 60),
);
```

#### 2. Unauthorized Errors

**Problem**: Getting 401 Unauthorized errors

**Solutions**:
- Verify token provider is working correctly
- Check token expiration
- Implement proper token refresh in `UnauthorizedHandler`
- Verify token format matches API expectations

#### 3. Connectivity Check Failing

**Problem**: Connectivity check always returns false

**Solutions**:
- Check if DNS hosts are reachable
- Increase timeout for connectivity check
- Use custom connectivity service
- Disable connectivity check if not needed

```dart
final connectivity = ConnectivityServiceImpl(
  timeout: Duration(seconds: 5),
  cacheTTL: Duration(seconds: 10),
);
```

#### 4. Response Parsing Errors

**Problem**: Data parsing fails

**Solutions**:
- Verify response format matches parser expectations
- Use custom parser for non-standard formats
- Check `fromJson` function implementation
- Verify response data structure

#### 5. Retry Not Working

**Problem**: Requests not retrying on failure

**Solutions**:
- Verify retry policy is configured
- Check if error is retryable (4xx errors are not retried by default)
- Use custom `shouldRetry` function
- Check retry policy parameters

---

## Examples

### Complete Enterprise Setup

```dart
import 'package:remote_client/remote_client.dart';

class EnterpriseRemoteClient {
  static RemoteClient create({
    required String baseUrl,
    required TokenProvider tokenProvider,
    required UnauthorizedHandler unauthorizedHandler,
    Environment environment = Environment.prod,
  }) {
    return RemoteClientFactory.builder()
      .baseUrl(baseUrl)
      .withNetworkConfig(
        NetworkConfig(
          baseUrl: baseUrl,
          connectTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 60),
          sendTimeout: Duration(seconds: 30),
          maxConnectionsPerHost: 10,
          defaultHeaders: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-Client-Version': '1.0.0',
          },
        ),
      )
      .withAuth(
        tokenProvider: tokenProvider,
        unauthorizedHandler: unauthorizedHandler,
        locale: 'en-US',
      )
      .withRetry(environment == Environment.prod 
        ? RetryPolicy.defaultPolicy 
        : RetryPolicy.conservative)
      .withTransformationHooks(
        TransformationHooks(
          onRequestTransform: (endpoint, data, options) {
            // Add request metadata
            if (data is Map<String, dynamic>) {
              return {
                ...data,
                'requestId': DateTime.now().millisecondsSinceEpoch,
              };
            }
            return data;
          },
        ),
      )
      .withConnectivityService(
        ConnectivityServiceImpl(
          cacheTTL: Duration(seconds: 5),
        ),
      )
      .enableLogging(environment != Environment.prod)
      .build();
  }
}
```

### Repository Pattern with Remote Client

```dart
class UserRepository {
  final RemoteClient _client;
  
  UserRepository(this._client);
  
  Future<Either<Failure, List<User>>> getUsers({
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _client.get<List<User>>(
      '/users',
      queryParams: {
        'page': page,
        'limit': limit,
      },
      fromJson: (json) {
        if (json is List) {
          return json.map((item) => User.fromJson(item as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    
    return result.fold(
      (failure) => Left(failure),
      (response) => Right(response.data ?? []),
    );
  }
  
  Future<Either<Failure, User>> createUser(User user) async {
    final result = await _client.post<User>(
      '/users',
      data: user.toJson(),
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
    
    return result.fold(
      (failure) => Left(failure),
      (response) => Right(response.data!),
    );
  }
}
```

---

## License

MIT License - see LICENSE file for details.

---

## Support

For issues, questions, or contributions, please open an issue on the repository.

---

**Made with ❤️ for the Flutter/Dart community**
