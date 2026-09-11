import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/role_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/analytics_widgets.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/esge_ui.dart';
import '../attendance/attendance_page.dart';
import '../admin/users_permissions_page.dart';
import '../cash/cash_page.dart';
import '../crm/crm_page.dart';
import '../disbursements/disbursement_page.dart';
import '../documents/documents_page.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: EsgeGlowBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 108),
              children: [
                _header(),
                const SizedBox(height: 18),
                _balanceCard(config),
                const SizedBox(height: 12),
                _metricRow(config.metrics),
                const SizedBox(height: 19),
                _sectionTitle('Actions rapides', 'Voir tout'),
                const SizedBox(height: 10),
                _quickActions(context, modules.take(4).toList()),
                const SizedBox(height: 20),
                _sectionTitle('Cash flow & activité', 'Ce mois'),
                const SizedBox(height: 10),
                _activityChart(config),
                const SizedBox(height: 20),
                _sectionTitle(
                  'À traiter maintenant',
                  '${config.pendingCount} éléments',
                ),
                const SizedBox(height: 10),
                _taskCard(context, config),
                const SizedBox(height: 20),
                _sectionTitle('Votre espace', '${modules.length} modules'),
                const SizedBox(height: 10),
                _moduleGrid(context, box.maxWidth, modules),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      const BrandMark(compact: true),
      const Spacer(),
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.violetGradient),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(role.icon, color: Colors.white, size: 20),
      ),
    ],
  );

  Widget _balanceCard(_DashboardConfig config) => Container(
    height: 185,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B3B2C), Color(0xFF17694D), Color(0xFF5AA77C)],
      ),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: AppColors.cyan.withValues(alpha: .15)),
      boxShadow: [
        BoxShadow(
          color: AppColors.cyan.withValues(alpha: .18),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: AppColors.violet.withValues(alpha: .15),
          blurRadius: 30,
          offset: const Offset(8, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -18,
          top: -32,
          child: Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .07),
            ),
          ),
        ),
        Positioned(
          right: 18,
          bottom: 12,
          child: SizedBox(
            width: 126,
            height: 58,
            child: CustomPaint(painter: _TrendPainter()),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour, Aïcha 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        role.label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(role.icon, color: Colors.white, size: 20),
                ),
              ],
            ),
            const Spacer(),
            Text(
              config.headline.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              config.primaryValue,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.green,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  config.note,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  Widget _metricRow(List<_Metric> metrics) => Row(
    children: List.generate(metrics.length, (i) {
      final metric = metrics[i];
      final colors = [
        AppColors.cyan,
        AppColors.violet,
        AppColors.green,
        AppColors.orange,
      ];
      final color = colors[i % colors.length];
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i == metrics.length - 1 ? 0 : 7),
          child: Container(
            height: 86,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: .18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(metric.icon, color: color, size: 17),
                const Spacer(),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
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
        ),
      );
    }),
  );

  Widget _sectionTitle(String title, String trailing) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
      ),
      const Spacer(),
      Text(
        trailing,
        style: const TextStyle(
          color: AppColors.cyan,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _quickActions(BuildContext context, List<_Module> modules) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
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
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Column(
                        children: [
                          EsgeIconBadge(
                            icon: module.icon,
                            color: module.color,
                            size: 40,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            module.shortTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.textSoft,
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

  Widget _activityChart(_DashboardConfig config) => EsgeGlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VOLUME D’ACTIVITÉ',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  config.chartValue,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const EsgeStatusChip('+10,8 %', color: AppColors.green),
          ],
        ),
        const SizedBox(height: 16),
        const SparklineBars(values: [35, 51, 42, 66, 58, 77, 62], height: 78),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('S1', style: _axis),
            Text('S2', style: _axis),
            Text('S3', style: _axis),
            Text('S4', style: _axis),
            Text('MTD', style: _axis),
          ],
        ),
      ],
    ),
  );

  Widget _taskCard(BuildContext context, _DashboardConfig config) => InkWell(
    onTap: () => _showPriority(context, config),
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.violet.withValues(alpha: .23)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.text,
              size: 25,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRIORITÉ',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.alert,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.tealDark,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.tealDark),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ],
      ),
    ),
  );

  void _showPriority(BuildContext context, _DashboardConfig config) =>
      showModalBottomSheet(
        context: context,
        useSafeArea: true,
        builder: (_) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            8,
            22,
            22 + MediaQueryData.fromView(View.of(context)).viewPadding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.text),
              ),
              const SizedBox(height: 14),
              const Text(
                'Action prioritaire',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                config.alert,
                style: const TextStyle(color: AppColors.textSoft, height: 1.4),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Prendre en charge'),
              ),
            ],
          ),
        ),
      );

  Widget _moduleGrid(
    BuildContext context,
    double width,
    List<_Module> modules,
  ) {
    final cols = width >= 760 ? 3 : 2;
    const cardBackgrounds = [
      Color(0xFFFFF1E9),
      Color(0xFFF0F1FC),
      Color(0xFFFFF7DD),
      Color(0xFFFFEEF2),
      Color(0xFFEAF5F1),
    ];
    const cardAccents = [
      AppColors.orange,
      AppColors.indigo,
      AppColors.gold,
      AppColors.coral,
      AppColors.tealDark,
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: width < 370 ? 1.08 : 1.25,
      ),
      itemBuilder: (_, index) {
        final module = modules[index];
        final background = cardBackgrounds[index % cardBackgrounds.length];
        final accent = cardAccents[index % cardAccents.length];
        return Material(
          color: background,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
          elevation: 2,
          shadowColor: accent.withValues(alpha: .18),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => module.page),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      EsgeIconBadge(icon: module.icon, color: accent, size: 38),
                      const Spacer(),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: accent,
                        size: 15,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    module.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    module.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 8,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
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
      Icons.verified_user_outlined,
      AppColors.cyan,
      DisbursementPage(),
    );
    const cash = _Module(
      'Caisse & bons',
      'Caisse',
      'Solde, entrées, sorties et recherche',
      Icons.account_balance_wallet_outlined,
      AppColors.violet,
      CashPage(),
    );
    const providers = _Module(
      'Prestataires',
      'Prestataires',
      'Dettes, créances et échéances',
      Icons.apartment_rounded,
      AppColors.blue,
      ProvidersPage(),
    );
    const stock = _Module(
      'Stock & logistique',
      'Stocks',
      'Articles, inventaires et mouvements',
      Icons.inventory_2_outlined,
      AppColors.orange,
      InventoryPage(),
    );
    const crm = _Module(
      'CRM commercial',
      'CRM',
      'Prospects, rendez-vous et clients',
      Icons.hub_outlined,
      AppColors.green,
      CrmPage(),
    );
    const attendance = _Module(
      'Présence',
      'Pointage',
      'Pointage GPS, Wi-Fi et historique',
      Icons.fingerprint_rounded,
      AppColors.cyan,
      AttendancePage(),
    );
    const users = _Module(
      'Utilisateurs & permissions',
      'Utilisateurs',
      'Comptes, rôles, droits et sessions',
      Icons.admin_panel_settings_outlined,
      AppColors.violet,
      UsersPermissionsPage(),
    );
    const documents = _Module(
      'Documents sécurisés',
      'Documents',
      'Factures, bons, contrats et justificatifs',
      Icons.folder_copy_outlined,
      AppColors.blue,
      DocumentsPage(),
    );
    const reports = _Module(
      'Rapports & audit',
      'Rapports',
      'Exports, analyses et traçabilité',
      Icons.analytics_outlined,
      AppColors.cyan,
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
        documents,
        reports,
      ],
      UserRole.admin => [
        users,
        reports,
        documents,
        attendance,
        validation,
        cash,
        providers,
        stock,
        crm,
      ],
      UserRole.comptable => [
        validation,
        providers,
        cash,
        documents,
        reports,
        attendance,
      ],
      UserRole.secretaire => [
        validation,
        documents,
        crm,
        attendance,
        providers,
        reports,
      ],
      UserRole.caissier => [
        cash,
        validation,
        providers,
        documents,
        attendance,
        reports,
      ],
      UserRole.magasinier => [
        stock,
        providers,
        attendance,
        documents,
        validation,
        reports,
      ],
      UserRole.commercial => [
        crm,
        providers,
        stock,
        attendance,
        documents,
        reports,
      ],
    };
  }
}

