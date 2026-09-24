import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/main_layout.dart';
import 'screens/startup_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

/// Ancho del "marco" de la app en pantallas anchas (desktop/web).
const double _frameWidth = 760;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        final app = child ?? const SizedBox.shrink();
        // En pantallas anchas, enmarca la app con un ancho tipo móvil/tablet
        // centrado y fondo oscuro a los lados. En móvil, ocupa todo el ancho.
        return StartupScreen(child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= _frameWidth) return app;
            return ColoredBox(
              color: AppColors.primaryDark,
              child: Center(
                child: SizedBox(width: _frameWidth, child: app),
              ),
            );
          },
        ));
      },
      home: const MainLayout(),
    );
  }
}
