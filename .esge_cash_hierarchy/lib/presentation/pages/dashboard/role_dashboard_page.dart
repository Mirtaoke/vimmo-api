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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 108),
            children: [
              _header(),
              const SizedBox(height: 18),
              _balanceCard(config),
              const SizedBox(height: 12),
              _metricRow(config.metrics),
              const SizedBox(height: 19),
              _sectionTitle('Actions rapides', '${modules.length} accès'),
              const SizedBox(height: 10),
              _quickActions(context, modules),
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
              _sectionTitle('Mouvements récents', 'Activité métier'),
              const SizedBox(height: 10),
              _RecentMovements(modules: modules),
            ],
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
        child: SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: modules.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (_, index) {
              final module = modules[index];
              return SizedBox(
                width: 73,
                child: Material(
                  color: module.color.withValues(alpha: .18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: module.color.withValues(alpha: .34),
                    ),
                  ),
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
              );
            },
          ),
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
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DisbursementPage()),
    ),
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

  List<_Module> _modules() {
    const validation = _Module(
      'Demandes financières',
      'Demandes',
      'Contrôle, approbation et historique',
      Icons.verified_user_outlined,
      AppColors.indigo,
      DisbursementPage(),
    );
    final cash = _Module(
      'Caisse & bons',
      'Caisse',
      'Solde, entrées, sorties et recherche',
      Icons.account_balance_wallet_outlined,
      AppColors.orange,
      CashPage(canCreateCashVoucher: role == UserRole.caissier),
    );
    const providers = _Module(
      'Prestataires',
      'Prestataires',
      'Dettes, créances et échéances',
      Icons.apartment_rounded,
      AppColors.purple,
      ProvidersPage(),
    );
    const stock = _Module(
      'Stock & logistique',
      'Stocks',
      'Articles, inventaires et mouvements',
      Icons.inventory_2_outlined,
      AppColors.coral,
      InventoryPage(),
    );
    const crm = _Module(
      'CRM commercial',
      'CRM',
      'Prospects, rendez-vous et clients',
      Icons.hub_outlined,
      AppColors.azure,
      CrmPage(),
    );
    const attendance = _Module(
      'Présence',
      'Pointage',
      'Pointage GPS, Wi-Fi et historique',
      Icons.fingerprint_rounded,
      AppColors.tealDark,
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
      AppColors.plum,
      DocumentsPage(),
    );
    const reports = _Module(
      'Rapports & audit',
      'Rapports',
      'Exports, analyses et traçabilité',
      Icons.analytics_outlined,
      AppColors.amber,
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
      UserRole.secretaire => [validation, documents, attendance],
      UserRole.caissier => [cash, validation, documents, attendance],
      UserRole.magasinier => [stock, attendance, documents],
      UserRole.commercial => [crm, attendance, documents],
    };
  }
}

class _RecentMovements extends StatefulWidget {
  const _RecentMovements({required this.modules});

  final List<_Module> modules;

  @override
  State<_RecentMovements> createState() => _RecentMovementsState();
}

class _RecentMovementsState extends State<_RecentMovements> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final module =
        widget.modules[selectedIndex.clamp(0, widget.modules.length - 1)];
    final records = _records(module.shortTitle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 37,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.modules.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (_, index) {
              final item = widget.modules[index];
              return EsgeFilterChip(
                label: item.shortTitle,
                selected: selectedIndex == index,
                color: item.color,
                onSelected: (_) => setState(() => selectedIndex = index),
              );
            },
          ),
        ),
        const SizedBox(height: 11),
        ...records
            .map(
              (record) => Material(
                color: module.color.withValues(alpha: .14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                  side: BorderSide(color: module.color.withValues(alpha: .30)),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => module.page),
                  ),
                  borderRadius: BorderRadius.circular(17),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        EsgeIconBadge(
                          icon: module.icon,
                          color: module.color,
                          size: 38,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                record.$2,
                                style: const TextStyle(
                                  color: AppColors.textSoft,
                                  fontSize: 8.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          record.$3,
                          style: TextStyle(
                            color: module.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .expand((item) => [item, const SizedBox(height: 8)]),
      ],
    );
  }

  List<(String, String, String)> _records(String module) => switch (module) {
    'Caisse' => const [
      ('Approvisionnement caisse', 'ENT-0089 • Aujourd’hui', '+ 5 000 000 F'),
      ('Mission terrain', 'SOR-0142 • Exécuté', '− 485 000 F'),
    ],
    'Demandes' => const [
      ('Demande DEC-0248', 'Validation comptable obtenue', 'À valider'),
      ('Demande DEC-0241', 'Retournée pour correction', 'Retournée'),
    ],
    'Prestataires' => const [
      ('Nova Services', 'Échéance dans 2 jours', '1 850 000 F'),
      ('Atlas Conseil', 'Règlement rapproché', 'Réglé'),
    ],
    'Stocks' => const [
      ('Papier A4 Premium', 'Stock sous le seuil minimum', '12 unités'),
      ('Cartouche HP 305', 'Entrée enregistrée aujourd’hui', '+ 24 unités'),
    ],
    'CRM' => const [
      ('Nova Conseil', 'Proposition envoyée', '4 800 000 F'),
      ('Horizon SARL', 'Rendez-vous demain à 10 h', 'À suivre'),
    ],
    'Pointage' => const [
      ('Pointage d’arrivée', 'GPS et Wi-Fi conformes', '08:02'),
      ('Présence du jour', 'Synchronisée avec le serveur', 'Validée'),
    ],
    'Documents' => const [
      ('BON-CAISSE-0248.pdf', 'Justificatif ajouté aujourd’hui', 'PDF'),
      ('FACT-2026-084.pdf', 'Facture prestataire sécurisée', 'PDF'),
    ],
    _ => const [
      ('Activité mise à jour', 'Synchronisée aujourd’hui', 'Récent'),
      ('Nouvelle opération', 'Disponible dans le module', 'Voir'),
    ],
  };
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
