import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/noticias_service.dart';
import '../utils/app_theme.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  List<Noticia> _noticias = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNoticias();
  }

  Future<void> _cargarNoticias() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final noticias = await Noticia.getNoticias();
      if (!mounted) return;
      setState(() {
        _noticias = noticias;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_noticias.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay noticias disponibles',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _cargarNoticias,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: _noticias.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _TarjetaNoticia(noticia: _noticias[index]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.accent,
        child: const Icon(Icons.auto_awesome),
        onPressed: () => _mostrarResumen(context),
      ),
    );
  }

  Future<void> _mostrarResumen(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final resumen = await Noticia.generarResumen();
      if (!context.mounted) return;
      Navigator.of(context).pop();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _ResumenIA(resumen: resumen),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _ResumenIA extends StatelessWidget {
  final String resumen;
  const _ResumenIA({required this.resumen});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Resumen de las noticias',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: AppFonts.serif,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Generado con IA',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: AppColors.divider, thickness: 1),
            ),
            Text(
              resumen,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: AppFonts.serif,
                fontSize: 18,
                height: 1.6,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: AppColors.divider, thickness: 1),
            ),
            const Text(
              'Para reportar cualquier incidencia o contenido inapropiado, contactar con rosespmar@alum.us.es',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaNoticia extends StatelessWidget {
  final Noticia noticia;
  const _TarjetaNoticia({required this.noticia});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoticiaDetalleScreen(noticia: noticia),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImagenNoticia(url: noticia.urlImagen, height: 190),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noticia.titular,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MetadatosNoticia(noticia: noticia),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoticiaDetalleScreen extends StatelessWidget {
  final Noticia noticia;

  const NoticiaDetalleScreen({super.key, required this.noticia});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Noticias - Detalle"),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      noticia.origen.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontFamily: AppFonts.serif,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: AppColors.primary, thickness: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      noticia.titular,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: AppFonts.serif,
                        fontSize: 30,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _MetadatosNoticia(noticia: noticia, showHora: true, showOrigen: false),
                    const SizedBox(height: 20),
                    _ImagenNoticia(url: noticia.urlImagen, height: 245),
                    const SizedBox(height: 22),
                    Text(
                      noticia.contenido,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: AppFonts.serif,
                        fontSize: 18,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadatosNoticia extends StatelessWidget {
  final Noticia noticia;
  final bool showHora;
  final bool showOrigen;

  const _MetadatosNoticia({required this.noticia, this.showHora = false, this.showOrigen = true});

  @override
  Widget build(BuildContext context) {
    final pattern = showHora
        ? "d 'de' MMMM 'de' y - HH:mm"
        : "d 'de' MMMM 'de' y";

    final fecha = DateFormat(pattern, 'es_ES').format(noticia.fecha);

    String res = showOrigen
        ? '$fecha | ${noticia.origen}'
        : fecha;

    return Text(
      res,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ImagenNoticia extends StatelessWidget {
  final String url;
  final double height;

  const _ImagenNoticia({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return _ImagenNoticiaFallback(height: height);
    }

    return Image.network(
      url,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _ImagenNoticiaFallback(height: height),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: height,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _ImagenNoticiaFallback extends StatelessWidget {
  final double height;

  const _ImagenNoticiaFallback({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.surfaceAlt,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textSecondary,
            size: 42,
          ),
          SizedBox(height: 8),
          Text(
            'Imagen no disponible',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}