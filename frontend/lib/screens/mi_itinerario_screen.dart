import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/auth_manager.dart';
import '../services/usuario_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_message.dart';
import 'login_screen.dart';
import 'mi_itinerario_first_screen.dart';
import 'register_screen.dart';

class MiItinerarioScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const MiItinerarioScreen({super.key, this.onLoginSuccess});

  @override
  State<MiItinerarioScreen> createState() => _MiItinerarioScreenState();
}

class _MiItinerarioScreenState extends State<MiItinerarioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AuthManager().isLoggedIn) {
        _showLoginModal();
      }
    });
  }

  void _showLoginModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoginModal(
        onLoginSuccess: () {
          setState(() {});
          widget.onLoginSuccess?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthManager().isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Por favor, ',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                TextSpan(
                  text: 'inicia sesión',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      ).then((result) {
                        if (result == true) {
                          setState(() {});
                          widget.onLoginSuccess?.call();
                        }
                      });
                    },
                ),
                const TextSpan(
                  text: ' para ver tu itinerario',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const ItinerarioFirstScreen();
  }
}

class LoginModal extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginModal({super.key, this.onLoginSuccess});

  @override
  State<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _errorTimer;

  @override
  void dispose() {
    _errorTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String text) {
    _errorTimer?.cancel();
    setState(() => _errorMessage = text);
    _errorTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showError('Por favor, introduce tus credenciales');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await UsuarioService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onLoginSuccess?.call();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _goToRegister() async {
    final registered = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
    if (!mounted) return;
    if (registered == true && AuthManager().isLoggedIn) {
      Navigator.pop(context);
      widget.onLoginSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: AppInputDecoration.build(
                  label: 'Email',
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: AppInputDecoration.build(
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                AppMessage(
                  message: _errorMessage!,
                  isError: true,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Iniciar Sesión',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿No tienes cuenta? ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : _goToRegister,
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
