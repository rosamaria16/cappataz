import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'auth_manager.dart';

class AdminService {

  static Map<String, String> get _authHeaders => {
    ...AuthManager().authHeaders,
  };

  static Future<List<Map<String, dynamic>>> getDias() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/admin/dias'),
        headers: _authHeaders,
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos de administrador');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> actualizarFechasDesdeInicio(
    String fechaInicio,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/admin/dias/fecha-inicio'),
        headers: {'Content-Type': 'application/json', ..._authHeaders},
        body: json.encode({'fecha_inicio': fechaInicio}),
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos de administrador');
      } else if (response.statusCode == 404) {
        throw Exception('No hay días configurados');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> uploadInfopasosCsv(
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      final uri = Uri.parse(
        '$apiBaseUrl/admin/upload-infopasos',
      );
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_authHeaders);
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de conexión agotado');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['detail'] ?? 'Error en el archivo CSV');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos de administrador');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> uploadHermandadesCsv(
    List<int> fileBytes,
    String fileName,
  ) async {
    try {
      final uri = Uri.parse(
        '$apiBaseUrl/admin/upload-hermandades',
      );
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_authHeaders);
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Tiempo de conexión agotado');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['detail'] ?? 'Error en el archivo CSV');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos de administrador');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<void> deleteNoticia(int noticiaId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/noticias/$noticiaId'),
        headers: _authHeaders,
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Debes iniciar sesión como administrador');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos de administrador');
      } else if (response.statusCode == 404) {
        throw Exception('La noticia ya no existe');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> regenerarResumen() async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/noticias/regenerar-resumen'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 60), onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Debes iniciar sesión como administrador');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos de administrador');
      } else if (response.statusCode == 502) {
        throw Exception('Error al generar el resumen con la IA');
      } else if (response.statusCode == 503) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(data['detail'] ?? 'El servicio de IA no está disponible');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
