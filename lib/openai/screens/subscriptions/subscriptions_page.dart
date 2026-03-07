import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/app_settings.dart';
import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/app/subscription/subscription_service.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  final _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  bool _isPurchasing = false; 

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _subscriptionService.initialize();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _purchasePlan(String planId) async {
    if (_isPurchasing) return;

    final auth = context.read<AuthController>();
    setState(() => _isPurchasing = true);

    try {
      // Si estamos en un dispositivo real con la tienda disponible
      if (_subscriptionService.isAvailable && _subscriptionService.products.isNotEmpty) {
        final product = _subscriptionService.products.firstWhere(
          (p) => p.id.contains(planId),
          orElse: () => _subscriptionService.products.first,
        );

        // --- CORRECCIÓN DEL ERROR DE ARGUMENTOS ---
        // Llamamos a buyProduct solo con el producto.
        final success = await _subscriptionService.buyProduct(product);
        
        if (success) {
          // Si la compra fue exitosa en la tienda, actualizamos nuestra DB
          await auth.updateSubscription(planId);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade800,
              content: Text('¡Plan ${planId.toUpperCase()} activado correctamente!'),
            ),
          );
        }
      } else {
        // MODO DESARROLLO / WEB (Simulación)
        await auth.updateSubscription(planId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Platform.isAndroid || Platform.isIOS
                  ? 'Modo prueba: Plan activado localmente.'
                  : 'Plan activado para prueba web.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('🚨 Error en compra: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar la compra. Inténtalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);
    final settings = context.watch<AppSettings>();
    final auth = context.watch<AuthController>();

    final currency = settings.currency;
    final locale = settings.locale;
    final currentPlan = auth.currentUser?.subscriptionPlan?.toLowerCase() ?? 'free';

    return FarmBackgroundScaffold(
      title: strings('subscriptions'),
      backgroundColor: Colors.transparent,
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Stack( 
            children: [
              ListView(
                padding: AppSpacing.paddingLg,
                children: [
                  if (currentPlan != 'free') ...[
                    _buildCurrentPlanBanner(t, currentPlan),
                    const SizedBox(height: 20),
                  ],

                  _PlanCard(
                    name: 'Plan Básico',
                    priceLabel: currency.formatUsd(5.99, locale),
                    accent: Colors.blue.shade400,
                    features: const [
                      '15 escaneos mensuales',
                      'Diagnóstico básico',
                      'Historial de escaneos',
                      'Soporte estándar'
                    ],
                    isCurrentPlan: currentPlan == 'basic',
                    onSelectPlan: (currentPlan == 'basic' || _isPurchasing) ? null : () => _purchasePlan('basic'),
                  ),
                  const SizedBox(height: 16),
                  _PlanCard(
                    name: 'Plan Premium',
                    priceLabel: currency.formatUsd(10.99, locale),
                    accent: Colors.purple.shade400,
                    features: const [
                      '30 escaneos mensuales',
                      'Diagnóstico completo',
                      'Historial ilimitado',
                      'Soporte prioritario'
                    ],
                    isCurrentPlan: currentPlan == 'intermediate',
                    onSelectPlan: (currentPlan == 'intermediate' || _isPurchasing) ? null : () => _purchasePlan('intermediate'),
                  ),
                  const SizedBox(height: 16),
                  _PlanCard(
                    name: 'Plan PRO',
                    priceLabel: currency.formatUsd(13.99, locale),
                    accent: Colors.amber.shade400,
                    features: const [
                      'Escaneos ilimitados',
                      'Diagnóstico avanzado con IA',
                      'Lista completa de medicamentos',
                      'Base de datos de enfermedades',
                      'Soporte VIP 24/7'
                    ],
                    recommended: true,
                    isCurrentPlan: currentPlan == 'pro',
                    onSelectPlan: (currentPlan == 'pro' || _isPurchasing) ? null : () => _purchasePlan('pro'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
              if (_isPurchasing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.amber),
                        SizedBox(height: 16),
                        Text("Procesando pago...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildCurrentPlanBanner(ThemeData t, String planId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.greenAccent, size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ESTADO ACTUAL', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(_getPlanName(planId), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  String _getPlanName(String planId) {
    switch (planId) {
      case 'basic': return 'Plan Básico';
      case 'intermediate': return 'Plan Premium';
      case 'pro': return 'Plan PRO';
      default: return 'Plan Gratuito';
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.priceLabel,
    required this.features,
    required this.accent,
    this.recommended = false,
    this.isCurrentPlan = false,
    this.onSelectPlan,
  });

  final String name;
  final String priceLabel;
  final List<String> features;
  final Color accent;
  final bool recommended;
  final bool isCurrentPlan;
  final VoidCallback? onSelectPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: recommended ? accent : Colors.white.withOpacity(0.08),
          width: recommended ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recommended)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                child: const Text('MÁS POPULAR', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(priceLabel, style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
            const Divider(color: Colors.white12, height: 30),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: accent),
                  const SizedBox(width: 12),
                  Expanded(child: Text(f, style: const TextStyle(color: Colors.white70, fontSize: 14))),
                ],
              ),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: isCurrentPlan
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white12), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
                    ),
                    child: const Text('TU PLAN ACTUAL', style: TextStyle(color: Colors.white24)),
                  )
                : FilledButton(
                    onPressed: onSelectPlan,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent, 
                      foregroundColor: Colors.black, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('ADQUIRIR AHORA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}