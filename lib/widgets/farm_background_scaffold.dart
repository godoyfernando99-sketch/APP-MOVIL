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
  });

  final String title;
  final Widget child;
  final bool showBack;
  final bool showHome;
  final List<Widget>? actions;
  final Color? backgroundColor; 

  static const String _bgAsset =
      'assets/images/farm_animals_pasture_background_photo_green_1769096572851.jpg';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // CAMBIO AQUÍ: Bajamos el alpha de 0.72 a 0.20 para que la imagen se vea clara
    // O usamos Colors.transparent si queremos ver la foto original pura.
    final overlayColor = backgroundColor ?? Colors.black.withOpacity(0.25);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        // Sombra en el texto para que se lea bien sobre la imagen
        title: Text(title, style: const TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 8, color: Colors.black)]
        )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: showBack
            ? IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Back',
              )
            : null,
        actions: [
          if (showHome)
            IconButton(
              onPressed: () => context.go(AppRoutes.menu),
              icon: const Icon(Icons.home_rounded, color: Colors.white),
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
          
          // 2. Capa de color (Overlay) - Ahora más transparente
          Container(color: overlayColor),
          
          // 3. Contenido de la pantalla
          SafeArea(child: child),
        ],
      ),
    );
  }
}