const _axis = TextStyle(color: AppColors.muted, fontSize: 7.5);

class _TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .76)
      ..cubicTo(
        size.width * .18,
        size.height * .58,
        size.width * .24,
        size.height * .82,
        size.width * .36,
        size.height * .55,
      )
      ..cubicTo(
        size.width * .48,
        size.height * .28,
        size.width * .58,
        size.height * .70,
        size.width * .70,
        size.height * .42,
      )
      ..cubicTo(
        size.width * .82,
        size.height * .15,
        size.width * .88,
        size.height * .34,
        size.width,
        size.height * .10,
      );
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.cyan, Colors.white],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    this.chartValue,
    this.pendingCount,
  );
  final String headline, primaryValue, note, alert, chartValue;
  final int pendingCount;
  final List<_Metric> metrics;
}

_DashboardConfig _config(UserRole role) => switch (role) {
  UserRole.dg => const _DashboardConfig(
    'Solde de caisse',
    '24 850 000 F CFA',
    '+8,4 % ce mois',
    '12 demandes attendent votre validation DG',
    [
      _Metric('En attente', '12', Icons.pending_actions_rounded),
      _Metric('Stock', '18,4 M', Icons.inventory_2_outlined),
      _Metric('Prospects', '146', Icons.people_alt_outlined),
      _Metric('Présents', '38/42', Icons.badge_outlined),
    ],
    '44 150 000 F',
    12,
  ),
  UserRole.admin => const _DashboardConfig(
    'Utilisateurs actifs',
    '42 collaborateurs',
    '7 rôles configurés',
    '3 alertes de sécurité à examiner',
    [
      _Metric('Actifs', '42', Icons.group_outlined),
      _Metric('Connexions', '37', Icons.login_rounded),
      _Metric('Documents', '1 284', Icons.folder_outlined),
      _Metric('Audit', '596', Icons.history_rounded),
    ],
    '596 actions',
    3,
  ),
  UserRole.comptable => const _DashboardConfig(
    'À contrôler aujourd’hui',
    '6 425 000 F CFA',
    '12 nouvelles demandes',
    '4 échéances prestataires arrivent cette semaine',
    [
      _Metric('À contrôler', '12', Icons.fact_check_outlined),
      _Metric('Dettes', '9,8 M', Icons.call_made_rounded),
      _Metric('Créances', '3,2 M', Icons.call_received_rounded),
      _Metric('Échéances', '4', Icons.event_outlined),
    ],
    '13 000 000 F',
    12,
  ),
  UserRole.secretaire => const _DashboardConfig(
    'Demandes ce mois',
    '28 dossiers',
    '82 % déjà traités',
    '3 demandes vous ont été retournées pour correction',
    [
      _Metric('Brouillons', '4', Icons.edit_note_rounded),
      _Metric('Comptable', '7', Icons.account_balance_outlined),
      _Metric('DG', '5', Icons.verified_user_outlined),
      _Metric('Exécutées', '12', Icons.check_circle_outline),
    ],
    '28 demandes',
    3,
  ),
  UserRole.caissier => const _DashboardConfig(
    'Solde disponible',
    '24 850 000 F CFA',
    '8 mouvements aujourd’hui',
    '5 paiements validés sont prêts à être exécutés',
    [
      _Metric('À exécuter', '5', Icons.payments_outlined),
      _Metric('Entrées', '5,0 M', Icons.south_west_rounded),
      _Metric('Sorties', '1,9 M', Icons.north_east_rounded),
      _Metric('Bons', '8', Icons.receipt_long_outlined),
    ],
    '6 900 000 F',
    5,
  ),
  UserRole.magasinier => const _DashboardConfig(
    'Valeur estimée du stock',
    '18 420 000 F CFA',
    '324 articles suivis',
    '3 articles sous le seuil et 1 rupture détectée',
    [
      _Metric('Articles', '324', Icons.inventory_2_outlined),
      _Metric('Entrées', '18', Icons.move_to_inbox_outlined),
      _Metric('Sorties', '27', Icons.outbox_outlined),
      _Metric('Alertes', '4', Icons.warning_amber_rounded),
    ],
    '45 mouvements',
    4,
  ),
  UserRole.commercial => const _DashboardConfig(
    'Pipeline commercial',
    '48 700 000 F CFA',
    '+12 % ce trimestre',
    'Votre prochain rendez-vous commence dans 45 minutes',
    [
      _Metric('Prospects', '46', Icons.person_search_outlined),
      _Metric('Rendez-vous', '7', Icons.calendar_month_outlined),
      _Metric('Propositions', '14', Icons.description_outlined),
      _Metric('Clients', '6', Icons.handshake_outlined),
    ],
    '48 700 000 F',
    1,
  ),
};
