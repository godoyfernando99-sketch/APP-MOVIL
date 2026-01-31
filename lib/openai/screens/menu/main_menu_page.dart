import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return FarmBackgroundScaffold(
      title: 'ScannerAnimal IA',
      // IMPORTANTE: Si tu FarmBackgroundScaffold tiene una propiedad de color, 
      // asegúrate de que sea transparente.
      backgroundColor: Colors.transparent, 
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.account_circle_rounded, size: 30),
        ),
      ],
      child: Container(
        // Usamos un degradado muy sutil solo en la base o fondo transparente
        // para asegurar que el texto sea legible sin tapar la imagen.
        color: Colors.transparent, 
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeHeader(t),
              const SizedBox(height: 24),
              
              Text(
                '¿Qué vamos a analizar hoy?',
                style: t.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Forzamos blanco para resaltar sobre el fondo
                  shadows: [const Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 16),

              _CategoryButton(
                title: 'Animales de Casa',
                subtitle: 'Perros, gatos, conejos...',
                icon: Icons.pets_rounded,
                color: Colors.orange.shade700.withOpacity(0.9), // Ligera transparencia
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

              Text(
                'Biblioteca Veterinaria',
                style: t.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Enfermedades',
                      icon: Icons.sick_rounded,
                      color: Colors.red.shade400, // Color más vivo
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

              Text(
                'Mi Actividad',
                style: t.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
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
            ],
          ),
        ),
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

// COMPONENTE: BOTÓN DE CATEGORÍA (Sin cambios estructurales, solo ajustes de color)
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

// COMPONENTE: TARJETAS PEQUEÑAS (FONDO MÁS OSCURO/TRANSPARENTE PARA NO OPACAR)
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
      // Usamos un fondo oscuro traslúcido para que se vea el animal detrás
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
              Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
