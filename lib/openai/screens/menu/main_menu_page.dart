import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);
    final auth = context.watch<AuthController>();

    return FarmBackgroundScaffold(
      title: strings('mainMenu'),
      showBack: false,
      showHome: false,
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.settings, color: t.colorScheme.onSurface),
          onSelected: (v) {
            switch (v) {
              case 'history':
                context.push(AppRoutes.history);
                break;
              case 'subscriptions':
                context.push(AppRoutes.subscriptions);
                break;
              case 'diseases':
                context.push(AppRoutes.diseases);
                break;
              case 'medications':
                context.push(AppRoutes.medications);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'history', child: Text(strings('history'))),
            PopupMenuItem(
                value: 'subscriptions', child: Text(strings('subscriptions'))),
            PopupMenuItem(value: 'diseases', child: Text(strings('diseases'))),
            PopupMenuItem(
                value: 'medications', child: Text(strings('medications'))),
          ],
        ),
      ],
      child: Center(
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Color(0xFFE5F1F1),
                    child: Padding(
                      padding: AppSpacing.paddingLg,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: t.colorScheme.primaryContainer,
                            child: Icon(Icons.person_rounded,
                                color: t.colorScheme.onPrimaryContainer),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.currentUser?.fullName.isNotEmpty == true
                                      ? auth.currentUser!.fullName
                                      : (auth.currentUser?.username ?? ''),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                          color: Color(0xFF0D0D0D),
                                          fontFamily:
                                              GoogleFonts.poppins().fontFamily),
                                ),
                                const SizedBox(height: 2),
                                Text('Scanner Animal',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                            color: Color(0xFF1D9705),
                                            fontFamily: GoogleFonts.poppins()
                                                .fontFamily)),
                                const SizedBox(height: AppSpacing.md),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () async {
                                      await context
                                          .read<AuthController>()
                                          .logout();
                                      if (!context.mounted) return;
                                      context.go(AppRoutes.login);
                                    },
                                    icon: Icon(Icons.logout_rounded,
                                        color:
                                            t.colorScheme.onSecondaryContainer),
                                    label: Text(strings('logout'),
                                        style: TextStyle(
                                            color: t.colorScheme
                                                .onSecondaryContainer)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Align(
                                alignment: Alignment.center,
                                child: Flexible(
                                  flex: 9,
                                  child: _CategoryButton(
                                    title: strings('homeAnimals'),
                                    icon: Icons.home_rounded,
                                    onPressed: () => context.push(
                                        '${AppRoutes.animals}?category=home'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _CategoryButton(
                              title: strings('farmAnimals'),
                              icon: Icons.agriculture_rounded,
                              onPressed: () => context
                                  .push('${AppRoutes.animals}?category=farm'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton(
      {required this.title, required this.icon, required this.onPressed});
  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Card(
      color: Color(0xFF23764D),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          splashFactory: NoSplash.splashFactory,
          highlightColor: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              children: [
                Icon(icon, size: 36, color: t.colorScheme.primary),
                const SizedBox(height: AppSpacing.sm),
                Text(title,
                    style: t.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
