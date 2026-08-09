import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class Noticia {
  final int id;
  final String titular;
  final String contenido;
  final String urlImagen;
  final DateTime fecha;
  final String origen;

  const Noticia({
    required this.id,
    required this.titular,
    required this.contenido,
    required this.urlImagen,
    required this.fecha,
    required this.origen,
  });

  factory Noticia.fromJson(Map<String, dynamic> json) {
    final fecha = DateTime.tryParse(json['fecha']?.toString() ?? '');
    if (fecha == null) {
      throw const FormatException('La noticia no contiene una fecha válida');
    }

    return Noticia(
      id: json['id'] as int,
      titular: json['titular']?.toString() ?? '',
      contenido: json['contenido']?.toString() ?? '',
      urlImagen: json['url_imagen']?.toString() ?? '',
      fecha: fecha,
      origen: json['origen']?.toString() ?? '',
    );
  }

  static Future<List<Noticia>> getNoticias() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/noticias/'),
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data
            .map((noticia) => Noticia.fromJson(noticia as Map<String, dynamic>))
            .toList();
      }

      if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      }
      throw Exception('Error: ${response.statusCode}');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<String> generarResumen() async {
  final response = await http.get(
    Uri.parse('$apiBaseUrl/noticias/summary'),
  ).timeout(const Duration(seconds: 30), onTimeout: () {
    throw Exception('Tiempo de conexión agotado');
  });

  if (response.statusCode == 200) {
    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return data['resumen']?.toString() ?? '';
  }
  throw Exception('No se pudo generar el resumen (${response.statusCode})');
}
}
