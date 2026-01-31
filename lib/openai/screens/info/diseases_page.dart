import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/data/diseases.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class DiseasesPage extends StatelessWidget {
  const DiseasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);
    final auth = context.watch<AuthController>();
    final isPro = auth.currentUser?.isPro ?? false;

    // --- VISTA PARA USUARIOS NO PRO ---
    if (!isPro) {
      return FarmBackgroundScaffold(
        title: strings('diseases'),
        child: Center(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Card(
              color: const Color(0xFF1A1A1A),
              child: Padding(
                padding: AppSpacing.paddingXl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 64, color: t.colorScheme.primary),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Contenido Exclusivo PRO',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'La lista completa de enfermedades está disponible solo para usuarios del Plan PRO.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.subscriptions),
                      icon: const Icon(Icons.star_rounded),
                      label: const Text('Ver Planes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // --- VISTA PRINCIPAL DEL CATÁLOGO (MODO OSCURO) ---
    return FarmBackgroundScaffold(
      title: strings('diseases'),
      child: ListView.separated(
        padding: AppSpacing.paddingLg,
        itemCount: DiseasesCatalog.diseases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final d = DiseasesCatalog.diseases[i];
          return Card(
            color: const Color(0xFF121212), // Fondo oscuro sólido
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            child: InkWell(
              onTap: () => _showDiseaseDetail(context, d),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Row(
                  children: [
                    // Icono en lugar de imagen
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bug_report_rounded, color: Colors.redAccent, size: 30),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.description,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- VENTANA EMERGENTE (POP-UP) DETALLADA ---
  void _showDiseaseDetail(BuildContext context, Disease disease) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A), // Fondo de la ventana
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Text(
                  disease.name,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const Divider(color: Colors.white12, height: 32),
                
                // Descripción
                _buildDetailSection('Descripción', disease.description, Colors.blueAccent),
                const SizedBox(height: 20),
                
                // Síntomas
                _buildDetailSection('Síntomas', disease.symptoms, Colors.orangeAccent),
                const SizedBox(height: 20),
                
                // Tratamiento
                _buildDetailSection('Tratamiento Sugerido', disease.treatment, Colors.greenAccent),
                
                const SizedBox(height: 32),
                
                // Botón Cerrar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para las secciones del detalle
  Widget _buildDetailSection(String title, String content, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, color: accentColor),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
        ),
      ],
    );
  }
}
