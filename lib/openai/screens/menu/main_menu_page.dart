import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/auth/auth_controller.dart';
import '../../../../widgets/farm_background_scaffold.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _selectedIndex = 0;

  // Lista de vistas para mantener la barra de navegación siempre visible
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const MainMenuContent(), // El menú principal que ves abajo
      const Center(child: Text("Historial", style: TextStyle(color: Colors.white, fontSize: 18))), 
      const Center(child: Text("Medicamentos", style: TextStyle(color: Colors.white, fontSize: 18))),
      const Center(child: Text("Salud", style: TextStyle(color: Colors.white, fontSize: 18))),
      const Center(child: Text("Suscripciones", style: TextStyle(color: Colors.white, fontSize: 18))),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return FarmBackgroundScaffold(
      title: 'ScannerAnimal IA',
      backgroundColor: Colors.transparent,
      // BOTÓN DE CERRAR SESIÓN EN EL APPBAR
      actions: [
        IconButton(
          icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
          onPressed: () => authController.signOut(),
          tooltip: 'Cerrar Sesión',
        ),
      ],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black.withOpacity(0.95),
          selectedItemColor: Colors.greenAccent,
          unselectedItemColor: Colors.white54,
          showUnselectedLabels: true,
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
      child: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }
}

class MainMenuContent extends StatelessWidget {
  const MainMenuContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;
    final isPro = user?.isPremium ?? false; 
    final scanLimit = 5;
    final scansDone = user?.scanCount ?? 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildHeader(user?.fullName ?? user?.username ?? 'Usuario', isPro),
          
          const SizedBox(height: 30),
          
          // BARRA DE CONTEO PERSONALIZADA
          _buildEnhancedCounter(isPro, scansDone, scanLimit),
          
          const SizedBox(height: 40),

          // TEXTO CON DELINEADO (Shadows para simular borde negro)
          Text(
            "MODO DE ESCANEO",
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.black, 
              letterSpacing: 2,
              fontSize: 14,
              shadows: [
                Shadow(offset: Offset(1.5, 1.5), blurRadius: 1, color: Colors.black),
                Shadow(offset: Offset(-1.5, -1.5), blurRadius: 1, color: Colors.black),
                Shadow(offset: Offset(1.5, -1.5), blurRadius: 1, color: Colors.black),
                Shadow(offset: Offset(-1.5, 1.5), blurRadius: 1, color: Colors.black),
              ],
            ),
          ),
          const SizedBox(height: 25),

          _ScanButton(
            title: "Escaneo por Microchip",
            subtitle: "Detectar ID mediante fotos y proximidad",
            icon: Icons.nfc_rounded,
            color: Colors.blueAccent,
            onTap: () {}, 
          ),

          const SizedBox(height: 16),

          _ScanButton(
            title: "Escaneo Visual",
            subtitle: "Análisis completo por fotografía",
            icon: Icons.auto_awesome_rounded,
            color: Colors.greenAccent,
            onTap: () {},
          ),

          const SizedBox(height: 40),

          // BOTÓN DE SOPORTE EXCLUSIVO PRO
          if (isPro) ...[
            _SupportButton(onTap: () {
               // Lógica soporte
            }),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(String name, bool isPro) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Hola, $name!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (isPro) const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '¿Cómo identificaremos a la mascota hoy?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white, 
            fontSize: 15, 
            shadows: [Shadow(blurRadius: 8, color: Colors.black)]
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedCounter(bool isPro, int count, int limit) {
    double progress = isPro ? 1.0 : (count / limit).clamp(0.0, 1.0);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isPro ? Colors.amber.withOpacity(0.5) : Colors.white10,
          width: 2
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPro ? "PLAN PREMIUM" : "PLAN BÁSICO",
                style: TextStyle(
                  color: isPro ? Colors.amber : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                isPro ? "Ilimitado" : "$count / $limit",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              color: isPro ? Colors.amber : Colors.greenAccent,
            ),
          ),
          if (!isPro) ...[
            const SizedBox(height: 10),
            const Text(
              "Pásate a PRO para escaneos infinitos",
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ]
        ],
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SupportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [Colors.blueAccent.withOpacity(0.8), Colors.blue.shade900]),
        boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.headset_mic_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  "CONTACTAR SOPORTE PRO",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ScanButton({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        onTap: onTap,
        leading: Icon(icon, color: color, size: 35),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
      ),
    );
  }
}