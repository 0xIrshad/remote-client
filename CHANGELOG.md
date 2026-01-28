# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1-dev.3] - 2025-11-07

### Fixed
- Replaced direct `dart:io` usage with conditional exports to fully isolate IO-specific connectivity logic.
- Added a web/WASM-safe connectivity implementation that avoids socket calls while preserving the public API.

## [0.0.1-dev.2] - 2025-11-07

### Fixed
- Restored WASM compatibility by avoiding direct `dart:io` imports and adding conditional stubs for connectivity checks.
- Updated `pubspec.yaml` metadata with the live repository URL to satisfy publish validation.

### Documentation
- Added API documentation for `AuthInterceptor` and all failure types to improve publish scores.

## [0.0.1-dev.1] - 2024-12-XX

### Added
- Pre-release version for testing
- Initial release of Remote Client package
- HTTP client implementation built on Dio
- Support for all HTTP methods (GET, POST, PUT, PATCH, DELETE)
- File upload and download operations with progress tracking
- Token-based authentication with automatic token injection
- Retry mechanism with exponential backoff and jitter
- Configurable retry policies
- Comprehensive error handling with type-safe failure types
- Connectivity checking service with TTL-based caching
- Flexible response parsing system (default, direct, custom parsers)
- Request/response transformation hooks
- Per-request and global timeout configuration
- Request cancellation support via CancelToken
- Structured logging with configurable levels
- Request ID tracking for debugging and correlation
- Clean architecture with contract-based design
- Highly extensible with pluggable components
- Comprehensive documentation and examples
- Type-safe API using Either monad pattern
- Connection pooling for performance optimization

### Technical Details
- Built on Dio 5.9.0
- Dart SDK: ^3.9.2
- Flutter: >=1.17.0
- Zero external dependencies (only Dio)
- Production-ready with enterprise-grade features

## [1.0.0] - 2026-01-28

### Added
- **New Interceptors**: Added `CacheInterceptor` for flexible caching strategies and `DeduplicationInterceptor` to prevent duplicate parallel requests.
- **Linting**: Integrated `very_good_analysis` for stricter code quality rules.

### Enhanced
- **Either Monad**: Significantly expanded `Either` type with functional operators including `map`, `flatMap`, `getOrElse`, `fold`, `tap`, and `swap` for robust error handling chaining.
- **Type Safety**: Improved `ResponseParser` implementation with stricter type checking and error handling during JSON parsing.
- **Observability**: Enhanced error logging to include Request ID context for better debugging.

### Maintenance
- **Dependencies**: Updated `dio` to `^5.9.1`.
