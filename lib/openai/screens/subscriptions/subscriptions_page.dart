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

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    setState(() => _isLoading = true);
    await _subscriptionService.initialize();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _purchasePlan(String planId) async {
    final auth = context.read<AuthController>();

    // Si las compras in-app están disponibles, intentar usar la tienda nativa
    if (_subscriptionService.isAvailable &&
        _subscriptionService.products.isNotEmpty) {
      final product = _subscriptionService.products.firstWhere(
        (p) => p.id.contains(planId),
        orElse: () => _subscriptionService.products.first,
      );

      await _subscriptionService.buyProduct(product, (purchasedPlanId) async {
        await auth.updateSubscription(purchasedPlanId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('¡Plan $purchasedPlanId activado correctamente!')),
        );
      });
    } else {
      // Si no está disponible, activar directamente (para testing o web)
      await auth.updateSubscription(planId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Platform.isAndroid || Platform.isIOS
                ? 'Las compras in-app no están disponibles en este momento. Plan activado para prueba.'
                : 'Compras in-app no disponibles en web. Plan activado para prueba.',
          ),
        ),
      );
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
    final currentPlan = auth.currentUser?.subscriptionPlan ?? 'free';

    if (_isLoading) {
      return FarmBackgroundScaffold(
        title: strings('subscriptions'),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return FarmBackgroundScaffold(
      title: strings('subscriptions'),
      child: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          if (currentPlan != 'free')
            Card(
              color: t.colorScheme.primaryContainer,
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: t.colorScheme.primary, size: 32),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan Actual',
                            style: t.textTheme.labelMedium,
                          ),
                          Text(
                            _getPlanName(currentPlan),
                            style: t.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (currentPlan != 'free') const SizedBox(height: 14),
          _PlanCard(
            name: 'Plan Básico',
            priceLabel: currency.formatUsd(6.99, locale),
            accent: t.colorScheme.primaryContainer,
            features: const [
              '15 escaneos mensuales',
              'Diagnóstico básico',
              'Historial de escaneos',
              'Soporte estándar'
            ],
            isCurrentPlan: currentPlan == 'basic',
            onSelectPlan:
                currentPlan == 'basic' ? null : () => _purchasePlan('basic'),
          ),
          const SizedBox(height: 14),
          _PlanCard(
            name: 'Plan Premium',
            priceLabel: currency.formatUsd(12.99, locale),
            accent: t.colorScheme.secondaryContainer,
            features: const [
              '30 escaneos mensuales',
              'Diagnóstico completo',
              'Historial ilimitado',
              'Soporte prioritario'
            ],
            isCurrentPlan: currentPlan == 'intermediate',
            onSelectPlan: currentPlan == 'intermediate'
                ? null
                : () => _purchasePlan('intermediate'),
          ),
          const SizedBox(height: 14),
          _PlanCard(
            name: 'Plan PRO',
            priceLabel: currency.formatUsd(29.99, locale),
            accent: t.colorScheme.tertiaryContainer,
            features: const [
              'Escaneos ilimitados',
              'Diagnóstico avanzado con IA',
              'Lista completa de medicamentos',
              'Base de datos de enfermedades',
              'Reportes detallados',
              'Soporte VIP 24/7'
            ],
            recommended: true,
            isCurrentPlan: currentPlan == 'pro',
            onSelectPlan:
                currentPlan == 'pro' ? null : () => _purchasePlan('pro'),
          ),
        ],
      ),
    );
  }

  String _getPlanName(String planId) {
    switch (planId) {
      case 'basic':
        return 'Plan Básico';
      case 'intermediate':
        return 'Plan Intermedio';
      case 'pro':
        return 'Plan PRO';
      default:
        return 'Plan Gratuito';
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
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Card(
      elevation: recommended ? 4 : 1,
      child: Container(
        decoration: recommended
            ? BoxDecoration(
                border: Border.all(color: cs.primary, width: 2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              )
            : null,
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'RECOMENDADO',
                    style: t.textTheme.labelSmall?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (recommended) const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: t.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      priceLabel,
                      style: t.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f, style: t.textTheme.bodyMedium)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: isCurrentPlan
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: Icon(Icons.check_rounded, color: cs.primary),
                        label: Text('Plan Actual',
                            style: TextStyle(color: cs.primary)),
                      )
                    : FilledButton.icon(
                        onPressed: onSelectPlan,
                        icon: Icon(Icons.shopping_cart_rounded,
                            color: cs.onPrimary),
                        label: Text('Elegir plan',
                            style: TextStyle(color: cs.onPrimary)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
