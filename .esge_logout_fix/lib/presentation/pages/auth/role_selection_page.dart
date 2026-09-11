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
            final columns = box.maxWidth >= 720
                ? 3
                : box.maxWidth >= 390
                ? 2
                : 1;
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
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.heroGradient,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: .25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VOTRE ESPACE',
                                  style: TextStyle(
                                    color: AppColors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Quel est votre rôle ?',
                                  style: TextStyle(
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
                          EsgeIconBadge(
                            icon: Icons.badge_outlined,
                            color: AppColors.green,
                            size: 58,
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
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: columns == 1 ? 116 : 142,
                      ),
                      itemBuilder: (_, i) => TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 380 + (i * 65)),
                        curve: Curves.easeOutBack,
                        tween: Tween(begin: 0, end: 1),
                        builder: (_, value, child) => Transform.translate(
                          offset: Offset(0, 22 * (1 - value)),
                          child: Opacity(
                            opacity: value.clamp(0, 1),
                            child: child,
                          ),
                        ),
                        child: _card(
                          UserRole.values[i],
                          horizontal: columns == 1,
                        ),
                      ),
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

  Widget _card(UserRole role, {required bool horizontal}) {
    final active = role == selected;
    return InkWell(
      onTap: () => setState(() => selected = role),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        scale: active ? 1 : .97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0E4936), Color(0xFF0A2B22)],
                  )
                : null,
            color: active ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppColors.cyan.withValues(alpha: .65)
                  : AppColors.line,
              width: active ? 1.2 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: .2),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: horizontal
              ? Row(
                  children: [
                    EsgeIconBadge(
                      icon: role.icon,
                      color: active ? AppColors.green : AppColors.aqua,
                      size: 52,
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: _roleText(role)),
                    if (active)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.green,
                        size: 22,
                      ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        EsgeIconBadge(
                          icon: role.icon,
                          color: active ? AppColors.green : AppColors.aqua,
                          size: 43,
                        ),
                        const Spacer(),
                        if (active)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.green,
                            size: 20,
                          ),
                      ],
                    ),
                    const Spacer(),
                    _roleText(role),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _roleText(UserRole role) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        role.label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${_count(role)} modules autorisés',
        style: const TextStyle(color: AppColors.textSoft, fontSize: 9),
      ),
    ],
  );

  int _count(UserRole r) => switch (r) {
    UserRole.admin => 9,
    UserRole.dg => 8,
    UserRole.comptable => 4,
    UserRole.secretaire => 2,
    UserRole.caissier || UserRole.magasinier || UserRole.commercial => 3,
  };
}
