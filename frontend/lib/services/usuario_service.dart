import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'auth_manager.dart';

class UsuarioService {
  //Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'contrasena': password,
        }),
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'] as String?;
        if (token == null || token.trim().isEmpty) {
          throw Exception('No se recibió un token de sesión válido');
        }
        AuthManager().setUser(data['usuario'] ?? data, token: token);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Email o contraseña incorrectos');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  //Registro
  static Future<Map<String, dynamic>> register(
    String email,
    String password,
    String nombre,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/usuarios/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'contrasena': password,
          'nombre': nombre,
        }),
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        throw Exception('Email ya registrado');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  //Actualizar perfil (nombre y/o email)
  static Future<Map<String, dynamic>> updateProfile(
    int userId, {
    String? nombre,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nombre != null) body['nombre'] = nombre;
      if (email != null) body['email'] = email;

      final response = await http.put(
        Uri.parse('$apiBaseUrl/usuarios/$userId'),
        headers: {'Content-Type': 'application/json', ...AuthManager().authHeaders},
        body: json.encode(body),
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AuthManager().setUser(data);
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else if (response.statusCode == 409) {
        throw Exception('Email ya registrado');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  //Cambiar contraseña
  static Future<void> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/usuarios/$userId/change-password'),
        headers: {'Content-Type': 'application/json', ...AuthManager().authHeaders},
        body: json.encode({
          'contrasena_actual': currentPassword,
          'contrasena_nueva': newPassword,
        }),
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        throw Exception('La contraseña actual es incorrecta');
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  //Logout
  static void logout() {
    AuthManager().logout();
  }
}
