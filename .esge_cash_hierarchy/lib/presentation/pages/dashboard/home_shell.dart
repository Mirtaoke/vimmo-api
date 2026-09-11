import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../business_logic/dashboard/dashboard_cubit.dart';
import '../../../business_logic/dashboard/dashboard_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/esge_ui.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import '../cash/cash_page.dart';
import '../crm/crm_page.dart';
import '../disbursements/disbursement_page.dart';
import '../documents/documents_page.dart';
import '../inventory/inventory_page.dart';
import '../providers/providers_page.dart';
import '../reports/reports_page.dart';
import '../attendance/attendance_page.dart';
import 'role_dashboard_page.dart';
import 'quick_access_page.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user);
    if (user == null) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final pages = [
          RoleDashboardPage(role: user.role),
          const GlobalSearchPage(),
          const NotificationsPage(),
          const ProfilePage(),
        ];
        return Scaffold(
          backgroundColor: AppColors.background,
          extendBody: true,
          body: IndexedStack(index: state.selectedIndex, children: pages),
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: _EsgeBottomNav(
              selectedIndex: state.selectedIndex,
              onChanged: context.read<DashboardCubit>().selectTab,
              onQuickTap: () => _quickMenu(context),
            ),
          ),
        );
      },
    );
  }

  void _quickMenu(BuildContext context) {
    final role = context.read<AuthCubit>().state.user!.role;
    final actions = switch (role) {
      UserRole.dg => const [
        (
          Icons.verified_user_outlined,
          'Demandes',
          AppColors.indigo,
          DisbursementPage(),
        ),
        (Icons.receipt_long_outlined, 'Caisse', AppColors.orange, CashPage()),
        (Icons.analytics_outlined, 'Rapports', AppColors.plum, ReportsPage()),
      ],
      UserRole.comptable => const [
        (
          Icons.fact_check_outlined,
          'Demandes',
          AppColors.indigo,
          DisbursementPage(),
        ),
        (
          Icons.apartment_outlined,
          'Prestataires',
          AppColors.plum,
          ProvidersPage(),
        ),
        (Icons.analytics_outlined, 'Rapports', AppColors.orange, ReportsPage()),
      ],
      UserRole.secretaire => const [
        (
          Icons.request_quote_outlined,
          'Demande',
          AppColors.orange,
          DisbursementPage(),
        ),
        (
          Icons.folder_copy_outlined,
          'Documents',
          AppColors.plum,
          DocumentsPage(),
        ),
        (
          Icons.fingerprint_rounded,
          'Pointage',
          AppColors.tealDark,
          AttendancePage(),
        ),
      ],
      UserRole.caissier => const [
        (
          Icons.receipt_long_outlined,
          'Bon caisse',
          AppColors.orange,
          CashPage(canCreateCashVoucher: true),
        ),
        (
          Icons.payments_outlined,
          'À exécuter',
          AppColors.indigo,
          DisbursementPage(),
        ),
        (
          Icons.folder_copy_outlined,
          'Documents',
          AppColors.plum,
          DocumentsPage(),
        ),
      ],
      UserRole.magasinier => const [
        (
          Icons.inventory_2_outlined,
          'Stock',
          AppColors.orange,
          InventoryPage(),
        ),
        (
          Icons.folder_copy_outlined,
          'Documents',
          AppColors.plum,
          DocumentsPage(),
        ),
        (
          Icons.fingerprint_rounded,
          'Pointage',
          AppColors.tealDark,
          AttendancePage(),
        ),
      ],
      UserRole.commercial => const [
        (
          Icons.person_add_alt_1_outlined,
          'Prospect',
          AppColors.coral,
          CrmPage(),
        ),
        (
          Icons.folder_copy_outlined,
          'Documents',
          AppColors.plum,
          DocumentsPage(),
        ),
        (
          Icons.fingerprint_rounded,
          'Pointage',
          AppColors.tealDark,
          AttendancePage(),
        ),
      ],
      UserRole.admin => const <(IconData, String, Color, Widget)>[],
    };
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          6,
          18,
          22 + MediaQueryData.fromView(View.of(context)).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Action rapide',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            const Text(
              'Les actions disponibles sont filtrées par le rôle et les permissions.',
              style: TextStyle(color: AppColors.textSoft, fontSize: 10.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: actions.indexed.expand((entry) {
                final (index, action) = entry;
                return [
                  if (index > 0) const SizedBox(width: 9),
                  Expanded(
                    child: _quick(
                      action.$1,
                      action.$2,
                      action.$3,
                      () => _openPage(context, action.$4),
                    ),
                  ),
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _quick(IconData icon, String label, Color color, VoidCallback onTap) =>
      Material(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            child: Column(
              children: [
                EsgeIconBadge(icon: icon, color: color, size: 39),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EsgeBottomNav extends StatelessWidget {
  const _EsgeBottomNav({
    required this.selectedIndex,
    required this.onChanged,
    required this.onQuickTap,
  });
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onQuickTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: .98),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: AppColors.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x68000000),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: [
            Expanded(child: _item(0, Icons.home_rounded, 'Accueil')),
            Expanded(child: _item(1, Icons.search_rounded, 'Recherche')),
            const SizedBox(width: 58),
            Expanded(
              child: _item(
                2,
                Icons.notifications_none_rounded,
                'Alertes',
                badge: true,
              ),
            ),
            Expanded(child: _item(3, Icons.person_outline_rounded, 'Profil')),
          ],
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onQuickTap,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: AppColors.actionGradient,
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: .48),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.text,
                size: 29,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _item(int index, IconData icon, String label, {bool badge = false}) {
    final active = selectedIndex == index;
    return InkWell(
      onTap: () => onChanged(index),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 21,
                color: active ? AppColors.cyan : AppColors.muted,
              ),
              if (badge)
                Positioned(
                  right: -5,
                  top: -4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.cyan : AppColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  String selectedFilter = 'Tout';
  String query = '';

  List<String> _filters(UserRole role) => switch (role) {
    UserRole.dg => const [
      'Tout',
      'Caisse',
      'Prestataires',
      'Stock',
      'CRM',
      'Documents',
    ],
    UserRole.comptable => const [
      'Tout',
      'Demandes',
      'Caisse',
      'Prestataires',
      'Documents',
    ],
    UserRole.secretaire => const ['Tout', 'Demandes', 'Documents'],
    UserRole.caissier => const ['Tout', 'Caisse', 'Documents'],
    UserRole.magasinier => const ['Tout', 'Stock', 'Documents'],
    UserRole.commercial => const ['Tout', 'CRM', 'Documents'],
    UserRole.admin => const ['Tout'],
  };

  bool _shows(QuickAccessType type) {
    final category = _category(type);
    final matchesFilter =
        selectedFilter == 'Tout' || selectedFilter == category;
    final label = switch (type) {
      QuickAccessType.vouchers => 'Bons récents caisse décaissement',
      QuickAccessType.articles => 'Articles stock inventaire',
      QuickAccessType.prospects => 'Prospects clients rendez-vous CRM',
      QuickAccessType.documents => 'Documents justificatifs factures contrats',
    };
    return matchesFilter &&
        (query.trim().isEmpty ||
            label.toLowerCase().contains(query.toLowerCase()));
  }

  String _category(QuickAccessType type) => switch (type) {
    QuickAccessType.vouchers => 'Caisse',
    QuickAccessType.articles => 'Stock',
    QuickAccessType.prospects => 'CRM',
    QuickAccessType.documents => 'Documents',
  };

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthCubit>().state.user?.role ?? UserRole.dg;
    final filters = _filters(role);
    if (!filters.contains(selectedFilter)) {
      selectedFilter = 'Tout';
    }
    final quickTypes = QuickAccessType.values
        .where((type) => filters.contains(_category(type)) && _shows(type))
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: EsgeGlowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 105),
            children: [
              const Text(
                'Recherche globale',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Prestataires, opérations, bons, articles, prospects, clients, rendez-vous et documents.',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Rechercher une information...',
                  suffixIcon: Icon(Icons.tune_rounded),
                ),
              ),
              const SizedBox(height: 13),
              SizedBox(
                height: 35,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: filters
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: EsgeFilterChip(
                            label: e,
                            selected: e == selectedFilter,
                            color: switch (e) {
                              'Tout' => AppColors.indigo,
                              'Caisse' => AppColors.orange,
                              'Prestataires' => AppColors.plum,
                              'Stock' => AppColors.blue,
                              'CRM' => AppColors.coral,
                              _ => AppColors.violet2,
                            },
                            onSelected: (_) =>
                                setState(() => selectedFilter = e),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Accès rapides',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (quickTypes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('Aucun résultat dans cette catégorie'),
                  ),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.65,
                  crossAxisSpacing: 9,
                  mainAxisSpacing: 9,
                  children: quickTypes.map((type) {
                    final data = switch (type) {
                      QuickAccessType.vouchers => (
                        'Bons récents',
                        '12 nouveaux',
                      ),
                      QuickAccessType.articles => ('Articles', '8 en alerte'),
                      QuickAccessType.prospects => ('Prospects', '24 actifs'),
                      QuickAccessType.documents => (
                        'Documents',
                        '156 fichiers',
                      ),
                    };
                    return _SearchCard(
                      data.$1,
                      data.$2,
                      type.icon,
                      type.color,
                      () => _openQuick(context, type),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 22),
              const Text(
                'Recherches récentes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...[
                ('DEC-0248 • Décaissement', QuickAccessType.vouchers),
                ('Papier A4 • Stock', QuickAccessType.articles),
                ('Nova Conseil • Prospect', QuickAccessType.prospects),
              ].map(
                (item) => InkWell(
                  onTap: () => _openQuick(context, item.$2),
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: AppColors.cyan,
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.$1,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.north_west_rounded,
                          color: AppColors.textSoft,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuick(BuildContext context, QuickAccessType type) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => QuickAccessPage(type: type)),
  );
}

class _SearchCard extends StatelessWidget {
  const _SearchCard(this.title, this.value, this.icon, this.color, this.onTap);
  final String title, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Color.lerp(color, Colors.white, .84),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                    value,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppColors.textSoft,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 11),
          ],
        ),
      ),
    ),
  );
}
