import 'package:remote_client/src/contracts/file_client.dart';
import 'package:remote_client/src/contracts/http_client.dart';

/// Combined interface for clients that need both HTTP and file operations
/// Follows composition over inheritance principle
abstract class RemoteClient implements HttpClient, FileClient {
  // This interface combines both contracts for full functionality
  // Clients can depend on just HttpClient or FileClient if they don't need both
}
