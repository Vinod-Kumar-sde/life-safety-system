import 'dart:io';

class NetworkService {
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}