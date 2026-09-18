import 'dart:async';
import 'package:flutter/material.dart';
import '../services/usuario_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_message.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>{
  late TextEditingController _emailController;
  late TextEditingController _nombreController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _nombreController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _emailController.dispose();
    _nombreController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String text) {
    _errorTimer?.cancel();
    setState(() => _errorMessage = text);
    _errorTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  String? validateForm() {
    if (_emailController.text.isEmpty) {
      return 'El email no puede estar vacío';
    }
    if (!_emailController.text.contains('@')) {
      return 'Email inválido';
    }
    if (_nombreController.text.isEmpty) {
      return 'El nombre no puede estar vacío';
    }
    if (_passwordController.text.isEmpty) {
      return 'La contraseña no puede estar vacía';
    }
    if (_passwordController.text.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _register() async {

    final validation = validateForm();
    if (validation != null) {
      _showError(validation);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text;
    final password = _passwordController.text;
    try {
      await UsuarioService.register(
        email,
        password,
        _nombreController.text,
      );

      try {
        await UsuarioService.login(email, password);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cuenta creada, pero no se pudo iniciar sesión automáticamente. '
                'Inicia sesión con tus credenciales.',
              ),
              duration: Duration(seconds: 10),
            ),
          );
          Navigator.pop(context, false);
        }
        return;
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 32,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    size: 36,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Completa tus datos para registrarte',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textOnPrimaryMuted,
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  if (_errorMessage != null) ...[
                    AppMessage(
                      message: _errorMessage!,
                      isError: true,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: 20),
                  ],

                  TextField(
                    controller: _nombreController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: AppInputDecoration.build(
                      label: 'Nombre completo',
                      icon: Icons.person_outline,
                      hint: 'Nombre Apellido',
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: AppInputDecoration.build(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      hint: 'tu@email.com',
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: AppInputDecoration.build(
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: AppInputDecoration.build(
                      label: 'Confirmar contraseña',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Registrarse',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes cuenta? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : () => Navigator.pop(context),
                        child: const Text(
                          'Inicia Sesión',
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
        ],
      ),
    );
  }
}
