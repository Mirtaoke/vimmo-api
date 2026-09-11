import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/esge_ui.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final formKey = GlobalKey<FormState>();
  final currentController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmationController = TextEditingController();
  bool showCurrent = false;
  bool showPassword = false;

  @override
  void dispose() {
    currentController.dispose();
    passwordController.dispose();
    confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Changer le mot de passe')),
    body: EsgeGlowBackground(
      child: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              EsgeGlassCard(
                gradient: LinearGradient(
                  colors: [
                    AppColors.indigo.withValues(alpha: .12),
                    AppColors.plum.withValues(alpha: .08),
                  ],
                ),
                child: const Row(
                  children: [
                    EsgeIconBadge(
                      icon: Icons.lock_reset_rounded,
                      color: AppColors.plum,
                      size: 48,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Utilisez au moins 8 caractères avec une majuscule et un chiffre.',
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _passwordField(
                currentController,
                'Mot de passe actuel',
                showCurrent,
                () => setState(() => showCurrent = !showCurrent),
              ),
              _passwordField(
                passwordController,
                'Nouveau mot de passe',
                showPassword,
                () => setState(() => showPassword = !showPassword),
              ),
              _passwordField(
                confirmationController,
                'Confirmer le mot de passe',
                showPassword,
                () => setState(() => showPassword = !showPassword),
              ),
              const SizedBox(height: 8),
              EsgeGradientButton(
                label: 'Mettre à jour le mot de passe',
                icon: Icons.shield_outlined,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _passwordField(
    TextEditingController controller,
    String label,
    bool visible,
    VoidCallback toggle,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.password_rounded),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Champ obligatoire';
        if (controller != currentController && value.length < 8) {
          return '8 caractères minimum';
        }
        if (controller == confirmationController &&
            value != passwordController.text) {
          return 'Les mots de passe ne correspondent pas';
        }
        return null;
      },
    ),
  );

  void _save() {
    if (!formKey.currentState!.validate()) return;
    currentController.clear();
    passwordController.clear();
    confirmationController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe mis à jour avec succès.')),
    );
  }
}
