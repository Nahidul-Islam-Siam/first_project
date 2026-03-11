import 'dart:io';

class NetworkUtils {
  const NetworkUtils._();

  static Future<bool> hasInternet({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    // DNS + outbound check to avoid firing Firebase/Google network calls blindly.
    const hosts = ['google.com', 'firebase.google.com', 'one.one.one.one'];
    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(host).timeout(timeout);
        if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException {
        // Try next host.
      } on OSError {
        // Try next host.
      } catch (_) {
        // Try next host.
      }
    }
    return false;
  }
}
