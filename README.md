# Remote Client

[![Pub](https://img.shields.io/pub/v/remote_client.svg)](https://pub.dev/packages/remote_client) [![Pub Points](https://img.shields.io/pub/points/remote_client.svg)](https://pub.dev/packages/remote_client/score) [![Pub Likes](https://img.shields.io/pub/likes/remote_client.svg)](https://pub.dev/packages/remote_client) [![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE) [![GitHub](https://img.shields.io/badge/GitHub-0xIrshad%2Fremote--client-181717.svg?logo=github)](https://github.com/0xIrshad/remote-client)

Remote Client is a Dio-powered HTTP client for Dart and Flutter that packages retry logic, authentication, structured errors, connectivity checks, and logging into one cohesive API. Configure once, reuse anywhere, and keep network code predictable across your app.

---

## Features at a Glance
- HTTP verbs (GET/POST/PUT/PATCH/DELETE) with typed responses
- Multipart upload, streaming download, and cancellation support
- Token-based auth with refresh handling and request transformation hooks
- Retry policies with exponential backoff + jitter
- Connectivity service with configurable caching and fallbacks
- Clean `Either<Failure, BaseResponse<T>>` error model with sealed failures
- No external dependencies besides Dio

---

dependencies:
  remote_client: ^1.0.0
```

```dart
import 'package:remote_client/remote_client.dart';

---

## Quick Start

### Minimal client

```dart
final client = RemoteClientFactory.create(
  baseUrl: 'https://api.example.com',
  enableLogging: true,
);

final result = await client.get('/users');

result.fold(
  (failure) => debugPrint('Error: ${failure.errorMessage}'),
  (response) => debugPrint('Success: ${response.data}'),
);
```

### Authenticated client with retry

```dart
class MyTokenProvider implements TokenProvider {
  @override
  String? getAccessToken() => secureStorage.read('token');
  
  @override
  bool get hasValidToken => getAccessToken()?.isNotEmpty == true;
}

class MyUnauthorizedHandler implements UnauthorizedHandler {
  @override
  Future<void> handleUnauthorized() async => authService.refreshOrSignOut();
}

final client = RemoteClientFactory.builder()
  .baseUrl('https://api.example.com')
  .withAuth(
    tokenProvider: MyTokenProvider(),
    unauthorizedHandler: MyUnauthorizedHandler(),
    locale: 'en-US',
  )
  .withRetry(RetryPolicy.defaultPolicy)
  .enableLogging()
  .build();
```

---

## Core API Essentials

| Component | Purpose |
| --- | --- |
| `RemoteClientFactory` | Fluent builder to assemble clients with auth, retry, logging, connectivity, and hooks. |
| `RemoteClient` | Typed request methods (`get`, `post`, `put`, `patch`, `delete`, `multiPartPost`, `download`). |
| `BaseResponse<T>` | Structured response data (`data`, `statusCode`, `message`, `meta`). |
| `Failure` | Exhaustive sealed errors (timeouts, network, HTTP codes, cancellations, unexpected). |
| `NetworkConfig` | Base URL, timeouts, headers, connection pooling. |
| `RetryPolicy` | Prebuilt or custom retry rules (max attempts, backoff, jitter, retryable codes). |
| `RequestTimeoutConfig` | Global or per-request timeout presets (quick, normal, extended, file upload/download). |
| `TransformationHooks` | Modify request payloads and responses (encryption, mapping, normalization). |
| `ResponseParser` | Default, direct, or custom parsers for various API payload shapes. |
| `ConnectivityService` | Lightweight connectivity checks with TTL caching and custom hosts. |

> [!TIP]
> All request methods return `Future<Either<Failure, BaseResponse<T>>>`, making success/error handling explicit and testable.

---

## Everyday Usage Patterns

### Typed GET with query params

```dart
final users = await client.get<List<User>>(
  '/users',
  queryParams: {'page': 1, 'limit': 20},
  fromJson: (json) => (json as List)
      .map((item) => User.fromJson(item as Map<String, dynamic>))
      .toList(),
);
```

### POST with custom headers and timeout

```dart
await client.post(
  '/users',
  data: {'name': 'Ada Lovelace'},
  options: Options(headers: {'X-Client': 'mobile'}),
  timeout: RequestTimeoutConfig.quick,
);
```

### Multipart upload & download

```dart
final upload = await client.multiPartPost(
  '/files',
  data: FormData.fromMap({
    'file': await MultipartFile.fromFile(path, filename: 'doc.pdf'),
  }),
  onSendProgress: (sent, total) => debugPrint('$sent / $total'),
  timeout: RequestTimeoutConfig.fileUpload,
);

final download = await client.download(
  'https://example.com/report.pdf',
  '/local/report.pdf',
  onReceiveProgress: (received, total) => debugPrint('$received / $total'),
  timeout: RequestTimeoutConfig.fileDownload,
);
```

---

## Advanced Configuration (Essentials Only)

- **Authentication**
  - Provide a `TokenProvider` to inject tokens.
  - Implement `UnauthorizedHandler` for refresh flows or sign-out.
  - Optional `locale` header per request.

- **Connectivity**
  - `ConnectivityServiceImpl` with default DNS hosts and cache TTL.
  - `ConnectivityServiceImpl.withHosts([...])` for custom probes.
  - Call `clearCache()` to force re-checks.

- **Retry Policies**
  - `RetryPolicy.defaultPolicy`, `aggressive`, `conservative`, or `noRetry`.
  - Override parameters (max retries, delays, jitter, status codes, predicates).

- **Response Parsing**
  - `DefaultResponseParser` for wrapped payloads (`{success, data, message, meta}`).
  - `DirectResponseParser` for bare JSON objects.
  - Implement `ResponseParser` to handle custom envelopes.

- **Transformation Hooks**
  - `TransformationHooks(onRequestTransform: ..., onResponseTransform: ...)` to encrypt, normalize, or map fields.
  - Hooks are invoked per request with endpoint context.

- **Logging**
  - Enable via factory (`enableLogging()`).
  - Swap `LoggingInterceptor` for custom log sinks or levels.

- **Timeouts**
  - Configure defaults with `NetworkConfig`.
  - Use presets (`quick`, `normal`, `extended`, `fileUpload`, `fileDownload`) or build custom via `RequestTimeoutConfig`.

For a complete guided setup, check the example app in `example/lib/main.dart`.

---

## Testing Tips

```dart
RemoteClient createTestClient() => RemoteClientFactory.create(
      baseUrl: 'https://test-api.example.com',
      retryPolicy: RetryPolicy.noRetry,
      enableLogging: false,
);
```

Mock `RemoteClient` or the underlying contracts (`TokenProvider`, `ConnectivityService`, `ResponseParser`) to isolate units in your tests.

---

## Resources
- [Documentation](https://github.com/0xIrshad/remote-client#readme)
- [Example App](example/lib/main.dart)
- [Issue Tracker](https://github.com/0xIrshad/remote-client/issues)

---

## Contributing & License
Contributions are welcome—open an issue or pull request with your proposal. Make sure tests pass and include coverage for new behavior.

Licensed under the [MIT License](LICENSE).
