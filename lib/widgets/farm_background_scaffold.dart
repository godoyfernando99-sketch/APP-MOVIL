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
  });

  final String title;
  final Widget child;
  final bool showBack;
  final bool showHome;
  final List<Widget>? actions;

  static const String _bgAsset =
      'assets/images/farm_animals_pasture_background_photo_green_1769096572851.jpg';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
          Image.asset(_bgAsset, fit: BoxFit.cover),
          Container(color: cs.surface.withValues(alpha: 0.72)),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
