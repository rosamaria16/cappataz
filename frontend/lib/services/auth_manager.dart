class AuthManager {
  static final AuthManager _instance = AuthManager._internal();

  factory AuthManager() {
    return _instance;
  }

  AuthManager._internal();

  Map<String, dynamic>? _currentUser;
  String? _token;

  bool get isLoggedIn =>
      _currentUser != null && _token != null && _token!.trim().isNotEmpty;

  bool get isAdmin => _currentUser != null && _currentUser!['admin'] == 1;
  
  Map<String, dynamic>? get currentUser => _currentUser;

  String? get token => _token;

  void setUser(Map<String, dynamic> userData, {String? token}) {
    _currentUser = userData;
    if (token != null) {
      _token = token;
    }
  }

  Map<String, String> get authHeaders {
    if (_token == null) return {};
    return {'Authorization': 'Bearer $_token'};
  }

  void logout() {
    _currentUser = null;
    _token = null;
  }
}
