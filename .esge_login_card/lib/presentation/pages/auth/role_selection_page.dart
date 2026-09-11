import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/role_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/esge_ui.dart';
import '../dashboard/home_shell.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});
  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  UserRole selected = UserRole.dg;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: EsgeGlowBackground(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (_, box) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                          ),
                        ),
                        const Spacer(),
                        const BrandMark(compact: true),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.tealDark, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x130B382A),
                            blurRadius: 28,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 82,
                            decoration: BoxDecoration(
                              color: AppColors.tealDark,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VOTRE ESPACE',
                                  style: TextStyle(
                                    color: AppColors.tealDark,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Quel est votre rôle ?',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.8,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Un tableau de bord adapté à vos responsabilités.',
                                  style: TextStyle(
                                    color: AppColors.textSoft,
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: const Icon(
                              Icons.badge_outlined,
                              color: AppColors.tealDark,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: UserRole.values.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: box.maxWidth >= 700 ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 176,
                      ),
                      itemBuilder: (_, index) => _card(UserRole.values[index]),
                    ),
                    const SizedBox(height: 22),
                    EsgeGradientButton(
                      label: 'Continuer comme ${selected.label}',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        context.read<AuthCubit>().signInAs(selected);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeShell()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _card(UserRole role) {
    final active = role == selected;
    const accent = AppColors.violet;
    return InkWell(
      onTap: () => setState(() => selected = role),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        scale: active ? 1 : .97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? AppColors.mint : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: active ? AppColors.tealDark : AppColors.line,
              width: active ? 2.2 : 1.4,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: .22),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EsgeIconBadge(icon: role.icon, color: accent, size: 44),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: active
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey('checked'),
                            color: accent,
                            size: 25,
                          )
                        : const Icon(
                            Icons.circle_outlined,
                            key: ValueKey('empty'),
                            color: AppColors.muted,
                            size: 22,
                          ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                role.label,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _description(role),
                style: TextStyle(color: AppColors.textSoft, fontSize: 9),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _description(UserRole role) => switch (role) {
    UserRole.admin => 'Utilisateurs, droits, sécurité et audit',
    UserRole.dg => 'Pilotage global, validations et rapports',
    UserRole.comptable => 'Contrôle comptable et rapprochements',
    UserRole.secretaire => 'Prestataires, dossiers et rendez-vous',
    UserRole.caissier => 'Encaissements, caisse et justificatifs',
    UserRole.magasinier => 'Stock, inventaires et mouvements',
    UserRole.commercial => 'Prospects, clients et opportunités',
  };
}
