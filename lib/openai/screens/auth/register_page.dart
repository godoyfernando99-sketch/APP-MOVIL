import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Asegúrate de agregar esta dependencia

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
  bool _acceptTerms = false; // Estado para el checkbox legal

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // Función para abrir los documentos legales
  Future<void> _openLegalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace.')),
        );
      }
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: _birthDate ?? DateTime(now.year - 18),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
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

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes aceptar los términos y condiciones.')));
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
        const SnackBar(content: Text('Registro exitoso. Inicia sesión.')));
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final auth = context.watch<AuthController>();
    final birthLabel = _birthDate == null
        ? 'Fecha de nacimiento'
        : 'Nacido el: ${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}';

    return FarmBackgroundScaffold(
      title: 'Crear Cuenta',
      backgroundColor: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15)
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_ind_rounded, color: Colors.white24, size: 48),
                    const SizedBox(height: 16),
                    const Text('REGISTRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(child: _buildField(_firstNameCtrl, 'Nombre', Icons.person_outline)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField(_lastNameCtrl, 'Apellidos', Icons.badge_outlined)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildField(_emailCtrl, 'Correo electrónico', Icons.email_outlined, type: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    
                    _buildField(_usernameCtrl, 'Usuario', Icons.account_circle_outlined),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: _pickBirthDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cake_outlined, color: _birthDate == null ? Colors.white38 : t.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(birthLabel, style: TextStyle(color: _birthDate == null ? Colors.white38 : Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildField(_passwordCtrl, 'Contraseña', Icons.lock_outline, obscure: true),
                    const SizedBox(height: 20),

                    // SECCIÓN LEGAL (TÉRMINOS Y PRIVACIDAD)
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                          activeColor: Colors.blueAccent,
                          side: const BorderSide(color: Colors.white38),
                        ),
                        Expanded(
                          child: Wrap(
                            children: [
                              const Text('Acepto los ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              GestureDetector(
                                onTap: () => _openLegalUrl('https://tuweb.com/terminos'),
                                child: const Text('Términos y Condiciones', 
                                  style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const Text(' y la ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              GestureDetector(
                                onTap: () => _openLegalUrl('https://tuweb.com/privacidad'),
                                child: const Text('Política de Privacidad', 
                                  style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: auth.isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('REGISTRARSE', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('¿Ya tienes cuenta? Inicia sesión', style: TextStyle(color: Colors.white70))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, TextInputType? type}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
    );
  }
}
