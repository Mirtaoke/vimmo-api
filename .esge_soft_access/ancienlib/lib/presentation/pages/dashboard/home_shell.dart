import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../business_logic/dashboard/dashboard_cubit.dart';
import '../../../business_logic/dashboard/dashboard_state.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import 'role_dashboard_page.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user);
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final pages = [
          RoleDashboardPage(role: user!.role),
          const GlobalSearchPage(),
          const NotificationsPage(),
          const ProfilePage(),
        ];
        return Scaffold(
          backgroundColor: AppColors.connectedCanvas,
          body: pages[state.selectedIndex],
          bottomNavigationBar: NavigationBar(
            backgroundColor: Colors.white,
            indicatorColor: AppColors.lavender,
            selectedIndex: state.selectedIndex,
            onDestinationSelected: context.read<DashboardCubit>().selectTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(Icons.search),
                label: 'Recherche',
              ),
              NavigationDestination(
                icon: Badge(
                  label: Text('5'),
                  child: Icon(Icons.notifications_none),
                ),
                label: 'Alertes',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }
}

class GlobalSearchPage extends StatelessWidget {
  const GlobalSearchPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.connectedCanvas,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        children: [
          const Text(
            'Explorer',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const Text(
            'Retrouvez instantanément chaque donnée de l’entreprise.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Prestataire, bon, article, prospect, document…',
              suffixIcon: Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Tout', 'Caisse', 'Stock', 'CRM', 'Documents']
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(e),
                        selected: e == 'Tout',
                        onSelected: (_) {},
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Accès rapides',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: const [
              _SearchCard(
                'Bons récents',
                '12 nouveaux',
                Icons.receipt_long_rounded,
                AppColors.peach,
              ),
              _SearchCard(
                'Articles',
                '8 en alerte',
                Icons.inventory_2_rounded,
                AppColors.violet,
              ),
              _SearchCard(
                'Prospects',
                '24 actifs',
                Icons.people_alt_rounded,
                AppColors.gold,
              ),
              _SearchCard(
                'Documents',
                '156 fichiers',
                Icons.folder_copy_rounded,
                AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Recherches récentes',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...[
            'DEC-0248 • Décaissement',
            'Papier A4 • Stock',
            'Nova Conseil • Prestataire',
          ].map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: AppColors.appPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Icon(Icons.north_west, size: 17),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SearchCard extends StatelessWidget {
  const _SearchCard(this.title, this.value, this.icon, this.color);
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withValues(alpha: .28), Colors.white],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
