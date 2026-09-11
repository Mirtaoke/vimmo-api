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
    appBar: AppBar(
      toolbarHeight: 56,
      title: const Text(
        'Changer le mot de passe',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    ),
    body: EsgeGlowBackground(
      child: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF33264F), Color(0xFF9B5C8F)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.plum.withValues(alpha: .22),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sécurisez votre compte',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '8 caractères, une majuscule et un chiffre minimum.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA8F0C5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'NOUVEAUX IDENTIFIANTS',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140B281E),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: List.generate(
                          4,
                          (index) => Expanded(
                            child: Container(
                              height: 4,
                              margin: EdgeInsets.only(
                                right: index == 3 ? 0 : 5,
                              ),
                              decoration: BoxDecoration(
                                color: index < 3
                                    ? AppColors.plum
                                    : AppColors.line,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      obscureText: !visible,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10.5),
        prefixIcon: const Icon(Icons.password_rounded, size: 18),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            visible ? Icons.visibility_off : Icons.visibility,
            size: 18,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
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
