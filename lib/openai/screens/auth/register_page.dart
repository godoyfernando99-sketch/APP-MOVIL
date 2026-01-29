import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:scanneranimal/app/auth/auth_controller.dart';
import 'package:scanneranimal/nav.dart';
import 'package:scanneranimal/theme.dart';
import 'package:scanneranimal/widgets/farm_background_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  DateTime? _birthDate;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: _birthDate ?? DateTime(now.year - 18),
    );
    if (selected == null) return;
    setState(() => _birthDate = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona fecha de nacimiento.')));
      return;
    }
    final auth = context.read<AuthController>();
    final err = await auth.register(
      username: _usernameCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      birthDateIso: _birthDate!.toIso8601String(),
      password: _passwordCtrl.text,
    );
    
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso. Verifica tu correo electrónico y luego inicia sesión.')));
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final auth = context.watch<AuthController>();
    final birthLabel = _birthDate == null
        ? 'Fecha de nacimiento'
        : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}';

    return FarmBackgroundScaffold(
      title: 'Registro',
      child: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _firstNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre(s)',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _lastNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Apellidos',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_rounded)),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Correo inválido'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _usernameCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Nombre de usuario',
                              prefixIcon: Icon(Icons.account_circle_rounded)),
                          validator: (v) =>
                              (v == null || v.trim().length < 3)
                                  ? 'Mínimo 3 caracteres'
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: _pickBirthDate,
                          icon: Icon(Icons.cake_rounded,
                              color: t.colorScheme.primary),
                          label: Text(birthLabel,
                              style:
                                  TextStyle(color: t.colorScheme.primary)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_rounded)),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Mínimo 6 caracteres'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: auth.isLoading ? null : _submit,
                            icon: Icon(Icons.check_circle_rounded,
                                color: t.colorScheme.onPrimary),
                            label: Text('Registrar',
                                style: TextStyle(color: t.colorScheme.onPrimary)),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                            'Tu cuenta se creará en Firebase. Asegúrate de que la autenticación esté habilitada.',
                            style: t.textTheme.bodySmall),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: const Text('Volver a iniciar sesión')),
                      ],
                    ),
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
