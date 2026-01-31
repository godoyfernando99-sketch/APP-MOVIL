import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class AnimalsPage extends StatelessWidget {
  final String category;

  const AnimalsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final animals = AnimalsCatalog.animals
        .where((a) => a.category == category)
        .toList();

    return FarmBackgroundScaffold(
      title: category == 'home' ? 'ANIMALES DE CASA' : 'ANIMALES DE GRANJA',
      backgroundColor: Colors.transparent,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.85,
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

  void _showScanModeSelector(BuildContext context, Animal animal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212).withOpacity(0.95),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        side: BorderSide(color: Colors.white10),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arrastre
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),
              Text(
                'MODO DE ESCANEO',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                animal.name.toUpperCase(),
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              _ScanOptionTile(
                icon: Icons.nfc_rounded,
                title: 'Identificar por Microchip',
                subtitle: 'Usar sensor NFC de proximidad',
                color: Colors.blueAccent,
                onTap: () {
                  context.pop();
                  context.push('${AppRoutes.scanCapture}/${animal.id}/chip');
                },
              ),
              const SizedBox(height: 12),
              _ScanOptionTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Escaneo Visual (IA)',
                subtitle: 'Reconocimiento por fotografía',
                color: Colors.greenAccent,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), // Cristal ahumado
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(animal.assetImage, fit: BoxFit.cover),
                    // Gradiente para que el nombre se lea mejor
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  children: [
                    Text(
                      animal.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 12, color: Colors.blueAccent),
                        SizedBox(width: 4),
                        Text('LISTO PARA ESCANEAR', style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 0.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ScanOptionTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      tileColor: color.withOpacity(0.05),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
    );
  }
}
