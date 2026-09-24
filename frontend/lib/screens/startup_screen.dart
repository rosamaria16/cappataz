import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../utils/app_theme.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, required this.child});

  final Widget child;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  static const _maxAttempts = 3;
  static const _attemptTimeout = Duration(seconds: 20);
  static const _retryDelay = Duration(seconds: 2);

  http.Client? _client;
  bool _ready = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      if (!mounted) return;
      final client = http.Client();
      _client = client;
      try {
        final response = await client
            .get(Uri.parse('$apiBaseUrl/dias/?limit=1'))
            .timeout(_attemptTimeout);
        if (response.statusCode == 200 && jsonDecode(response.body) is List) {
          if (!mounted) return;
          setState(() => _ready = true);
          return;
        }
      } catch (_) {
      } finally {
        client.close();
        _client = null;
      }
      if (!mounted) return;
      if (attempt < _maxAttempts - 1) {
        await Future<void>.delayed(_retryDelay);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/branding/icono.jpg',
                      width: 176,
                      height: 176,
                      semanticLabel: 'Icono CAPPATAZ',
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'CAPPATAZ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.serif,
                      fontSize: 30,
                      letterSpacing: 4,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tu Semana Santa, paso a paso',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.serif,
                      fontSize: 20,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_loading) ...[
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                        semanticsLabel: 'Conectando',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _loading
                          ? 'Preparando tu Semana Santa…'
                          : 'Algo no ha funcionado. Inténtalo de nuevo.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (!_loading) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primaryDark,
                      ),
                      onPressed: () {
                        setState(() => _loading = true);
                        _connect();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
