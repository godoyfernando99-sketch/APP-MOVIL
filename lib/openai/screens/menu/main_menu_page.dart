import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  // TODO: Implementar lógica real de suscripción desde tu AuthController o Provider
  final bool isUserPro = false; 

  void _handleVipSupport(BuildContext context) {
    if (isUserPro) {
      // Si es Pro, navegamos al soporte (Asegúrate de tener esta ruta en nav.dart)
      context.push(AppRoutes.support);
    } else {
      // Si no es Pro, mostramos aviso
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber),
              SizedBox(width: 10),
              Text("Acceso VIP", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "El soporte técnico prioritario es una función exclusiva para usuarios con un Plan Pro activo.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("MÁS TARDE"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.subscriptions);
              },
              child: const Text("VER PLANES PRO", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return FarmBackgroundScaffold(
      title: 'ScannerAnimal IA',
      backgroundColor: Colors.transparent, 
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.account_circle_rounded, size: 30),
        ),
      ],
      child: Container(
        color: Colors.transparent, 
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeHeader(t),
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

              _buildSectionTitle(t, 'Biblioteca Veterinaria'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Enfermedades',
                      icon: Icons.sick_rounded,
                      color: Colors.red.shade400,
                      onTap: () => context.push(AppRoutes.diseases),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Medicamentos',
                      icon: Icons.medication_rounded,
                      color: Colors.purple.shade300,
                      onTap: () => context.push(AppRoutes.medications),
                    ),
                  ),
                ],
              ),

              const Divider(height: 48, color: Colors.white24),

              // --- NUEVA SECCIÓN SOPORTE VIP ---
              _buildSectionTitle(t, 'Servicios VIP'),
              const SizedBox(height: 16),
              _CategoryButton(
                title: 'Soporte VIP Prioritario',
                subtitle: 'Chat directo con expertos veterinarios',
                icon: Icons.support_agent_rounded,
                color: isUserPro ? Colors.amber.shade800.withOpacity(0.9) : Colors.blueGrey.withOpacity(0.6),
                onTap: () => _handleVipSupport(context),
              ),
              // --------------------------------

              const Divider(height: 48, color: Colors.white24),

              _buildSectionTitle(t, 'Mi Actividad'),
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
                      title: 'Planes Pro',
                      icon: Icons.star_rounded,
                      color: Colors.amber.shade400,
                      onTap: () => context.push(AppRoutes.subscriptions),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData t, String title) {
    return Text(
      title,
      style: t.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [const Shadow(blurRadius: 4, color: Colors.black54)],
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Bienvenido!', 
          style: t.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900, 
            color: Colors.white,
            shadows: [const Shadow(blurRadius: 8, color: Colors.black87)],
          )
        ),
        Text(
          'Tu asistente veterinario con IA', 
          style: t.textTheme.bodyLarge?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

// COMPONENTE: BOTÓN DE CATEGORÍA
class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

// COMPONENTE: TARJETAS PEQUEÑAS
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.title, required this.icon, required this.color, required this.onTap});
  
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.black.withOpacity(0.4), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5)
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
