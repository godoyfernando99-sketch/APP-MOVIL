import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/auth/auth_controller.dart';
import '../../../../nav.dart';
import '../../../../widgets/farm_background_scaffold.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 1: context.push(AppRoutes.history); break;
      case 2: context.push(AppRoutes.medications); break;
      case 3: context.push(AppRoutes.diseases); break;
      case 4: context.push(AppRoutes.subscriptions); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    return FarmBackgroundScaffold(
      title: 'ScannerAnimal IA',
      backgroundColor: Colors.transparent,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black.withOpacity(0.95),
          selectedItemColor: Colors.greenAccent,
          unselectedItemColor: Colors.white54,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Historial'),
            BottomNavigationBarItem(icon: Icon(Icons.vaccines_rounded), label: 'Medicinas'),
            BottomNavigationBarItem(icon: Icon(Icons.sick_rounded), label: 'Salud'),
            BottomNavigationBarItem(icon: Icon(Icons.star_rounded), label: 'PRO'),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildHeader(user?.fullName ?? user?.username ?? 'Usuario'),
            const SizedBox(height: 50),
            
            const Text(
              "MODO DE ESCANEO",
              style: TextStyle(
                color: Colors.white70, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 2,
                fontSize: 13
              ),
            ),
            const SizedBox(height: 25),

            // BOTÓN MICROCHIP: Envía a captura con instrucción de detectar ID
            _ScanButton(
              title: "Escaneo por Microchip",
              subtitle: "Detectar ID mediante fotos y proximidad",
              icon: Icons.nfc_rounded,
              color: Colors.blueAccent,
              onTap: () => context.push(AppRoutes.capture, extra: {'type': 'microchip', 'step': 'photos'}),
            ),

            const SizedBox(height: 16),

            // BOTÓN VISUAL: Envía a captura normal
            _ScanButton(
              title: "Escaneo Visual",
              subtitle: "Análisis completo por fotografía",
              icon: Icons.auto_awesome_rounded,
              color: Colors.greenAccent,
              onTap: () => context.push(AppRoutes.capture, extra: {'type': 'visual'}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Column(
      children: [
        Text(
          '¡Hola, $name!',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        const Text(
          '¿Cómo identificaremos a la mascota hoy?',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 15),
        ),
      ],
    );
  }
}

class _ScanButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ScanButton({
    required this.title, 
    required this.subtitle, 
    required this.icon, 
    required this.color, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        onTap: onTap,
        leading: Icon(icon, color: color, size: 35),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
      ),
    );
  }
}
                
