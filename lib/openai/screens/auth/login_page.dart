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
    await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu correo electrónico registrado.'),
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
              // Color sólido oscuro para que no se vea transparente
              color: const Color(0xFF1A1A1A), 
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Image.asset(
                        'assets/icons/logos_app.png', // Corregido el nombre si era logo_app.png
                        height: 150,
                        width: 150,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // CAMPO USUARIO
                      TextFormField(
                        controller: _usernameCtrl,
                        style: const TextStyle(color: Colors.white), // TEXTO BLANCO AL ESCRIBIR
                        decoration: InputDecoration(
                          labelText: strings('username'),
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.person_rounded, color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1), // Fondo sutil para el input
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Completa el usuario' : null,
                        textInputAction: TextInputAction.next,
                        cursorColor: Colors.white,
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // CAMPO CONTRASEÑA
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white), // TEXTO BLANCO AL ESCRIBIR
                        decoration: InputDecoration(
                          labelText: strings('password'),
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock_rounded, color: Colors.white),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: Colors.white),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Completa la contraseña' : null,
                        onFieldSubmitted: (_) => _submit(),
                        cursorColor: Colors.white,
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
                      
                      // BOTÓN LOGIN
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: auth.isLoading ? null : _submit,
                          icon: const Icon(Icons.login_rounded),
                          label: Text(strings('login').toUpperCase(), 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // BOTÓN REGISTRO
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.push(AppRoutes.register),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: t.colorScheme.primary)),
                          child: Text(strings('register')),
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          icon: Icon(Icons.translate_rounded, color: cs.onSurface),
          items: AppStrings.supportedLocales
              .map((l) => DropdownMenuItem(
                    value: l.languageCode,
                    child: Text(AppStrings.languageLabel(l.languageCode)),
                  ))
              .toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}
