import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'dia_service.dart';
import 'hermandad_service.dart';
import 'info_paso_service.dart';
import '../utils/hora_utils.dart';
import '../utils/franja_horaria_utils.dart';
import 'auth_manager.dart';

class ItinerarioApi {
  static Future<Map<String, dynamic>> getOrCreateByUsuario(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/itinerarios/usuario/$userId'),
        headers: AuthManager().authHeaders,
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        final createResponse = await http.post(
          Uri.parse('$apiBaseUrl/itinerarios/'),
          headers: {'Content-Type': 'application/json', ...AuthManager().authHeaders},
          body: json.encode({'idUsuario': userId}),
        ).timeout(requestTimeout, onTimeout: () {
          throw Exception('Tiempo de conexión agotado');
        });

        if (createResponse.statusCode == 201) {
          final data = json.decode(createResponse.body);
          data['items'] = [];
          return data;
        }
        if (createResponse.statusCode == 409) {
          final existingResponse = await http.get(
            Uri.parse('$apiBaseUrl/itinerarios/usuario/$userId'),
            headers: AuthManager().authHeaders,
          ).timeout(requestTimeout);
          if (existingResponse.statusCode == 200) {
            return json.decode(existingResponse.body);
          }
        }
        throw Exception('Error al crear itinerario');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> addItem(int itinerarioId, int idInfoPaso) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/itinerarios/$itinerarioId/items'),
        headers: {'Content-Type': 'application/json', ...AuthManager().authHeaders},
        body: json.encode({'idInfoPaso': idInfoPaso}),
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 409) {
        throw Exception('El elemento ya está en el itinerario');
      } else if (response.statusCode == 404) {
        throw Exception('El itinerario o el dato seleccionado ya no existe');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<void> removeItem(int itinerarioId, int itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/itinerarios/$itinerarioId/items/$itemId'),
        headers: AuthManager().authHeaders,
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar elemento');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<List<Map<String, dynamic>>> getDias(int itinerarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/itinerarios/$itinerarioId/dias'),
        headers: AuthManager().authHeaders,
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> addDia(int itinerarioId, int idDia) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/itinerarios/$itinerarioId/dias'),
        headers: {'Content-Type': 'application/json', ...AuthManager().authHeaders},
        body: json.encode({'idDia': idDia}),
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 409) {
        throw Exception('El día ya está en el itinerario');
      } else if (response.statusCode == 404) {
        throw Exception('El itinerario o el dato seleccionado ya no existe');
      } else if (response.statusCode >= 500) {
        throw Exception('Error en el servidor');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<void> removeDia(int itinerarioId, int diaItinerarioId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/itinerarios/$itinerarioId/dias/$diaItinerarioId'),
        headers: AuthManager().authHeaders,
      ).timeout(requestTimeout, onTimeout: () {
        throw Exception('Tiempo de conexión agotado');
      });

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar día del itinerario');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}


class EntradaItinerarioExport {

  final String dia;
  final DateTime fecha;
  final String hora;
  final String hermandad;
  final String tipoPaso;
  final String localizacion;
  final bool esCarreraOficial;

  EntradaItinerarioExport({
    required this.dia,
    required this.fecha,
    required this.hora,
    required this.hermandad,
    required this.tipoPaso,
    required this.localizacion,
    required this.esCarreraOficial,
  });

  static Future<List<EntradaItinerarioExport>> getEntradasItinerarioExport(int usuarioId, {int? idDia}) async {
    try {
      final itinerario = await ItinerarioApi.getOrCreateByUsuario(usuarioId);
      final itinerarioId = itinerario['id'] as int;

      final idsInfoPasoElegidos = (itinerario['items'] as List)
        .map((item) => item['idInfoPaso'] as int)
        .toSet();

      final diasItinerario = await ItinerarioApi.getDias(itinerarioId);
      final todosLosDias = await Dia.getDiasSemanaSanta();

      final diasAExportar = diasItinerario
          .where((d) => idDia == null || d['idDia'] == idDia)
          .map((d) => todosLosDias.firstWhere((dia) => dia.id == d['idDia']))
          .toList()
        ..sort((a, b) => a.fecha.compareTo(b.fecha));


      final List<EntradaItinerarioExport> entradas = [];

      for (final dia in diasAExportar) {
        final infoPasosDelDia = await InfoPaso.getByDia(dia.id);
        final hermandadesDelDia = await Hermandad.getHermandadesDia(dia.id);

        final nombreHermandadPorId = {
          for (final h in hermandadesDelDia) 
            h.id: h.nombre
        };

        final franjaHoraria = FranjaHoraria.calcularFranjas(
          infoPasosDelDia.map((i) => horaAMinutos(i.hora)).toList(),
        );
        final seleccionadosDelDia = infoPasosDelDia
            .where((i) => idsInfoPasoElegidos.contains(i.id))
            .toList()
          ..sort((a, b) => franjaHoraria
              .ajustarHora(horaAMinutos(a.hora))
              .compareTo(franjaHoraria.ajustarHora(horaAMinutos(b.hora))));

        for (final info in seleccionadosDelDia) {
          entradas.add(EntradaItinerarioExport(
            dia: dia.nombre,
            fecha: dia.fecha,
            hora: info.hora,
            hermandad: nombreHermandadPorId[info.idHermandad] ?? 'Desconocida',
            tipoPaso: info.tipoPaso,
            localizacion: info.localizacion,
            esCarreraOficial: info.esCarreraOficial,
          ));
        }
      }

      return entradas;
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
