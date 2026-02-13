import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:scanneranimal/app/auth/auth_controller.dart'; // Importante para leer el plan
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  void _handleVipSupport(BuildContext context, bool isPro) {
    if (isPro) {
      // Si es Pro, navegamos al soporte
      context.push(AppRoutes.support);
    } else {
      // Si no es Pro, mostramos el aviso de suscripción
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
            "El soporte técnico prioritario 24/7 es una función exclusiva para usuarios con un Plan Pro activo.",
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
              child: const Text("SER PRO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    
    // CONEXIÓN CON EL CONTROLADOR DE USUARIO
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;
    final bool isUserPro = user?.subscriptionPlan == 'pro';
    
    // LÓGICA DE ESCANEOS GRATUITOS (Bienvenida)
    // Asumimos que el modelo de usuario tiene un campo 'freeScans'
    final int scansLeft = user?.freeScans ?? 10; 

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
              _buildWelcomeHeader(t, user?.displayName ?? 'Usuario'),
              const SizedBox(height: 16),

              // BANNER DE ESCANEOS DE BIENVENIDA
              if (!isUserPro) _buildFreeScansBanner(scansLeft),
              
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
                subtitle: isUserPro 
                    ? 'Chat activo con veterinarios' 
                    : 'Función exclusiva para Plan Pro',
                icon: Icons.support_agent_rounded,
                // Si es Pro brilla en Ámbar, si no es gris azulado
                color: isUserPro 
                    ? Colors.amber.shade800.withOpacity(0.9) 
                    : Colors.blueGrey.withOpacity(0.6),
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
                title: 'Planes Pro y Suscripciones',
                icon: Icons.star_rounded,
                color: Colors.amber.shade400,
                onTap: () => context.push(AppRoutes.subscriptions),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET PARA EL BANNER DE BIENVENIDA (ESCANEOS GRATIS)
  Widget _buildFreeScansBanner(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "¡Regalo de Bienvenida! Te quedan $count escaneos gratuitos.",
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData t, String title) {
    return Text(
      title,
      style: t.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData t, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Hola, $name!', 
          style: t.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900, 
            color: Colors.white,
          )
        ),
        const Text(
          'Tu asistente veterinario con IA listo.', 
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

// COMPONENTE: BOTÓN DE CATEGORÍA (Reutilizado)
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
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
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

// COMPONENTE: TARJETAS PEQUEÑAS (Reutilizado)
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
