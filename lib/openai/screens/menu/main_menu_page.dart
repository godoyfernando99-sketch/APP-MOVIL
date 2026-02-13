import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  // Manejo del Soporte VIP mejorado
  void _handleVipSupport(BuildContext context, bool hasSupport) {
    if (hasSupport) {
      context.push(AppRoutes.support);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber),
              SizedBox(width: 10),
              Text("Acceso VIP", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "El soporte técnico prioritario 24/7 con veterinarios expertos es una función exclusiva para los planes Básico y Premium.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("MÁS TARDE", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.subscriptions);
              },
              child: const Text("VER PLANES", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    
    // Escuchamos los cambios del usuario en tiempo real
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;
    
    // Lógica de Soporte: Planes 'basico' o 'premium' tienen soporte VIP
    final bool hasVipSupport = user?.subscriptionPlan == 'basico' || user?.subscriptionPlan == 'premium';
    
    // Lógica de Escaneos: Usamos el campo monthlyScans que actualizamos en ScanResultPage
    final int scansLeft = user?.monthlyScans ?? 0;
    final bool isFreePlan = user?.subscriptionPlan == 'free';

    return FarmBackgroundScaffold(
      title: 'ScannerAnimal IA',
      backgroundColor: Colors.transparent, 
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.account_circle_rounded, size: 30),
        ),
      ],
      child: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeHeader(t, user?.displayName ?? 'Usuario'),
            const SizedBox(height: 16),

            // BANNER DINÁMICO DE ESCANEOS
            if (isFreePlan) 
              _buildFreeScansBanner(scansLeft)
            else if (!isFreePlan)
              _buildProInfoBanner(user?.subscriptionPlan ?? ''),
            
            const SizedBox(height: 24),
            
            _buildSectionTitle(t, '¿Qué vamos a analizar hoy?'),
            const SizedBox(height: 16),

            _CategoryButton(
              title: 'Animales de Casa',
              subtitle: 'Perros, gatos, conejos...',
              icon: Icons.pets_rounded,
              color: Colors.orange.shade700.withOpacity(0.9),
              onTap: () => context.push('${AppRoutes.animals}/home'),
            ),

            const SizedBox(height: 16),

            _CategoryButton(
              title: 'Animales de Granja',
              subtitle: 'Vacas, cerdos, caballos...',
              icon: Icons.agriculture_rounded,
              color: Colors.green.shade700.withOpacity(0.9),
              onTap: () => context.push('${AppRoutes.animals}/farm'),
            ),

            const Divider(height: 48, color: Colors.white24),

            _buildSectionTitle(t, 'Servicios VIP'),
            const SizedBox(height: 16),
            
            _CategoryButton(
              title: 'Soporte VIP Prioritario',
              subtitle: hasVipSupport 
                  ? 'Chat activo con veterinarios' 
                  : 'Función para planes Básico/Premium',
              icon: Icons.support_agent_rounded,
              // Color cambia según si tiene el beneficio o no
              color: hasVipSupport 
                  ? Colors.amber.shade800.withOpacity(0.9) 
                  : Colors.blueGrey.withOpacity(0.6),
              onTap: () => _handleVipSupport(context, hasVipSupport),
            ),

            const Divider(height: 48, color: Colors.white24),

            _buildSectionTitle(t, 'Biblioteca & Historial'),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    title: 'Historial',
                    icon: Icons.history_rounded,
                    color: Colors.blue.shade300,
                    onTap: () => context.push(AppRoutes.history),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    title: 'Enfermedades',
                    icon: Icons.sick_rounded,
                    color: Colors.red.shade400,
                    onTap: () => context.push(AppRoutes.diseases),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _QuickActionCard(
              title: 'Gestionar Suscripción',
              icon: Icons.star_rounded,
              color: Colors.amber.shade400,
              onTap: () => context.push(AppRoutes.subscriptions),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeScansBanner(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count > 0 
                ? "Te quedan $count escaneos gratuitos este mes." 
                : "Has agotado tus escaneos. ¡Pásate a un plan superior!",
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProInfoBanner(String planName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 12),
          Text(
            "Plan ${planName.toUpperCase()} Activo",
            style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData t, String title) {
    return Text(title, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white));
  }

  Widget _buildWelcomeHeader(ThemeData t, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¡Hola, $name!', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
        const Text('Tu asistente veterinario con IA listo.', style: TextStyle(color: Colors.white70)),
      ],
    );
  }
}

// (Los componentes _CategoryButton y _QuickActionCard se mantienen iguales)
