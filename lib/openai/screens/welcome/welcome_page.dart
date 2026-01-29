import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);

    return FarmBackgroundScaffold(
      title: strings('welcome'),
      showBack: false,
      child: Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pets_rounded, size: 52, color: t.colorScheme.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text('${strings('welcome')},', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(user?.fullName.isNotEmpty == true ? user!.fullName : (user?.username ?? ''), style: t.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.menu),
                        icon: Icon(Icons.arrow_forward_rounded, color: t.colorScheme.onPrimary),
                        label: Text(strings('continue'), style: TextStyle(color: t.colorScheme.onPrimary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
