import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/app_settings.dart';
import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/l10n/app_strings.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final err = await auth.login(
        username: _usernameCtrl.text.trim(), password: _passwordCtrl.text);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    context.go(AppRoutes.welcome);
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Ingresa tu correo electrónico registrado para restablecer tu contraseña.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_rounded),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, emailCtrl.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final auth = context.read<AuthController>();
      final err = await auth.resetPassword(email: result);
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Se ha enviado un correo para restablecer tu contraseña.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final strings = (String key) => AppStrings.of(context, key);
    final auth = context.watch<AuthController>();
    final settings = context.watch<AppSettings>();

    return FarmBackgroundScaffold(
      title: 'Scanner Animal',
      showBack: false,
      showHome: false,
      actions: [
        _LanguagePicker(
            current: settings.locale.languageCode,
            onChanged: (code) => settings.setLocaleCode(code)),
      ],
      child: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: Color(0xFF0D0D0D),
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Image.asset(
                        'images/icono_appp.png',
                        height: 170,
                        fit: BoxFit.cover,
                        width: 170,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: InputDecoration(
                          labelText: strings('username'),
                          prefixIcon: Icon(Icons.person_rounded,
                              color: Color(0xFFFFFFFF)),
                          focusedBorder: OutlineInputBorder(),
                          fillColor: Color(0xFFFFFFFF),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Completa el usuario'
                            : null,
                        textInputAction: TextInputAction.next,
                        cursorColor: Color(0xFFFFFFFF),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: strings('password'),
                          prefixIcon: Icon(Icons.lock_rounded,
                              color: Color(0xFFFFFFFF)),
                          suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: Color(0xFFFFFFFF)),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword)),
                          focusedBorder: InputBorder.none,
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Completa la contraseña'
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                        cursorColor: Color(0xFFFFFFFF),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: t.colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: auth.isLoading ? null : _submit,
                          icon: Icon(Icons.login_rounded,
                              color: t.colorScheme.onPrimary),
                          label: Text(
                            strings('login'),
                            style: TextStyle(color: t.colorScheme.onPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(AppRoutes.register),
                          icon: Icon(Icons.person_add_alt_rounded,
                              color: t.colorScheme.primary),
                          label: Text(
                            strings('register'),
                            style: TextStyle(color: t.colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.current, required this.onChanged});
  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          icon: Icon(Icons.translate_rounded, color: cs.onSurface),
          items: AppStrings.supportedLocales
              .map(
                (l) => DropdownMenuItem(
                  value: l.languageCode,
                  child: Text(AppStrings.languageLabel(l.languageCode)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
