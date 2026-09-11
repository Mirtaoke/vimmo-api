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
  late final PageController _roleController = PageController(
    initialPage: UserRole.values.indexOf(selected),
    viewportFraction: .78,
  );

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

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
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        controller: _roleController,
                        itemCount: UserRole.values.length,
                        onPageChanged: (i) =>
                            setState(() => selected = UserRole.values[i]),
                        itemBuilder: (_, i) => AnimatedBuilder(
                          animation: _roleController,
                          builder: (_, child) {
                            var distance = 0.0;
                            if (_roleController.hasClients &&
                                _roleController.position.haveDimensions) {
                              distance = (_roleController.page! - i)
                                  .abs()
                                  .clamp(0, 1);
                            }
                            return Transform.scale(
                              scale: 1 - (distance * .1),
                              child: Opacity(
                                opacity: 1 - (distance * .28),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 10,
                            ),
                            child: _card(UserRole.values[i]),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        UserRole.values.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: UserRole.values[i] == selected ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: UserRole.values[i] == selected
                                ? AppColors.green
                                : AppColors.line,
                            borderRadius: BorderRadius.circular(20),
                          ),
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

  Widget _card(UserRole role) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EsgeIconBadge(
                    icon: role.icon,
                    color: active ? AppColors.green : AppColors.aqua,
                    size: 62,
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: active
                        ? const Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey('checked'),
                            color: AppColors.green,
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
                  color: active ? Colors.white : AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_count(role)} modules autorisés',
                style: TextStyle(
                  color: active ? Colors.white70 : AppColors.textSoft,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _count(role) / 9,
                minHeight: 5,
                color: AppColors.green,
                backgroundColor: active ? Colors.white24 : AppColors.line,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _count(UserRole r) => switch (r) {
    UserRole.admin => 9,
    UserRole.dg => 8,
    UserRole.comptable => 4,
    UserRole.secretaire => 2,
    UserRole.caissier || UserRole.magasinier || UserRole.commercial => 3,
  };
}
