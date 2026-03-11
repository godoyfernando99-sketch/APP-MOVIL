import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/auth/auth_controller.dart';
import '../../../../nav.dart'; 
import '../../../../widgets/farm_background_scaffold.dart';

// Páginas de las pestañas
import '../history/history_page.dart';
import '../info/medications_page.dart';
import '../info/diseases_page.dart';
import '../subscriptions/subscriptions_page.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _selectedIndex = 0;
  final InAppReview _inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkReviewStatus();
    });
  }

  Future<void> _checkReviewStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool alreadyRated = prefs.getBool('already_rated') ?? false;

    if (!alreadyRated) {
      await Future.delayed(const Duration(seconds: 8));
      if (!mounted) return;
      _showRateDialog(prefs);
    }
  }

  void _showRateDialog(SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(color: Colors.greenAccent.withOpacity(0.3)),
        ),
        title: const Column(
          children: [
            Icon(Icons.stars_rounded, color: Colors.amber, size: 50),
            SizedBox(height: 10),
            Text("¿Te gusta ScannerAnimal?", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Tu calificación nos ayuda a mejorar nuestra IA y seguir salvando ejemplares.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("MÁS TARDE", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await prefs.setBool('already_rated', true);
              if (await _inAppReview.isAvailable()) {
                await _inAppReview.requestReview();
              } else {
                final url = Uri.parse("https://play.google.com/store/apps/details?id=com.scanneranimal.app");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text("CALIFICAR"),
          ),
        ],
      ),
    );
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
      actions: [
        IconButton(
          icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
          onPressed: () => authController.signOut(), 
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
        children: [
          MainMenuContent(onTabRequested: _onItemTapped), 
          const HistoryPage(),       
          const MedicationsPage(),   
          const DiseasesPage(),      
          const SubscriptionsPage(), 
        ],
      ),
    );
  }
}

class MainMenuContent extends StatelessWidget {
  final Function(int) onTabRequested;
  const MainMenuContent({super.key, required this.onTabRequested});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    // CORRECCIÓN: Aseguramos que los nombres de los campos existan en tu AuthController/User model
    final bool isPro = user?.isPro ?? false; 
    final int scansAvailable = user?.scansRemaining ?? 0;
    final int maxScans = user?.maxScansByPlan ?? 10;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildHeader(user?.fullName ?? user?.username ?? 'Usuario', isPro),
          const SizedBox(height: 30),
          _buildEnhancedCounter(isPro, scansAvailable, maxScans),
          const SizedBox(height: 40),
          const Text("MODO DE ESCANEO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 25),

          _ScanButton(
            title: "Escaneo por Microchip",
            subtitle: "Detectar ID y proximidad",
            icon: Icons.nfc_rounded,
            color: Colors.blueAccent,
            onTap: () => _handleScanAccess(context, isPro, scansAvailable),
          ),

          const SizedBox(height: 16),

          _ScanButton(
            title: "Escaneo Visual",
            subtitle: "Análisis completo por fotografía",
            icon: Icons.auto_awesome_rounded,
            color: Colors.greenAccent,
            onTap: () => _handleScanAccess(context, isPro, scansAvailable),
          ),

          const SizedBox(height: 40),
          // CORRECCIÓN: Acceso estático a AppRoutes
          if (isPro) _SupportButton(onTap: () => context.push(AppRoutes.support)),
        ],
      ),
    );
  }

  void _handleScanAccess(BuildContext context, bool isPro, int available) {
    if (!isPro && available <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("⚠️ Has agotado tus escaneos gratuitos."),
          backgroundColor: Colors.redAccent,
          action: SnackBarAction(
            label: "VER PLANES",
            textColor: Colors.white,
            onPressed: () => onTabRequested(4), 
          ),
        ),
      );
    } else {
      // CORRECCIÓN: Acceso estático a AppRoutes.scanVisual
      context.push(AppRoutes.scanVisual, extra: {'animalId': 'generic', 'mode': 'visual'});
    }
  }

  Widget _buildHeader(String name, bool isPro) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('¡Hola, $name!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            if (isPro) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.stars_rounded, color: Colors.amber, size: 28)),
          ],
        ),
        const Text('¿Cómo identificaremos al animal hoy?', style: TextStyle(color: Colors.white70, fontSize: 15)),
      ],
    );
  }

  Widget _buildEnhancedCounter(bool isPro, int available, int max) {
    double progress = isPro ? 1.0 : (available / max).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isPro ? Colors.amber.withOpacity(0.5) : Colors.white10, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isPro ? "PLAN PREMIUM" : "PLAN BÁSICO", style: TextStyle(color: isPro ? Colors.amber : Colors.greenAccent, fontWeight: FontWeight.bold)),
              Text(isPro ? "ILIMITADO" : "$available / $max", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white10, color: isPro ? Colors.amber : Colors.greenAccent),
        ],
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
        onTap: onTap,
        leading: Icon(icon, color: color, size: 35),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blue.shade900])),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        onPressed: onTap,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(Icons.headset_mic_rounded, color: Colors.white), SizedBox(width: 12), Text("SOPORTE VIP 24/7", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
        ),
      ),
    );
  }
}