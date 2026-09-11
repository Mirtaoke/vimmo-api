import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.actions,
    required this.children,
    this.primaryAction,
  });
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final List<String> actions;
  final List<Widget> children;
  final String? primaryAction;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.connectedCanvas,
    appBar: AppBar(
      backgroundColor: AppColors.connectedCanvas,
      foregroundColor: AppColors.ink,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
      ),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
      ],
    ),
    floatingActionButton: primaryAction == null
        ? null
        : FloatingActionButton(
            onPressed: () => _form(context),
            backgroundColor: AppColors.appPurple,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050),
        child: ListView(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 370 ? 14 : 20,
          ),
          children: [
            Container(
              height: 150,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.appPurpleDark,
                    Color.lerp(color, AppColors.appPurple, .55)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(27),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -25,
                    bottom: -38,
                    child: Container(
                      width: 145,
                      height: 145,
                      decoration: BoxDecoration(
                        color: AppColors.peach.withValues(alpha: .65),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 26,
                    top: 26,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(icon, color: Colors.white, size: 36),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESPACE MÉTIER',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 220,
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 78,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: actions
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 76,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: entry.key == 0
                                  ? AppColors.appPurpleDark
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: entry.key == 0
                                    ? AppColors.appPurpleDark
                                    : AppColors.line,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _actionIcon(entry.value),
                                  size: 21,
                                  color: entry.key == 0
                                      ? Colors.white
                                      : AppColors.appPurple,
                                ),
                                const Spacer(),
                                Text(
                                  entry.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: entry.key == 0
                                        ? Colors.white
                                        : AppColors.ink,
                                    fontSize: 9,
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
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: AppColors.ink),
              decoration: InputDecoration(
                fillColor: Colors.white,
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.appPurple,
                ),
                hintText: 'Rechercher dans $title',
                hintStyle: const TextStyle(color: AppColors.muted),
                suffixIcon: const Icon(Icons.tune, color: AppColors.appPurple),
              ),
            ),
            const SizedBox(height: 20),
            ...children,
            const SizedBox(height: 70),
          ],
        ),
      ),
    ),
  );
  IconData _actionIcon(String value) {
    final v = value.toLowerCase();
    if (v.contains('entrée')) {
      return Icons.login;
    }
    if (v.contains('sortie')) {
      return Icons.logout;
    }
    if (v.contains('rapport') || v.contains('historique')) {
      return Icons.analytics;
    }
    if (v.contains('inventaire')) {
      return Icons.qr_code_scanner;
    }
    if (v.contains('client') || v.contains('prospect')) {
      return Icons.people;
    }
    if (v.contains('document')) {
      return Icons.folder;
    }
    return Icons.grid_view_rounded;
  }

  void _form(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primaryAction!,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          const TextField(
            decoration: InputDecoration(labelText: 'Libellé / objet'),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(labelText: 'Référence ou montant'),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 2,
            decoration: InputDecoration(labelText: 'Commentaire'),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.peach, AppColors.appPurple],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    ),
  );
}
