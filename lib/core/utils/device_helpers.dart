import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// Device and network information helpers
/// Extracted from UserService for reusability
class DeviceHelpers {
  /// Get detailed device information
  static Future<String> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        return 'Windows: ${info.computerName}';
      } else if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return 'Android: ${info.model} (${info.manufacturer})';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return 'iOS: ${info.name} (${info.model})';
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        return 'macOS: ${info.computerName}';
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        return 'Linux: ${info.name}';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Get IP address
  static Future<String> getIpAddress() async {
    try {
      final networkInfo = NetworkInfo();
      final wifiIP = await networkInfo.getWifiIP();
      return wifiIP ?? 'Unknown IP';
    } catch (e) {
      return 'Unknown IP';
    }
  }
}
