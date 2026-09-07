import 'package:flutter/material.dart';
import '../services/emisora_service.dart';
import '../services/radio_player_controller.dart';
import '../utils/app_theme.dart';

class RadioScreen extends StatefulWidget {
  final RadioPlayerController controller;

  const RadioScreen({super.key, required this.controller});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  late Future<List<Emisora>> _emisorasFuture;

  RadioPlayerController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _emisorasFuture = Emisora.getEmisoras();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _playEmisora(Emisora emisora) async {
    try {
      await _controller.play(emisora);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al reproducir ${emisora.nombre}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Emisora>>(
      future: _emisorasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: AppColors.errorText),
            ),
          );
        }

        final emisoras = snapshot.data ?? [];
        if (emisoras.isEmpty) {
          return const Center(
            child: Text('No hay emisoras disponibles'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: emisoras.length,
          itemBuilder: (context, index) {
            final emisora = emisoras[index];
            final isCurrentStation =
                _controller.currentEmisora?.id == emisora.id;
            final isPlaying = isCurrentStation && _controller.isPlaying;

            return GestureDetector(
              onTap: () {
                if (isPlaying) {
                  _controller.pause();
                } else {
                  _playEmisora(emisora);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrentStation
                        ? AppColors.accent
                        : AppColors.border,
                    width: isCurrentStation ? 2 : 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                            child: Image.network(
                              emisora.urlImagen,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: AppColors.surfaceAlt,
                                child: const Icon(
                                  Icons.radio,
                                  size: 56,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isPlaying
                                    ? AppColors.accent.withValues(alpha: 0.92)
                                    : AppColors.primary.withValues(alpha: 0.75),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Text(
                        emisora.nombre,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrentStation
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isCurrentStation
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
