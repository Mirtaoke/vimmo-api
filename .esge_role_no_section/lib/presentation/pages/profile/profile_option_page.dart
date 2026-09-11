import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/esge_ui.dart';

class ProfileOptionPage extends StatefulWidget {
  const ProfileOptionPage({
    super.key,
    required this.title,
    required this.icon,
    required this.options,
  });

  final String title;
  final IconData icon;
  final List<String> options;

  @override
  State<ProfileOptionPage> createState() => _ProfileOptionPageState();
}

class _ProfileOptionPageState extends State<ProfileOptionPage> {
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF182B55), Color(0xFF5968B0)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.indigo.withValues(alpha: .20),
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
                        const Text(
                          'Personnalisez les options de votre espace.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'PRÉFÉRENCES',
              style: TextStyle(
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
              child: Column(
                children: values.entries.indexed.map((indexed) {
                  final index = indexed.$1;
                  final entry = indexed.$2;
                  return Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        secondary: EsgeIconBadge(
                          icon: index.isEven
                              ? Icons.tune_rounded
                              : Icons.shield_outlined,
                          color: index.isEven
                              ? AppColors.indigo
                              : AppColors.plum,
                          size: 36,
                        ),
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          entry.value ? 'Activé' : 'Désactivé',
                          style: const TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 8.5,
                          ),
                        ),
                        value: entry.value,
                        activeThumbColor: AppColors.indigo,
                        onChanged: (value) =>
                            setState(() => values[entry.key] = value),
                      ),
                      if (index < values.length - 1)
                        const Divider(height: 1, indent: 64),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.textSoft,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Les modifications sont enregistrées automatiquement.',
                      style: TextStyle(color: AppColors.textSoft, fontSize: 9),
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
}
