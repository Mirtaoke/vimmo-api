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
    appBar: AppBar(title: Text(widget.title)),
    body: EsgeGlowBackground(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            EsgeGlassCard(
              child: Row(
                children: [
                  EsgeIconBadge(
                    icon: widget.icon,
                    color: AppColors.indigo,
                    size: 46,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configurez ${widget.title.toLowerCase()} selon vos besoins.',
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...values.entries.map(
              (entry) => Card(
                child: SwitchListTile.adaptive(
                  title: Text(entry.key),
                  value: entry.value,
                  activeThumbColor: AppColors.indigo,
                  onChanged: (value) =>
                      setState(() => values[entry.key] = value),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
