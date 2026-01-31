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
    final t = Theme.of(context);

    if (widget.payload is! ScanResult) {
      return FarmBackgroundScaffold(
        title: 'Error',
        backgroundColor: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text('Sin datos del escaneo', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.menu),
                  child: const Text('Volver al Menú'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final result = widget.payload as ScanResult;
    final animal = AnimalsCatalog.byId(result.animalId);

    // Definición de colores premium para los estados
    final Color statusColor = result.healthStatus == 'buena' 
        ? Colors.greenAccent 
        : (result.healthStatus == 'regular' ? Colors.orangeAccent : Colors.redAccent);

    return FarmBackgroundScaffold(
      title: 'Resultado
