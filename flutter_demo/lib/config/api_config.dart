import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) return 'http://localhost:5000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // For Android emulator, use 10.0.2.2 to access host machine's localhost
        // For real device, you need to use your computer's IP address on the local network
        // To find your IP: Windows: ipconfig, Mac/Linux: ifconfig
        // Look for IPv4 Address (usually starts with 192.168.x.x or 10.x.x.x)
        // Example: 'http://192.168.1.100:5000'
        // 
        // Default to localhost - UPDATE THIS with your computer's local IP address
        // when building for physical devices, or pass via:
        // flutter build apk --release --dart-define=API_BASE_URL=http://YOUR_IP:5000
        // Use your computer's local IP address for physical devices
        // Your current IP: 192.168.4.89 (update if your IP changes)
        const defaultAndroidUrl = String.fromEnvironment('ANDROID_API_URL', defaultValue: 'http://192.168.4.89:5000');
        return defaultAndroidUrl;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'http://localhost:5000';
      default:
        return 'http://localhost:5000';
    }
  }
}

