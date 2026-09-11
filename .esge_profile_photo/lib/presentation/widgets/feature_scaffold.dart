import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'esge_ui.dart';

/// Shared shell for ESGE modules. It mirrors the dark premium template:
/// compact title bar, gradient summary card, horizontal action chips, search,
/// dense glass cards and a uniform visual language across all roles.
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
    backgroundColor: AppColors.background,
    floatingActionButton: primaryAction == null
        ? null
        : Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.actionGradient),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: .32),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _form(context),
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                primaryAction!,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
    body: EsgeGlowBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width < 370 ? 14 : 18,
                12,
                MediaQuery.sizeOf(context).width < 370 ? 14 : 18,
                100,
              ),
              children: [
                _topBar(context),
                const SizedBox(height: 18),
                _hero(),
                const SizedBox(height: 16),
                _actions(context),
                const SizedBox(height: 15),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'Rechercher dans $title',
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _topBar(BuildContext context) => Row(
    children: [
      if (Navigator.canPop(context))
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSoft, fontSize: 11),
            ),
          ],
        ),
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: (value) => _notify(context, value),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'Données actualisées',
            child: Text('Actualiser'),
          ),
          PopupMenuItem(
            value: 'Export préparé',
            child: Text('Exporter la vue'),
          ),
        ],
      ),
    ],
  );

  Widget _hero() => Container(
    height: 154,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.heroGradient,
      ),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: AppColors.cyan.withValues(alpha: .18)),
      boxShadow: [
        BoxShadow(
          color: AppColors.cyan.withValues(alpha: .12),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
        BoxShadow(
          color: AppColors.violet.withValues(alpha: .10),
          blurRadius: 34,
          offset: const Offset(10, 8),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -38,
          top: -52,
          child: _bubble(150, Colors.white.withValues(alpha: .06)),
        ),
        Positioned(
          right: 34,
          bottom: -54,
          child: _bubble(105, AppColors.violet.withValues(alpha: .12)),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
            ),
            child: Icon(icon, color: AppColors.cyan, size: 29),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'ESGE • ESPACE MÉTIER',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 255,
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 10.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _bubble(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _actions(BuildContext context) => SizedBox(
    height: 76,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: actions.length,
      separatorBuilder: (context, index) => const SizedBox(width: 9),
      itemBuilder: (_, i) {
        final active = i == 0;
        return InkWell(
          onTap: () => _showAction(context, actions[i]),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 86,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: [
                        color.withValues(alpha: .20),
                        color.withValues(alpha: .08),
                      ],
                    )
                  : null,
              color: active ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active ? color.withValues(alpha: .48) : AppColors.line,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _actionIcon(actions[i]),
                  size: 20,
                  color: active ? color : AppColors.textSoft,
                ),
                const Spacer(),
                Text(
                  actions[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? AppColors.text : AppColors.textSoft,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  IconData _actionIcon(String value) {
    final v = value.toLowerCase();
    if (v.contains('entrée')) {
      return Icons.south_west_rounded;
    }
    if (v.contains('sortie')) {
      return Icons.north_east_rounded;
    }
    if (v.contains('rapport') || v.contains('historique')) {
      return Icons.insights_rounded;
    }
    if (v.contains('inventaire')) {
      return Icons.inventory_2_outlined;
    }
    if (v.contains('client') || v.contains('prospect')) {
      return Icons.people_alt_outlined;
    }
    if (v.contains('document')) {
      return Icons.folder_copy_outlined;
    }
    if (v.contains('validation') || v.contains('contrô')) {
      return Icons.verified_user_outlined;
    }
    if (v.contains('recherche')) {
      return Icons.search_rounded;
    }
    if (v.contains('pointage')) {
      return Icons.fingerprint_rounded;
    }
    return Icons.grid_view_rounded;
  }

  void _form(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQueryData.fromView(View.of(context)).viewPadding.bottom +
            24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            primaryAction!,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'Saisissez les informations requises. Le formulaire est prêt à être relié à l’API Laravel.',
            style: TextStyle(color: AppColors.textSoft, fontSize: 11),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(labelText: 'Libellé / objet'),
          ),
          const SizedBox(height: 10),
          const TextField(
            decoration: InputDecoration(labelText: 'Référence / montant'),
          ),
          const SizedBox(height: 10),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(labelText: 'Commentaire'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _notify(context, 'Justificatif prêt à être joint'),
            icon: const Icon(Icons.attach_file_rounded),
            label: const Text('Joindre un justificatif'),
          ),
          const SizedBox(height: 12),
          EsgeGradientButton(
            label: 'Enregistrer',
            onPressed: () => Navigator.pop(context),
            icon: Icons.check_rounded,
          ),
        ],
      ),
    ),
  );

  void _showAction(BuildContext context, String action) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) {
      var showItems = false;
      return StatefulBuilder(
        builder: (_, updateSheet) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .78,
          ),
          child: SingleChildScrollView(
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
                EsgeIconBadge(
                  icon: _actionIcon(action),
                  color: color,
                  size: 52,
                ),
                const SizedBox(height: 14),
                Text(
                  action,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Données disponibles dans le module $title.',
                  style: const TextStyle(color: AppColors.textSoft),
                ),
                const SizedBox(height: 18),
                if (showItems) ...[
                  ..._actionItems(
                    action,
                  ).map((item) => _sheetRecord(item.$1, item.$2, item.$3)),
                  const SizedBox(height: 8),
                ],
                FilledButton.icon(
                  onPressed: showItems
                      ? () => Navigator.pop(sheetContext)
                      : () => updateSheet(() => showItems = true),
                  icon: Icon(
                    showItems ? Icons.close_rounded : Icons.visibility_outlined,
                  ),
                  label: Text(showItems ? 'Fermer' : 'Afficher les éléments'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  List<(String, String, String)> _actionItems(String action) {
    final normalized = action.toLowerCase();
    if (normalized.contains('entrée') || normalized.contains('sortie')) {
      return const [
        ('Approvisionnement caisse', 'ENT-0089 • Aujourd’hui', '+ 5 000 000 F'),
        ('Mission commerciale', 'SOR-0142 • Hier', '− 485 000 F'),
        ('Frais de fonctionnement', 'SOR-0138 • 24 août', '− 175 000 F'),
      ];
    }
    if (normalized.contains('client') || normalized.contains('prospect')) {
      return const [
        ('Nova Conseil', 'Proposition envoyée • 82 %', '4 800 000 F'),
        ('Horizon SARL', 'Rendez-vous demain • 64 %', '2 350 000 F'),
        ('Bénin Services', 'Relance à effectuer • 48 %', '1 900 000 F'),
      ];
    }
    if (normalized.contains('stock') || normalized.contains('article')) {
      return const [
        ('Papier A4 Premium', 'STK-0042 • Stock faible', '12 unités'),
        ('Cartouche HP 305', 'STK-0118 • Disponible', '48 unités'),
        ('Classeur archive', 'STK-0084 • Disponible', '126 unités'),
      ];
    }
    if (normalized.contains('document') || normalized.contains('facture')) {
      return const [
        ('FACT-2026-084.pdf', 'Facture prestataire • 1,8 Mo', 'Aujourd’hui'),
        ('BON-CAISSE-0248.pdf', 'Bon de caisse • 640 Ko', 'Hier'),
        ('CONTRAT-NOVA.pdf', 'Contrat commercial • 2,1 Mo', '22 août'),
      ];
    }
    return [
      (
        '$action — élément 01',
        'Référence ESGE-0248 • À traiter',
        'Prioritaire',
      ),
      ('$action — élément 02', 'Référence ESGE-0186 • En cours', 'Actualisé'),
      ('$action — élément 03', 'Référence ESGE-0124 • Terminé', 'Archivé'),
    ];
  }

  Widget _sheetRecord(String name, String meta, String value) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        EsgeIconBadge(icon: _actionIcon(name), color: color, size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                meta,
                style: const TextStyle(color: AppColors.textSoft, fontSize: 9),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  void _notify(BuildContext context, String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
