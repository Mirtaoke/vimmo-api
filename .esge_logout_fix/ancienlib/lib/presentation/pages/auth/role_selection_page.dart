import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/role_extensions.dart';
import '../../../data/models/user_model.dart';
import '../dashboard/home_shell.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});
  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  UserRole selected = UserRole.dg;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.connectedCanvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, box) {
            final columns = box.maxWidth >= 600 ? 3 : 2;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Spacer(),
                        const Text(
                          'ESGE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Votre espace',
                      style: TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Choisissez le tableau de bord adapté à vos responsabilités.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 24),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: UserRole.values.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: box.maxWidth < 350 ? 0.86 : 1,
                      ),
                      itemBuilder: (_, i) => _card(UserRole.values[i]),
                    ),
                    const SizedBox(height: 24),
                    _button(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _button(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.peach, AppColors.appPurple],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: FilledButton(
      onPressed: () {
        context.read<AuthCubit>().signInAs(selected);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      },
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: Text('Ouvrir l’espace ${selected.label}'),
    ),
  );
  Widget _card(UserRole role) {
    final active = role == selected;
    return InkWell(
      onTap: () => setState(() => selected = role),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: active ? AppColors.appPurpleDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? AppColors.appPurple : AppColors.line,
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.appPurple.withValues(alpha: .22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: active ? Colors.white12 : AppColors.lavender,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                role.icon,
                color: active ? Colors.white : AppColors.appPurple,
              ),
            ),
            const Spacer(),
            Text(
              role.label,
              maxLines: 2,
              style: TextStyle(
                color: active ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_count(role)} modules',
              style: TextStyle(
                color: active ? Colors.white60 : AppColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _count(UserRole r) => switch (r) {
    UserRole.admin || UserRole.dg => 7,
    UserRole.comptable => 4,
    UserRole.secretaire => 2,
    UserRole.caissier || UserRole.magasinier || UserRole.commercial => 3,
  };
}
