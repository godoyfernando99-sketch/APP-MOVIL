import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  void _handleVipSupport(BuildContext context, bool isPro) {
    if (isPro) {
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
              Text("Exclusivo PRO", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "El soporte técnico prioritario con veterinarios expertos es una función exclusiva para usuarios con el Plan PRO activo.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ENTENDIDO", style: TextStyle(color: Colors.white54)),
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
              child: const Text("OBTENER PRO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;
    
    final String currentPlan = user?.subscriptionPlan?.toLowerCase() ?? 'free';
    final bool isUserPro = currentPlan == 'pro';
    final int scansLeft = user?.scansRemaining ?? 0;

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeHeader(t, user?.firstName ?? user?.username ?? 'Usuario'),
            const SizedBox(height: 16),

            if (isUserPro) _buildProInfoBanner() else _buildFreeScansBanner(scansLeft),
            
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
              subtitle: isUserPro ? 'Chat activo con veterinarios' : 'Desbloquea con el Plan PRO',
              icon: Icons.support_agent_rounded,
              color: isUserPro ? Colors.amber.shade800.withOpacity(0.9) : Colors.grey.withOpacity(0.5),
              onTap: () => _handleVipSupport(context, isUserPro),
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
              count > 0 ? "Te quedan $count escaneos disponibles." : "Escaneos agotados. ¡Pásate a PRO!",
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 12),
          Text("USUARIO PRO - ACCESO TOTAL", style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
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

// --- CLASES QUE FALTABAN ---
class _CategoryButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryButton({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.5))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
