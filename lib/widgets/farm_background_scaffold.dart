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
    this.backgroundColor, // <-- Agregado para resolver el error de compilación
  });

  final String title;
  final Widget child;
  final bool showBack;
  final bool showHome;
  final List<Widget>? actions;
  final Color? backgroundColor; // <-- Definición de la propiedad

  static const String _bgAsset =
      'assets/images/farm_animals_pasture_background_photo_green_1769096572851.jpg';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Si no se pasa un color, usamos el color de superficie con transparencia por defecto
    final overlayColor = backgroundColor ?? cs.surface.withValues(alpha: 0.72);

    return Scaffold(
      extendBodyBehindAppBar: true,
      // Se define el fondo del Scaffold como transparente para ver la imagen del Stack
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: cs.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: showBack
            ? IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back, color: cs.onSurface),
                tooltip: 'Back',
              )
            : null,
        actions: [
          if (showHome)
            IconButton(
              onPressed: () => context.go(AppRoutes.menu),
              icon: Icon(Icons.home_rounded, color: cs.onSurface),
              tooltip: 'Home',
            ),
          ...?actions,
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagen de fondo
          Image.asset(_bgAsset, fit: BoxFit.cover),
          
          // 2. Capa de color (Overlay)
          // Usamos el color configurado para dar el efecto de "cristal"
          Container(color: overlayColor),
          
          // 3. Contenido de la pantalla
          SafeArea(child: child),
        ],
      ),
    );
  }
}
