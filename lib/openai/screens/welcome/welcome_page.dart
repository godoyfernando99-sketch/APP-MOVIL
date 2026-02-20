import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart'; // Asegúrate de haber hecho flutter pub get

import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // Función para mostrar el diálogo del video
  void _showTutorial(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Obliga a usar el botón cerrar
      builder: (context) => const _TutorialVideoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final t = Theme.of(context);
    
    String strings(String key) => AppStrings.of(context, key);

    final String displayName = (user?.fullName != null && user!.fullName.isNotEmpty)
        ? user.fullName 
        : (user?.username ?? 'Usuario');

    return FarmBackgroundScaffold(
      title: strings('welcome'),
      showBack: false,
      backgroundColor: Colors.transparent,
      child: Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              color: Colors.black.withOpacity(0.7),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: t.colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: t.colorScheme.primary.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Icon(Icons.pets_rounded, size: 60, color: t.colorScheme.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${strings('welcome')},',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // BOTÓN DE ACCIÓN PRINCIPAL (CONTINUAR)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.menu),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                        label: Text(
                          strings('continue').toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // BOTÓN VER TUTORIAL (NUEVO)
                    TextButton.icon(
                      onPressed: () => _showTutorial(context),
                      icon: Icon(Icons.play_circle_outline, color: t.colorScheme.primary),
                      label: Text(
                        "VER TUTORIAL DE USO",
                        style: TextStyle(
                          color: t.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    
                    if (user?.subscriptionPlan == 'pro')
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Plan PRO Activo",
                              style: TextStyle(
                                color: Colors.amber.shade300, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
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

// COMPONENTE DEL DIÁLOGO DE VIDEO
class _TutorialVideoDialog extends StatefulWidget {
  const _TutorialVideoDialog();

  @override
  State<_TutorialVideoDialog> createState() => _TutorialVideoDialogState();
}

class _TutorialVideoDialogState extends State<_TutorialVideoDialog> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/tutorial_app.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // IMPORTANTE: Libera la memoria del video
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra superior con botón cerrar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tutorial ScannerAnimal", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Área del Video
          AspectRatio(
            aspectRatio: _controller.value.isInitialized 
                ? _controller.value.aspectRatio 
                : 16 / 9,
            child: _controller.value.isInitialized
                ? VideoPlayer(_controller)
                : const Center(child: CircularProgressIndicator()),
          ),
          // Indicador de progreso
          if (_controller.value.isInitialized)
            VideoProgressIndicator(_controller, allowScrubbing: true),
        ],
      ),
    );
  }
}
