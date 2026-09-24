import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/usuario_service.dart';
import '../services/admin_service.dart';
import '../services/noticias_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_message.dart';

class AdminScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const AdminScreen({super.key, this.onLogout});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _nombreHermandades;
  List<int>? _bytesHermandades;
  String? _nombreInfopasos;
  List<int>? _bytesInfopasos;
  bool _subiendo = false;
  String? _mensajeCsv;
  bool _mensajeCsvError = false;
  Timer? _timerCsv;

  List<Map<String, dynamic>> _dias = [];
  bool _cargandoDias = false;
  String? _mensajeDias;
  bool _mensajeDiasError = false;
  Timer? _timerDias;

  List<Noticia> _noticias = [];
  bool _cargandoNoticias = false;
  int? _eliminandoNoticiaId;
  bool _regenerandoResumen = false;
  String? _mensajeNoticias;
  bool _mensajeNoticiasError = false;
  Timer? _timerNoticias;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDias();
    _cargarNoticias();
  }

  @override
  void dispose() {
    _timerCsv?.cancel();
    _timerDias?.cancel();
    _timerNoticias?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _showCsvMessage(String text, {bool isError = false}) {
    _timerCsv?.cancel();
    setState(() {
      _mensajeCsv = text;
      _mensajeCsvError = isError;
    });
    _timerCsv = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _mensajeCsv = null);
    });
  }

  void _showDiasMessage(String text, {bool isError = false}) {
    _timerDias?.cancel();
    setState(() {
      _mensajeDias = text;
      _mensajeDiasError = isError;
    });
    _timerDias = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _mensajeDias = null);
    });
  }

  void _showNoticiasMessage(String text, {bool isError = false}) {
    _timerNoticias?.cancel();
    setState(() {
      _mensajeNoticias = text;
      _mensajeNoticiasError = isError;
    });
    _timerNoticias = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _mensajeNoticias = null);
    });
  }

  Future<void> _cargarNoticias() async {
    setState(() {
      _cargandoNoticias = true;
      _mensajeNoticias = null;
    });

    try {
      final noticias = await Noticia.getNoticias();
      if (mounted) {
        setState(() {
          _noticias = noticias;
          _cargandoNoticias = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoNoticias = false);
        _showNoticiasMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _regenerarResumen() async {
    setState(() {
      _regenerandoResumen = true;
      _mensajeNoticias = null;
    });

    try {
      await AdminService.regenerarResumen();
      if (mounted) {
        setState(() => _regenerandoResumen = false);
        _showNoticiasMessage('Resumen regenerado correctamente');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _regenerandoResumen = false);
        _showNoticiasMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _eliminarNoticia(Noticia noticia) async {
    final confirmado = await _confirmarEliminarNoticia(noticia);
    if (confirmado != true) return;

    setState(() {
      _eliminandoNoticiaId = noticia.id;
      _mensajeNoticias = null;
    });

    try {
      await AdminService.deleteNoticia(noticia.id);
      if (mounted) {
        setState(() {
          _noticias.removeWhere((n) => n.id == noticia.id);
          _eliminandoNoticiaId = null;
        });
        _showNoticiasMessage('Noticia eliminada correctamente');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _eliminandoNoticiaId = null);
        _showNoticiasMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  Future<bool?> _confirmarEliminarNoticia(Noticia noticia) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Eliminar noticia',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context, false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '¿Seguro que quieres eliminar "${noticia.titular}"? Esta acción no se puede deshacer.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _seleccionarArchivo({required bool hermandades}) async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (!mounted || resultado == null || resultado.files.single.bytes == null) {
      return;
    }
    setState(() {
      if (hermandades) {
        _nombreHermandades = resultado.files.single.name;
        _bytesHermandades = resultado.files.single.bytes!.toList();
      } else {
        _nombreInfopasos = resultado.files.single.name;
        _bytesInfopasos = resultado.files.single.bytes!.toList();
      }
      _mensajeCsv = null;
    });
  }

  Future<void> _subirCsv() async {
    if (_subiendo || _bytesHermandades == null || _nombreHermandades == null ||
        _bytesInfopasos == null || _nombreInfopasos == null) {
      return;
    }

    setState(() {
      _subiendo = true;
      _mensajeCsv = null;
    });

    try {
      final respuesta = await AdminService.uploadCatalogoCsv(
        _bytesHermandades!, _nombreHermandades!,
        _bytesInfopasos!, _nombreInfopasos!,
      );
      if (mounted) {
        setState(() {
          _subiendo = false;
          _nombreHermandades = null;
          _bytesHermandades = null;
          _nombreInfopasos = null;
          _bytesInfopasos = null;
        });
        _showCsvMessage(respuesta['mensaje'] ?? 'Carga completada');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _subiendo = false);
        _showCsvMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _cargarDias() async {
    setState(() {
      _cargandoDias = true;
      _mensajeDias = null;
    });

    try {
      final dias = await AdminService.getDias();
      if (mounted) {
        setState(() {
          _dias = dias;
          _cargandoDias = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoDias = false);
        _showDiasMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final primerDia = _dias.isNotEmpty ? _dias.first : null;
    var fechaInicial = primerDia != null
        ? (DateTime.tryParse(primerDia['fecha'] ?? '') ?? DateTime.now())
        : DateTime.now();

    //initialDate debe caer en viernes
    if (fechaInicial.weekday != DateTime.friday) {
      final diasHastaViernes = (DateTime.friday - fechaInicial.weekday + 7) % 7;
      fechaInicial = fechaInicial.add(Duration(days: diasHastaViernes == 0 ? 7 : diasHastaViernes));
    }

    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      locale: const Locale('es', 'ES'),
      helpText: 'Selecciona la fecha del Viernes de Dolores',
      selectableDayPredicate: (DateTime day) => day.weekday == DateTime.friday,
    );

    if (nuevaFecha == null) return;

    setState(() {
      _mensajeDias = null;
      _cargandoDias = true;
    });

    try {
      final fechaStr = nuevaFecha.toIso8601String();
      final respuesta = await AdminService.actualizarFechasDesdeInicio(
        fechaStr,
      );

      if (mounted) {
        _showDiasMessage(respuesta['mensaje'] ?? 'Fechas actualizadas');
        _cargarDias();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoDias = false);
        _showDiasMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  void _cerrarSesion() {
    UsuarioService.logout();
    if (widget.onLogout != null) {
      widget.onLogout!();
    } else {
      Navigator.pop(context, 'logout');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file), text: 'Cargar Datos'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Días'),
            Tab(icon: Icon(Icons.newspaper), text: 'Noticias')
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCsvTab(),
          _buildDiasTab(),
          _buildNoticiasTab(),
        ],
      ),
    );
  }


  Widget _buildCsvTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cargar CSVs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Selecciona ambos archivos. Se cargarán juntos.'),
          const SizedBox(height: 8),
          const Text(
            'Esta carga reemplaza todas las hermandades e infopasos y vacía '
            'los días y pasos guardados en los itinerarios de todos los usuarios.',
          ),
          const SizedBox(height: 24),
          const Text('Hermandades: id;nombre;idDia'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _subiendo ? null : () => _seleccionarArchivo(hermandades: true),
              icon: const Icon(Icons.folder_open),
              label: Text(_nombreHermandades ?? 'Seleccionar CSV de hermandades'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Infopasos: idHermandad;tipoPaso;hora;localizacion;difHora;esCarreraOficial'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _subiendo ? null : () => _seleccionarArchivo(hermandades: false),
              icon: const Icon(Icons.folder_open),
              label: Text(_nombreInfopasos ?? 'Seleccionar CSV de infopasos'),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_bytesHermandades != null && _bytesInfopasos != null && !_subiendo)
                  ? _subirCsv
                  : null,
              icon: _subiendo
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.cloud_upload, color: Colors.white),
              label: Text(
                _subiendo ? 'Subiendo...' : 'Reemplazar datos con ambos CSV',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          if (_mensajeCsv != null) ...[
            const SizedBox(height: 16),
            AppMessage(
              message: _mensajeCsv!,
              isError: _mensajeCsvError,
              onDismiss: () => setState(() => _mensajeCsv = null),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildDiasTab() {
    if (_cargandoDias) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión de Fechas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona la fecha del Viernes de Dolores y el resto de días se calcularán automáticamente.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _seleccionarFechaInicio,
              icon: const Icon(Icons.edit_calendar, color: Colors.white),
              label: const Text(
                'Seleccionar fecha de inicio',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          if (_mensajeDias != null) ...[
            const SizedBox(height: 12),
            AppMessage(
              message: _mensajeDias!,
              isError: _mensajeDiasError,
              onDismiss: () => setState(() => _mensajeDias = null),
            ),
          ],

          const SizedBox(height: 16),

          Expanded(
            child: _dias.isEmpty
                ? const Center(
                    child: Text(
                      'No hay días configurados',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: _dias.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dia = _dias[index];
                      return _buildDiaCard(dia);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaCard(Map<String, dynamic> dia) {
    final fechaStr = dia['fecha'] ?? '';
    final fecha = DateTime.tryParse(fechaStr);
    final fechaFormateada = fecha != null
        ? '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}'
        : 'Sin fecha';
    final diaSemana = fecha != null
        ? ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][fecha.weekday - 1]
        : '';
    final diaNum = fecha?.day.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  diaNum,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  diaSemana,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dia['nombre'] ?? 'Día',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fechaFormateada,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticiasTab() {
    if (_cargandoNoticias) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión de Noticias',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _regenerandoResumen ? null : _regenerarResumen,
              icon: _regenerandoResumen
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                _regenerandoResumen ? 'Regenerando...' : 'Regenerar resumen IA',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          if (_mensajeNoticias != null) ...[
            const SizedBox(height: 12),
            AppMessage(
              message: _mensajeNoticias!,
              isError: _mensajeNoticiasError,
              onDismiss: () => setState(() => _mensajeNoticias = null),
            ),
          ],

          const SizedBox(height: 16),

          Expanded(
            child: _noticias.isEmpty
                ? const Center(
                    child: Text(
                      'No hay noticias publicadas',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _cargarNoticias,
                    child: ListView.separated(
                      itemCount: _noticias.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _buildNoticiaCard(_noticias[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticiaCard(Noticia noticia) {
    final fecha = noticia.fecha;
    final fechaFormateada =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    final subtitulo = noticia.origen.isNotEmpty
        ? '$fechaFormateada · ${noticia.origen}'
        : fechaFormateada;
    final eliminando = _eliminandoNoticiaId == noticia.id;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noticia.titular,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            eliminando
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.errorText,
                    tooltip: 'Eliminar noticia',
                    onPressed: _eliminandoNoticiaId != null
                        ? null
                        : () => _eliminarNoticia(noticia),
                  ),
          ],
        ),
      ),
    );
  }
}
