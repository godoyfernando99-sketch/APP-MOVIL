import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class AnimalsPage extends StatelessWidget {
  // Recibimos la categoría directamente desde el Router
  final String category;

  const AnimalsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    
    // Filtramos los animales según la categoría que viene por la URL
    final animals = AnimalsCatalog.animals
        .where((a) => a.category == category)
        .toList();

    return FarmBackgroundScaffold(
      title: category == 'home' ? 'Animales de Casa' : 'Animales de Granja',
      child: GridView.builder(
        padding: AppSpacing.paddingLg,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.82,
        ),
        itemCount: animals.length,
        itemBuilder: (context, i) {
          final a = animals[i];
          return _AnimalCard(
            animal: a,
            onTap: () => _showScanModeSelector(context, a),
          );
        },
      ),
    );
  }

  // Menú que aparece al tocar un animal
  void _showScanModeSelector(BuildContext context, Animal animal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selecciona el modo para ${animal.name}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.nfc_rounded, color: Colors.blue),
                title: const Text('Identificar por Microchip'),
                subtitle: const Text('Usa el escáner de la app'),
                onTap: () {
                  context.pop();
                  context.push('${AppRoutes.scanCapture}/${animal.id}/chip');
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.green),
                title: const Text('Escaneo Visual (IA)'),
                subtitle: const Text('Solo fotos, sin microchip'),
                onTap: () {
                  context.pop();
                  context.push('${AppRoutes.scanCapture}/${animal.id}/nochip');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal, required this.onTap});
  final Animal animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.asset(
                animal.assetImage,
                fit: BoxFit.cover,
                // Si la imagen no carga, mostramos un color sólido con un icono
                errorBuilder: (context, error, stackTrace) => Container(
                  color: cs.primaryContainer,
                  child: const Icon(Icons.pets, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    animal.name,
                    style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text('Escanear', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
