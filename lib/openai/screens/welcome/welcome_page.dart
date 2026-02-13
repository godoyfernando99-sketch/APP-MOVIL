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
    // Usamos watch para reaccionar a cambios en el estado de autenticación
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final t = Theme.of(context);
    
    // Función auxiliar para strings con manejo de seguridad
    String strings(String key) => AppStrings.of(context, key);

    // Lógica de seguridad: Si por alguna razón el usuario es nulo, 
    // podrías redirigir al login, pero aquí mostraremos un estado vacío seguro.
    final String displayName = user?.fullName.isNotEmpty == true 
        ? user!.fullName 
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
                    // Icono con resplandor suave
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
                    
                    // BOTÓN DE ACCIÓN PRINCIPAL
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        // Verificamos si hay usuario antes de navegar
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
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    
                    // Tip opcional para usuarios PRO
                    if (user?.subscriptionPlan == 'pro')
                      Padding(
                        padding: const EdgeInsets.top(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Plan PRO Activo",
                              style: TextStyle(color: Colors.amber.shade300, fontSize: 12, fontWeight: FontWeight.bold),
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
