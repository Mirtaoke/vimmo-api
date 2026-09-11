import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/esge_ui.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String selectedFilter = 'Toutes';
  final Set<int> readNotificationIds = {};

  static const filterColors = <String, Color>{
    'Toutes': AppColors.indigo,
    'Non lues': AppColors.plum,
    'Validations': AppColors.orange,
    'Alertes': AppColors.red,
  };

  @override
  Widget build(BuildContext context) {
    final unreadCount = 3 - readNotificationIds.length.clamp(0, 3);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: EsgeGlowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 105),
            children: [
              Row(
                children: [
                  const BrandMark(compact: true),
                  const Spacer(),
                  EsgeStatusChip('$unreadCount non lues', color: AppColors.red),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(
                      () => readNotificationIds.addAll(const [0, 1, 2]),
                    ),
                    child: const Text(
                      'Tout marquer comme lu',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Validations, stocks, rendez-vous, caisse et pointage.',
                style: TextStyle(color: AppColors.textSoft, fontSize: 10.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 35,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['Toutes', 'Non lues', 'Validations', 'Alertes']
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: EsgeFilterChip(
                            label: e,
                            selected: e == selectedFilter,
                            color: filterColors[e]!,
                            onSelected: (_) =>
                                setState(() => selectedFilter = e),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aujourd’hui',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              _notification(
                0,
                'Demande à valider',
                'DEC-0248 est prête pour votre validation.',
                '10:45',
                Icons.verified_user_outlined,
                AppColors.cyan,
                true,
              ),
              _notification(
                1,
                'Stock faible',
                'Papier A4 est passé sous le seuil minimum.',
                '09:18',
                Icons.inventory_2_outlined,
                AppColors.orange,
                true,
              ),
              _notification(
                2,
                'Nouveau prospect',
                'Nova Conseil a été ajouté au pipeline.',
                '08:42',
                Icons.person_add_alt_1_outlined,
                AppColors.violet,
                true,
              ),
              const SizedBox(height: 12),
              const Text(
                'Hier',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 9),
              _notification(
                3,
                'Paiement exécuté',
                'Le bon BC-0081 a été clôturé avec succès.',
                'Hier',
                Icons.payments_outlined,
                AppColors.green,
                false,
              ),
              _notification(
                4,
                'Pointage confirmé',
                'Votre présence a été enregistrée.',
                'Hier',
                Icons.fingerprint_rounded,
                AppColors.blue,
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notification(
    int id,
    String title,
    String body,
    String time,
    IconData icon,
    Color color,
    bool initiallyUnread,
  ) {
    final unread = initiallyUnread && !readNotificationIds.contains(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: unread ? color.withValues(alpha: .28) : AppColors.line,
          ),
        ),
        child: InkWell(
          onTap: () => setState(() => readNotificationIds.add(id)),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                EsgeIconBadge(icon: icon, color: color, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 9,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (unread)
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: color, blurRadius: 7)],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
