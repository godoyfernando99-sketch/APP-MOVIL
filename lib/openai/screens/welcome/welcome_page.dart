import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);

    return FarmBackgroundScaffold(
      title: strings('welcome'),
      showBack: false,
      // Forzamos fondo transparente para que se vea la imagen clara
      backgroundColor: Colors.transparent,
      child: Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              // Usamos negro con opacidad para crear el efecto de cristal
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
                    // Icono resaltado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: t.colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
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
                      user?.fullName.isNotEmpty == true 
                          ? user!.fullName 
                          : (user?.username ?? ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Botón Continuar estilo premium
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.menu),
                        style: FilledButton.styleFrom(
                          backgroundColor: t.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                        label: Text(
                          strings('continue').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
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
