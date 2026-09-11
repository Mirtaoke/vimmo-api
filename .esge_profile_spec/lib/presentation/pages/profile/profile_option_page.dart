import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/esge_ui.dart';

enum ProfileOptionKind { toggles, permissions, sessions, history }

class ProfileOptionPage extends StatefulWidget {
  const ProfileOptionPage({
    super.key,
    required this.title,
    required this.icon,
    required this.options,
    required this.color,
    this.kind = ProfileOptionKind.toggles,
  });

  final String title;
  final IconData icon;
  final List<String> options;
  final Color color;
  final ProfileOptionKind kind;

  @override
  State<ProfileOptionPage> createState() => _ProfileOptionPageState();
}

class _ProfileOptionPageState extends State<ProfileOptionPage> {
  late final List<String> visibleOptions = [...widget.options];
  late final Map<String, bool> values = {
    for (final option in widget.options) option: true,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 56,
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    ),
    body: EsgeGlowBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _header(),
            const SizedBox(height: 20),
            Text(
              _sectionLabel,
              style: const TextStyle(
                color: AppColors.textSoft,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 9),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140B281E),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(children: _items()),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: widget.color,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _footer,
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color.lerp(AppColors.navy, widget.color, .28)!, widget.color],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: widget.color.withValues(alpha: .22),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _headerSubtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 9.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  List<Widget> _items() => visibleOptions.indexed.map((indexed) {
    final index = indexed.$1;
    final option = indexed.$2;
    return Column(
      children: [
        if (widget.kind == ProfileOptionKind.toggles)
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 2,
            ),
            secondary: EsgeIconBadge(
              icon: Icons.notifications_active_outlined,
              color: widget.color,
              size: 36,
            ),
            title: _title(option),
            subtitle: _subtitle(values[option]! ? 'Activé' : 'Désactivé'),
            value: values[option]!,
            activeThumbColor: widget.color,
            onChanged: (value) => setState(() => values[option] = value),
          )
        else
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 5,
            ),
            leading: EsgeIconBadge(
              icon: _itemIcon,
              color: widget.color,
              size: 36,
            ),
            title: _title(option),
            subtitle: _subtitle(_itemSubtitle(index)),
            trailing: _trailing(index),
          ),
        if (index < visibleOptions.length - 1)
          const Divider(height: 1, indent: 64),
      ],
    );
  }).toList();

  Widget _title(String value) => Text(
    value,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
  );

  Widget _subtitle(String value) => Text(
    value,
    style: const TextStyle(color: AppColors.textSoft, fontSize: 8.5),
  );

  Widget _trailing(int index) => switch (widget.kind) {
    ProfileOptionKind.permissions => EsgeStatusChip(
      'Autorisé',
      color: widget.color,
    ),
    ProfileOptionKind.sessions =>
      index == 0
          ? EsgeStatusChip('Cet appareil', color: widget.color)
          : IconButton(
              tooltip: 'Déconnecter cet appareil',
              onPressed: () => setState(() => visibleOptions.removeAt(index)),
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.red,
                size: 18,
              ),
            ),
    ProfileOptionKind.history => Icon(
      Icons.check_circle_rounded,
      color: widget.color,
      size: 18,
    ),
    ProfileOptionKind.toggles => const SizedBox.shrink(),
  };

  IconData get _itemIcon => switch (widget.kind) {
    ProfileOptionKind.permissions => Icons.verified_user_outlined,
    ProfileOptionKind.sessions => Icons.devices_outlined,
    ProfileOptionKind.history => Icons.history_rounded,
    ProfileOptionKind.toggles => Icons.tune_rounded,
  };

  String _itemSubtitle(int index) => switch (widget.kind) {
    ProfileOptionKind.permissions => 'Accordée par le rôle et l’administration',
    ProfileOptionKind.sessions =>
      index == 0
          ? 'Cotonou • Active maintenant'
          : 'Dernière activité il y a 2 jours',
    ProfileOptionKind.history =>
      index == 0
          ? 'Aujourd’hui à 08:42 • Cotonou'
          : index == 1
          ? 'Hier à 17:36 • Cotonou'
          : '28 août à 07:55 • Porto-Novo',
    ProfileOptionKind.toggles => '',
  };

  String get _sectionLabel => switch (widget.kind) {
    ProfileOptionKind.permissions => 'AUTORISATIONS ACTIVES',
    ProfileOptionKind.sessions => 'APPAREILS CONNECTÉS',
    ProfileOptionKind.history => 'CONNEXIONS RÉCENTES',
    ProfileOptionKind.toggles => 'PRÉFÉRENCES',
  };

  String get _headerSubtitle => switch (widget.kind) {
    ProfileOptionKind.permissions => 'Droits accordés à votre compte',
    ProfileOptionKind.sessions => 'Contrôlez les accès à votre compte',
    ProfileOptionKind.history => 'Traçabilité de vos authentifications',
    ProfileOptionKind.toggles => 'Choisissez les alertes à recevoir',
  };

  String get _footer => switch (widget.kind) {
    ProfileOptionKind.permissions =>
      'Les permissions sont modifiées uniquement depuis l’administration Web.',
    ProfileOptionKind.sessions =>
      'Vous pouvez déconnecter tout appareil que vous ne reconnaissez pas.',
    ProfileOptionKind.history =>
      'Signalez immédiatement toute connexion que vous ne reconnaissez pas.',
    ProfileOptionKind.toggles =>
      'Les préférences sont enregistrées automatiquement.',
  };
}
