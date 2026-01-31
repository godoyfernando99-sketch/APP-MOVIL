import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class AnimalDetailPage extends StatelessWidget {
  const AnimalDetailPage({super.key, required this.animalId});
  final String animalId;

  @override
  Widget build(BuildContext context) {
    final animal = AnimalsCatalog.byId(animalId);
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);

    return FarmBackgroundScaffold(
      title: animal.name.toUpperCase(),
      backgroundColor: Colors.transparent, // Habilitamos transparencia
      child: Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              // EFECTO CRISTAL AHUMADO
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Imagen destacada del animal seleccionado
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          animal.assetImage, 
                          height: 220, 
                          width: double.infinity, 
                          fit: BoxFit.cover
                        ),
                      ),
                      // Overlay gradiente sutil sobre la foto
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  Text(
                    'MODO DE ESCANEO', 
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.2
                    )
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¿Cómo deseas identificar al animal?', 
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // BOTÓN: ESCANEO CON CHIP (Primario)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton.icon(
                      onPressed: () => context.push('${AppRoutes.scanCapture}/${animal.id}/chip'),
                      style: FilledButton.styleFrom(
                        backgroundColor: t.colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.nfc_rounded, size: 24),
                      label: Text(
                        strings('scanWithChip').toUpperCase(), 
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // BOTÓN: ESCANEO SIN CHIP (Secundario/Outlined)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('${AppRoutes.scanCapture}/${animal.id}/nochip'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white70),
                      label: Text(
                        strings('scanWithoutChip').toUpperCase(), 
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
