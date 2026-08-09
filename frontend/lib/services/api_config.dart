import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

const Duration requestTimeout = Duration(seconds: 10);
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
final String apiBaseUrl = _getBaseUrl();

String _getBaseUrl() {
  if (_apiBaseUrlOverride.isNotEmpty) {
    return _apiBaseUrlOverride;
  }
  if (kIsWeb) {
    return 'http://localhost:8000/api/v1';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000/api/v1';
  }
  return 'http://localhost:8000/api/v1';
}
