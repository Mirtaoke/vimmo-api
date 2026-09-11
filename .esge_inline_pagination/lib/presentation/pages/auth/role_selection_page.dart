import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/role_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/esge_ui.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  UserRole selected = UserRole.dg;

  static const mobileRoles = <UserRole>[
    UserRole.dg,
    UserRole.comptable,
    UserRole.secretaire,
    UserRole.caissier,
    UserRole.magasinier,
    UserRole.commercial,
  ];

  static const accents = <Color>[
    AppColors.cyan,
    AppColors.orange,
    AppColors.plum,
    AppColors.coral,
    AppColors.teal,
    Color(0xFFB89A42),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: EsgeGlowBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: LayoutBuilder(
              builder: (_, constraints) => ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
                children: [
                  const Row(
                    children: [
                      BrandMark(compact: true),
                      Spacer(),
                      EsgeStatusChip('ACCÈS SÉCURISÉ', color: AppColors.indigo),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Choisissez votre espace',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Votre rôle détermine les données, actions et validations disponibles après la connexion.',
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 2, 4, 11),
                        child: Row(
                          children: [
                            Icon(
                              Icons.grid_view_rounded,
                              color: AppColors.indigo,
                              size: 15,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'ESPACES MÉTIER',
                              style: TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: mobileRoles.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: constraints.maxWidth >= 560 ? 3 : 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: constraints.maxWidth < 350
                              ? 1.18
                              : 1.32,
                        ),
                        itemBuilder: (_, index) {
                          final role = mobileRoles[index];
                          return _roleCard(role, accents[index]);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: Row(
                      key: ValueKey(selected),
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _accent(selected).withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            selected.icon,
                            color: _accent(selected),
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.label,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _description(selected),
                                style: const TextStyle(
                                  color: AppColors.textSoft,
                                  fontSize: 8.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  EsgeGradientButton(
                    label: 'Continuer',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginPage(role: selected),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _roleCard(UserRole role, Color accent) {
    final active = selected == role;
    return Semantics(
      selected: active,
      button: true,
      label: role.label,
      child: InkWell(
        onTap: () => setState(() => selected = role),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          scale: active ? 1 : .96,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(AppColors.surface, accent, active ? .17 : .07)!,
                  AppColors.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: active
                      ? accent.withValues(alpha: .20)
                      : const Color(0x100B281E),
                  blurRadius: active ? 17 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 3,
                  bottom: 3,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: active ? 4 : 3,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: .65),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(role.icon, color: accent, size: 17),
                          ),
                          const Spacer(),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: active ? 1 : .25,
                            child: Icon(
                              active
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: active ? accent : AppColors.muted,
                              size: 17,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        role.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _shortCapability(role),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 7.5,
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
    );
  }

  Color _accent(UserRole role) => accents[mobileRoles.indexOf(role)];

  String _description(UserRole role) => switch (role) {
    UserRole.admin => 'Comptes, droits, sécurité et traçabilité',
    UserRole.dg => 'Pilotage global, décisions et validations',
    UserRole.comptable => 'Contrôle, rapprochements et rapports',
    UserRole.secretaire => 'Dossiers, agenda et coordination',
    UserRole.caissier => 'Caisse, bons et exécution des paiements',
    UserRole.magasinier => 'Stock, inventaires et mouvements',
    UserRole.commercial => 'Prospects, clients et opportunités',
  };

  String _shortCapability(UserRole role) => switch (role) {
    UserRole.admin => 'SÉCURITÉ & DROITS',
    UserRole.dg => 'PILOTAGE GLOBAL',
    UserRole.comptable => 'FINANCE & CONTRÔLE',
    UserRole.secretaire => 'DOSSIERS & AGENDA',
    UserRole.caissier => 'CAISSE & BONS',
    UserRole.magasinier => 'STOCK & LOGISTIQUE',
    UserRole.commercial => 'CRM & VENTES',
  };
}
