import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/esge_ui.dart';

enum QuickAccessType { vouchers, articles, prospects, documents }

extension QuickAccessTypeX on QuickAccessType {
  String get title => switch (this) {
    QuickAccessType.vouchers => 'Bons récents',
    QuickAccessType.articles => 'Articles & stock',
    QuickAccessType.prospects => 'Prospects actifs',
    QuickAccessType.documents => 'Documents',
  };

  String get subtitle => switch (this) {
    QuickAccessType.vouchers => 'Suivi des bons, montants et validations',
    QuickAccessType.articles => 'Disponibilités, seuils et mouvements',
    QuickAccessType.prospects => 'Opportunités et prochaines actions',
    QuickAccessType.documents => 'Fichiers partagés et pièces métier',
  };

  IconData get icon => switch (this) {
    QuickAccessType.vouchers => Icons.receipt_long_rounded,
    QuickAccessType.articles => Icons.inventory_2_rounded,
    QuickAccessType.prospects => Icons.people_alt_rounded,
    QuickAccessType.documents => Icons.folder_copy_rounded,
  };

  Color get color => switch (this) {
    QuickAccessType.vouchers => AppColors.orange,
    QuickAccessType.articles => AppColors.indigo,
    QuickAccessType.prospects => AppColors.coral,
    QuickAccessType.documents => AppColors.plum,
  };
}

class QuickAccessPage extends StatefulWidget {
  const QuickAccessPage({super.key, required this.type});
  final QuickAccessType type;

  @override
  State<QuickAccessPage> createState() => _QuickAccessPageState();
}

class _QuickAccessPageState extends State<QuickAccessPage> {
  String query = '';
  String filter = 'Tous';

  List<_QuickRecord> get records => _data[widget.type]!;

  @override
  Widget build(BuildContext context) {
    final color = widget.type.color;
    final visible = records.where((record) {
      final matchesQuery = '${record.title} ${record.reference} ${record.meta}'
          .toLowerCase()
          .contains(query.toLowerCase());
      return matchesQuery && (filter == 'Tous' || record.status == filter);
    }).toList();
    final statuses = [
      'Tous',
      ...{for (final item in records) item.status},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.type.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(
                      widget.type.icon,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${records.length} éléments',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          widget.type.subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Rechercher...',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: statuses.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final value = statuses[index];
                  return ChoiceChip(
                    label: Text(value),
                    selected: filter == value,
                    onSelected: (_) => setState(() => filter = value),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Résultats',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  '${visible.length}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(
                  child: Text(
                    'Aucun résultat',
                    style: TextStyle(color: AppColors.textSoft),
                  ),
                ),
              )
            else
              ...visible.map((record) => _recordCard(context, record, color)),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(
    BuildContext context,
    _QuickRecord record,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(21),
        side: const BorderSide(color: AppColors.line, width: 1.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: () => _details(context, record),
        leading: EsgeIconBadge(icon: widget.type.icon, color: color, size: 44),
        title: Text(
          record.title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        subtitle: Text(
          '${record.reference} • ${record.meta}',
          style: const TextStyle(fontSize: 10.5),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              record.value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              record.status,
              style: const TextStyle(color: AppColors.textSoft, fontSize: 9),
            ),
          ],
        ),
      ),
    ),
  );

  void _details(BuildContext context, _QuickRecord record) =>
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
              EsgeIconBadge(
                icon: widget.type.icon,
                color: widget.type.color,
                size: 52,
              ),
              const SizedBox(height: 14),
              Text(
                record.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${record.reference} • ${record.meta}',
                style: const TextStyle(color: AppColors.textSoft),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _info('Valeur', record.value)),
                  const SizedBox(width: 10),
                  Expanded(child: _info('Statut', record.status)),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Fermer'),
              ),
            ],
          ),
        ),
      );

  Widget _info(String label, String value) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.soft,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSoft, fontSize: 10),
        ),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );

  void _create(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        8,
        22,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQueryData.fromView(View.of(context)).viewPadding.bottom +
            22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nouveau — ${widget.type.title}',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'Libellé')),
          const SizedBox(height: 10),
          const TextField(
            decoration: InputDecoration(labelText: 'Référence / valeur'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
}

class _QuickRecord {
  const _QuickRecord(
    this.title,
    this.reference,
    this.meta,
    this.value,
    this.status,
  );
  final String title, reference, meta, value, status;
}

const _data = <QuickAccessType, List<_QuickRecord>>{
  QuickAccessType.vouchers: [
    _QuickRecord(
      'Achat fournitures bureau',
      'BON-0258',
      'Aujourd’hui, 09:42',
      '185 000 F',
      'À valider',
    ),
    _QuickRecord(
      'Mission commerciale Porto-Novo',
      'BON-0257',
      'Aujourd’hui, 08:15',
      '72 500 F',
      'Validé',
    ),
    _QuickRecord(
      'Maintenance groupe électrogène',
      'BON-0256',
      'Hier, 16:20',
      '310 000 F',
      'Exécuté',
    ),
    _QuickRecord(
      'Abonnement internet',
      'BON-0255',
      'Hier, 11:05',
      '95 000 F',
      'À contrôler',
    ),
  ],
  QuickAccessType.articles: [
    _QuickRecord(
      'Papier A4 Double A',
      'ART-0018',
      'Magasin principal',
      '12 unités',
      'Stock faible',
    ),
    _QuickRecord(
      'Cartouche HP 305',
      'ART-0042',
      'Magasin principal',
      '28 unités',
      'Disponible',
    ),
    _QuickRecord(
      'Clavier sans fil',
      'ART-0087',
      'Dépôt annexe',
      '6 unités',
      'Stock faible',
    ),
    _QuickRecord(
      'Ramette chemises cartonnées',
      'ART-0112',
      'Magasin principal',
      '84 unités',
      'Disponible',
    ),
  ],
  QuickAccessType.prospects: [
    _QuickRecord(
      'Groupe Horizon',
      'PRO-1024',
      'Relance aujourd’hui',
      '4,8 M F',
      'Négociation',
    ),
    _QuickRecord(
      'Clinique Les Oliviers',
      'PRO-1021',
      'RDV demain, 10:00',
      '2,1 M F',
      'Qualifié',
    ),
    _QuickRecord(
      'Nova Conseil',
      'PRO-1018',
      'Proposition envoyée',
      '1,4 M F',
      'Proposition',
    ),
    _QuickRecord(
      'Maison Kora',
      'PRO-1014',
      'Contacté il y a 2 jours',
      '850 000 F',
      'Nouveau',
    ),
  ],
  QuickAccessType.documents: [
    _QuickRecord(
      'Contrat Nova Conseil.pdf',
      'DOC-481',
      'Direction commerciale',
      '2,4 Mo',
      'Partagé',
    ),
    _QuickRecord(
      'Rapport caisse août.xlsx',
      'DOC-479',
      'Comptabilité',
      '860 Ko',
      'Récent',
    ),
    _QuickRecord(
      'Inventaire dépôt.pdf',
      'DOC-475',
      'Magasin',
      '4,1 Mo',
      'Archivé',
    ),
    _QuickRecord(
      'Procès-verbal réunion.docx',
      'DOC-472',
      'Direction générale',
      '320 Ko',
      'Partagé',
    ),
  ],
};
