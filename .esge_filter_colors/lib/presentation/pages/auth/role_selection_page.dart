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
  late final PageController _controller = PageController(
    initialPage: UserRole.values.indexOf(selected),
    viewportFraction: .76,
  );

  @override
  void dispose() {
    _controller.dispose();
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.line),
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
                    SizedBox(
                      height: 342,
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: UserRole.values.length,
                        onPageChanged: (index) =>
                            setState(() => selected = UserRole.values[index]),
                        itemBuilder: (_, index) => AnimatedBuilder(
                          animation: _controller,
                          builder: (_, child) {
                            var distance = 0.0;
                            if (_controller.hasClients &&
                                _controller.position.haveDimensions) {
                              distance = (_controller.page! - index)
                                  .abs()
                                  .clamp(0, 1);
                            }
                            return Transform.scale(
                              scale: 1 - (distance * .08),
                              child: Opacity(
                                opacity: 1 - (distance * .22),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: _card(UserRole.values[index]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        UserRole.values.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: selected == UserRole.values[index] ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: selected == UserRole.values[index]
                                ? AppColors.tealDark
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
      onTap: () => _controller.animateToPage(
        UserRole.values.indexOf(role),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      ),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        scale: active ? 1 : .98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B3B2C), Color(0xFF247052)],
                  )
                : null,
            color: active ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.tealDark.withValues(alpha: active ? .2 : .08),
                blurRadius: active ? 28 : 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -34,
                top: -38,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? Colors.white.withValues(alpha: .06)
                        : AppColors.mint.withValues(alpha: .7),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFFFF9ED)
                              : AppColors.mint,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x180B382A),
                              blurRadius: 16,
                              offset: Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Icon(
                          role.icon,
                          color: AppColors.tealDark,
                          size: 45,
                        ),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: active
                            ? const Icon(
                                Icons.check_circle_rounded,
                                key: ValueKey('checked'),
                                color: Colors.white,
                                size: 27,
                              )
                            : const Icon(
                                Icons.circle_outlined,
                                key: ValueKey('empty'),
                                color: AppColors.muted,
                                size: 24,
                              ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    role.label,
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _description(role),
                    style: TextStyle(
                      color: active ? Colors.white70 : AppColors.textSoft,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: _capabilities(role)
                        .map(
                          (label) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white.withValues(alpha: .12)
                                    : AppColors.soft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : AppColors.tealDark,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
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

  List<String> _capabilities(UserRole role) => switch (role) {
    UserRole.admin => ['Comptes', 'Droits', 'Audit'],
    UserRole.dg => ['Pilotage', 'Validation', 'Rapports'],
    UserRole.comptable => ['Contrôle', 'Écritures', 'Soldes'],
    UserRole.secretaire => ['Dossiers', 'Agenda', 'Courrier'],
    UserRole.caissier => ['Caisse', 'Bons', 'Paiements'],
    UserRole.magasinier => ['Stock', 'Entrées', 'Inventaire'],
    UserRole.commercial => ['Prospects', 'Clients', 'Ventes'],
  };
}
