import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/role_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/esge_ui.dart';
import '../dashboard/home_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.role = UserRole.dg});
  final UserRole role;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool hidden = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: EsgeGlowBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    const BrandMark(compact: true),
                  ],
                ),
                const SizedBox(height: 46),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.indigo.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.role.icon, color: AppColors.indigo, size: 17),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Espace ${widget.role.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.indigo,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Heureux de vous revoir 👋',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connectez-vous pour continuer vers votre espace sécurisé.',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    height: 1.45,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 32),
                _label('E-mail ou identifiant'),
                const SizedBox(height: 8),
                const TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                    hintText: 'vous@esge.com',
                  ),
                ),
                const SizedBox(height: 16),
                _label('Mot de passe'),
                const SizedBox(height: 8),
                TextField(
                  obscureText: hidden,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => hidden = !hidden),
                      icon: Icon(
                        hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _forgotPassword(context),
                    child: const Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                EsgeGradientButton(
                  label: 'Se connecter',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    context.read<AuthCubit>().signInAs(widget.role);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeShell()),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'accès sécurisé',
                        style: TextStyle(color: AppColors.muted, fontSize: 10),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _securityCard(
                        Icons.fingerprint_rounded,
                        'Biométrie',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _securityCard(
                        Icons.shield_outlined,
                        'Session sécurisée',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.soft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: AppColors.tealDark,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Les accès, validations sensibles et sessions sont journalisés et protégés selon le rôle.',
                          style: TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 10.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _label(String value) => Text(
    value,
    style: const TextStyle(
      color: AppColors.textSoft,
      fontWeight: FontWeight.w800,
      fontSize: 10.5,
    ),
  );

  Widget _securityCard(IconData icon, String label) => Container(
    height: 56,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19, color: AppColors.cyan),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  void _forgotPassword(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQueryData.fromView(View.of(context)).viewPadding.bottom +
            24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mot de passe oublié ?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          const Text(
            'Un code de vérification sera envoyé à votre adresse professionnelle.',
            style: TextStyle(color: AppColors.textSoft, fontSize: 11),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(labelText: 'Adresse e-mail'),
          ),
          const SizedBox(height: 14),
          EsgeGradientButton(
            label: 'Envoyer le code',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}
