import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/role_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/responsive_content.dart';
import '../attendance/attendance_page.dart';
import '../cash/cash_page.dart';
import '../crm/crm_page.dart';
import '../disbursements/disbursement_page.dart';
import '../inventory/inventory_page.dart';
import '../providers/providers_page.dart';
import '../reports/reports_page.dart';

class RoleDashboardPage extends StatelessWidget {
  const RoleDashboardPage({super.key, required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final config = _config(role);
    final modules = _modules();
    return ColoredBox(
      color: AppColors.connectedCanvas,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(context),
                  const SizedBox(height: 24),
                  _hero(config),
                  const SizedBox(height: 20),
                  _quickActions(context, modules.take(4).toList()),
                  const SizedBox(height: 22),
                  _alertBanner(config),
                  const SizedBox(height: 26),
                  _sectionTitle('Vue d’ensemble', 'Aujourd’hui'),
                  const SizedBox(height: 12),
                  _metricsGrid(viewport.maxWidth, config.metrics),
                  const SizedBox(height: 28),
                  _sectionTitle('Votre espace', '${modules.length} modules'),
                  const SizedBox(height: 12),
                  _modulesGrid(context, viewport.maxWidth, modules),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) => Row(
    children: [
      const BrandMark(),
      const Spacer(),
      IconButton.filledTonal(
        onPressed: () {},
        icon: const Badge(
          label: Text('5'),
          child: Icon(Icons.notifications_none),
        ),
      ),
      const SizedBox(width: 8),
      CircleAvatar(
        radius: 23,
        backgroundColor: AppColors.mint,
        child: Icon(role.icon, color: AppColors.tealDark),
      ),
    ],
  );

  Widget _hero(_DashboardConfig config) => TweenAnimationBuilder<double>(
    duration: const Duration(milliseconds: 700),
    tween: Tween(begin: .94, end: 1),
    curve: Curves.easeOutBack,
    builder: (_, value, child) => Transform.scale(scale: value, child: child),
    child: Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 210),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.appPurpleDark,
            AppColors.appPurple,
            AppColors.peach,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: .28),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -20,
            bottom: -20,
            width: 220,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.transparent, Colors.white],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/esge_dashboard_hero.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
          ),
          Positioned(
            right: -18,
            top: -24,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                role.icon,
                size: 72,
                color: Colors.white.withValues(alpha: .42),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BONJOUR, AÏCHA  •  ${role.label.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                config.headline,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                config.primaryValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: Color(0xFF83E6C9),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      config.note,
                      style: const TextStyle(
                        color: Color(0xFFB8F2E3),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _quickActions(BuildContext context, List<_Module> modules) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: modules
              .map(
                (module) => Expanded(
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => module.page),
                    ),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  module.color.withValues(alpha: .16),
                                  AppColors.mint,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              module.icon,
                              color: AppColors.tealDark,
                              size: 21,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            module.shortTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );

  Widget _alertBanner(_DashboardConfig config) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.teal, Color(0xFF46CDB3)],
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'À TRAITER MAINTENANT',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                config.alert,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.arrow_forward, color: AppColors.tealDark),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title, String trailing) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      const Spacer(),
      Text(
        trailing,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _metricsGrid(double width, List<_Metric> metrics) {
    final columns = width >= 850 ? 4 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: width < 370 ? 1.12 : 1.3,
      ),
      itemBuilder: (_, index) {
        final metric = metrics[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: index == 0 ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: index == 0 ? AppColors.primary : AppColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                metric.icon,
                color: index == 0 ? const Color(0xFF7DE0C8) : AppColors.teal,
              ),
              const Spacer(),
              Text(
                metric.value,
                maxLines: 1,
                style: TextStyle(
                  color: index == 0 ? Colors.white : AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                metric.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: index == 0 ? Colors.white60 : AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modulesGrid(
    BuildContext context,
    double width,
    List<_Module> modules,
  ) {
    final columns = width >= 1000
        ? 3
        : width >= 620
        ? 2
        : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 116,
      ),
      itemBuilder: (_, index) {
        final module = modules[index];
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => module.page),
          ),
          borderRadius: BorderRadius.circular(25),
          child: Ink(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: index == 0
                  ? const LinearGradient(
                      colors: [Color(0xFFE0F4EF), Color(0xFFF7FBFA)],
                    )
                  : null,
              color: index == 0 ? null : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: index == 0 ? const Color(0xFFA9DCD1) : AppColors.line,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: module.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(module.icon, color: module.color),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        module.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_outward, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_Module> _modules() {
    const validation = _Module(
      'Validations financières',
      'Validations',
      'Contrôle, approbation et historique',
      Icons.verified_user,
      AppColors.teal,
      DisbursementPage(),
    );
    const cash = _Module(
      'Caisse & bons',
      'Caisse',
      'Solde, entrées, sorties et recherche',
      Icons.account_balance_wallet,
      AppColors.gold,
      CashPage(),
    );
    const providers = _Module(
      'Prestataires',
      'Prestataires',
      'Dettes, créances et échéances',
      Icons.apartment,
      AppColors.success,
      ProvidersPage(),
    );
    const stock = _Module(
      'Stock & logistique',
      'Stocks',
      'Articles, inventaires et mouvements',
      Icons.inventory_2,
      AppColors.info,
      InventoryPage(),
    );
    const crm = _Module(
      'CRM commercial',
      'CRM',
      'Prospects, rendez-vous et clients',
      Icons.hub,
      Color(0xFF9B51E0),
      CrmPage(),
    );
    const attendance = _Module(
      'Présence',
      'Pointage',
      'Pointage GPS, Wi-Fi et historique',
      Icons.fingerprint,
      AppColors.coral,
      AttendancePage(),
    );
    const reports = _Module(
      'Rapports & audit',
      'Rapports',
      'Exports, analyses et traçabilité',
      Icons.analytics,
      AppColors.navy,
      ReportsPage(),
    );
    return switch (role) {
      UserRole.dg => [
        validation,
        cash,
        providers,
        stock,
        crm,
        attendance,
        reports,
      ],
      UserRole.admin => [
        reports,
        attendance,
        validation,
        cash,
        providers,
        stock,
        crm,
      ],
      UserRole.comptable => [validation, providers, cash, reports],
      UserRole.secretaire => [validation, reports],
      UserRole.caissier => [cash, validation, reports],
      UserRole.magasinier => [stock, attendance, reports],
      UserRole.commercial => [crm, attendance, reports],
    };
  }
}

class _Module {
  const _Module(
    this.title,
    this.shortTitle,
    this.subtitle,
    this.icon,
    this.color,
    this.page,
  );
  final String title, shortTitle, subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;
}

class _DashboardConfig {
  const _DashboardConfig(
    this.headline,
    this.primaryValue,
    this.note,
    this.alert,
    this.metrics,
  );
  final String headline, primaryValue, note, alert;
  final List<_Metric> metrics;
}

_DashboardConfig _config(UserRole role) => switch (role) {
  UserRole.dg => const _DashboardConfig(
    'Solde de caisse',
    '24 850 000 F CFA',
    '+8,4 % ce mois',
    '12 demandes attendent votre validation DG',
    [
      _Metric('Demandes en attente', '12', Icons.pending_actions),
      _Metric('Valeur du stock', '18,4 M', Icons.inventory),
      _Metric('Prospects actifs', '146', Icons.people),
      _Metric('Présents aujourd’hui', '38/42', Icons.badge),
    ],
  ),
  UserRole.admin => const _DashboardConfig(
    'Utilisateurs actifs',
    '42 collaborateurs',
    '7 rôles configurés',
    '3 alertes de sécurité à examiner',
    [
      _Metric('Utilisateurs actifs', '42', Icons.group),
      _Metric('Connexions du jour', '37', Icons.login),
      _Metric('Documents stockés', '1 284', Icons.folder),
      _Metric('Actions auditées', '596', Icons.history),
    ],
  ),
  UserRole.comptable => const _DashboardConfig(
    'À contrôler aujourd’hui',
    '6 425 000 F CFA',
    '12 nouvelles demandes',
    '4 échéances prestataires arrivent cette semaine',
    [
      _Metric('Demandes à contrôler', '12', Icons.fact_check),
      _Metric('Dettes prestataires', '9,8 M', Icons.call_made),
      _Metric('Créances à recouvrer', '3,2 M', Icons.call_received),
      _Metric('Échéances proches', '4', Icons.event),
    ],
  ),
  UserRole.secretaire => const _DashboardConfig(
    'Demandes ce mois',
    '28 dossiers',
    '82 % déjà traités',
    '3 demandes vous ont été retournées pour correction',
    [
      _Metric('Brouillons', '4', Icons.edit_note),
      _Metric('Chez le comptable', '7', Icons.account_balance),
      _Metric('Chez le DG', '5', Icons.verified_user),
      _Metric('Exécutées', '12', Icons.check_circle),
    ],
  ),
  UserRole.caissier => const _DashboardConfig(
    'Solde disponible',
    '24 850 000 F CFA',
    '8 mouvements aujourd’hui',
    '5 paiements validés sont prêts à être exécutés',
    [
      _Metric('À exécuter', '5', Icons.payments),
      _Metric('Entrées du jour', '5,0 M', Icons.south_west),
      _Metric('Sorties du jour', '1,9 M', Icons.north_east),
      _Metric('Bons émis', '8', Icons.receipt_long),
    ],
  ),
  UserRole.magasinier => const _DashboardConfig(
    'Valeur estimée du stock',
    '18 420 000 F CFA',
    '324 articles suivis',
    '3 articles sous le seuil et 1 rupture détectée',
    [
      _Metric('Articles', '324', Icons.inventory_2),
      _Metric('Entrées du jour', '18', Icons.move_to_inbox),
      _Metric('Sorties du jour', '27', Icons.outbox),
      _Metric('Alertes stock', '4', Icons.warning),
    ],
  ),
  UserRole.commercial => const _DashboardConfig(
    'Pipeline commercial',
    '48 700 000 F CFA',
    '+12 % ce trimestre',
    'Votre prochain rendez-vous commence dans 45 minutes',
    [
      _Metric('Prospects actifs', '46', Icons.person_search),
      _Metric('Rendez-vous', '7', Icons.calendar_month),
      _Metric('Propositions', '14', Icons.description),
      _Metric('Nouveaux clients', '6', Icons.handshake),
    ],
  ),
};
