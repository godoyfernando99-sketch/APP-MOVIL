import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanneranimal/nav.dart';

class FarmBackgroundScaffold extends StatelessWidget {
  const FarmBackgroundScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showBack = true,
    this.showHome = true,
    this.actions,
    this.backgroundColor,
    this.bottomNavigationBar, // <--- NUEVO PARÁMETRO
  });

  final String title;
  final Widget child;
  final bool showBack;
  final bool showHome;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar; // <--- DEFINICIÓN DEL PARÁMETRO

  static const String _bgAsset = 'assets/images/fondo nuevo.png';

  @override
  Widget build(BuildContext context) {
    // Overlay más transparente para que luzca el fondo
    final overlayColor = backgroundColor ?? Colors.black.withOpacity(0.25);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      // PASAMOS EL PARÁMETRO AL SCAFFOLD REAL
      bottomNavigationBar: bottomNavigationBar, 
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 8, color: Colors.black)],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: showBack
            ? IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Atrás',
              )
            : null,
        actions: [
          if (showHome)
            IconButton(
              onPressed: () => context.go(AppRoutes.menu),
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              tooltip: 'Inicio',
            ),
          ...?actions,
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagen de fondo (Asegúrate de que la ruta sea correcta)
          Image.asset(
            _bgAsset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
          ),

          // 2. Capa de color (Overlay)
          Container(color: overlayColor),

          // 3. Contenido de la pantalla
          SafeArea(child: child),
        ],
      ),
    );
  }
}
