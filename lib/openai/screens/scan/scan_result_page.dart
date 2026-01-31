import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/history/history_controller.dart';
import 'package:scanneranimal/app/history/scan_models.dart';
import 'package:scanneranimal/data/animals.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class ScanResultPage extends StatefulWidget {
  const ScanResultPage({super.key, this.payload});
  final dynamic payload;

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  bool _isSaved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoSave());
  }

  Future<void> _autoSave() async {
    if (!mounted || widget.payload is! ScanResult) return;
    final result = widget.payload as ScanResult;
    
    setState(() => _isSaving = true);
    try {
      await context.read<HistoryController>().add(result);
      if (!mounted) return;
      setState(() {
        _isSaved = true;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // CASO 1: ERROR O SIN DATOS
    if (widget.payload is! ScanResult) {
      return FarmBackgroundScaffold(
        title: 'ERROR',
        backgroundColor: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text('Sin datos del escaneo', 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.menu),
                  child: const Text('VOLVER AL MENÚ'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // CASO 2: RESULTADO EXITOSO
    final result = widget.payload as ScanResult;
    final animal = AnimalsCatalog.byId(result.animalId);

    final Color statusColor = result.healthStatus == 'buena' 
        ? Colors.greenAccent 
        : (result.healthStatus == 'regular' ? Colors.orangeAccent : Colors.redAccent);

    return FarmBackgroundScaffold(
      title: 'RESULTADO DEL EXAMEN',
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
              ),
              child: Column(
                children: [
                  // Icono y Estado Principal
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.analytics_outlined, color: statusColor, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ANÁLISIS COMPLETADO',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12),
                  ),
                  const SizedBox(height: 24),

                  // Información del Animal
                  _buildResultRow('Especie:', animal.name, Icons.pets),
                  _buildResultRow('Salud:', result.healthStatus.toUpperCase(), Icons.favorite, valueColor: statusColor),
                  // Usamos DateTime.now() si timestamp da error, o result.date si existe
                  _buildResultRow('Fecha:', DateTime.now().toString().substring(0, 16), Icons.calendar_today),
                  
                  const SizedBox(height: 32),
                  
                  // Botón de Salida
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blueAccent,
                      ),
                      onPressed: () => context.go(AppRoutes.menu),
                      icon: const Icon(Icons.home),
                      label: const Text('VOLVER AL INICIO'),
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

  // FUNCIÓN AUXILIAR PARA LAS FILAS (La que faltaba)
  Widget _buildResultRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.white, fontSize: 15),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
