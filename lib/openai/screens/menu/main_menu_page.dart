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
      // Botón de perfil en la parte superior
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
            _buildWelcomeHeader(t),
            const SizedBox(height: 24),
            
            // SECCIÓN: SELECCIÓN DE CATEGORÍA
            Text(
              '¿Qué vamos a analizar hoy?',
              style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // BOTÓN: ANIMALES DE CASA
            _CategoryButton(
              title: 'Animales de Casa',
              subtitle: 'Perros, gatos, conejos...',
              icon: Icons.pets_rounded,
              color: Colors.orange.shade700,
              onTap: () => context.push('${AppRoutes.animals}/home'),
            ),

            const SizedBox(height: 16),

            // BOTÓN: ANIMALES DE GRANJA
            _CategoryButton(
              title: 'Animales de Granja',
              subtitle: 'Vacas, cerdos, caballos...',
              icon: Icons.agriculture_rounded,
              color: Colors.green.shade700,
              onTap: () => context.push('${AppRoutes.animals}/farm'),
            ),

            const Divider(height: 48),

            // SECCIÓN: ACCESOS RÁPIDOS
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    title: 'Historial',
                    icon: Icons.history_rounded,
                    color: Colors.blueGrey,
                    onTap: () => context.push(AppRoutes.history),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    title: 'Planes Pro',
                    icon: Icons.star_rounded,
                    color: Colors.amber.shade800,
                    onTap: () => context.push(AppRoutes.subscriptions),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¡Bienvenido!', style: t.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
        Text('Tu asistente veterinario con IA', style: t.textTheme.bodyLarge),
      ],
    );
  }
}

// COMPONENTE: BOTÓN DE CATEGORÍA (ICONOS BLANCOS)
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
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Icono forzado a blanco
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
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.2))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
