import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'esge_ui.dart';

class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.status,
    this.icon = Icons.receipt_long_rounded,
    this.onTap,
  });

  final String title, subtitle, value, status;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  Color get _semanticColor {
    final s = status.toLowerCase();
    if (s.contains('refus') || s.contains('rupture') || s.contains('perdu')) {
      return AppColors.red;
    }
    if (s.contains('attente') ||
        s.contains('pending') ||
        s.contains('retour') ||
        s.contains('faible')) {
      return AppColors.yellow;
    }
    if (s.contains('exécut') ||
        s.contains('valid') ||
        s.contains('actif') ||
        s.contains('pay') ||
        s.contains('convert')) {
      return AppColors.green;
    }
    return color;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              EsgeIconBadge(icon: icon, color: color, size: 43),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 9.5,
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
                    value,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  EsgeStatusChip(status, color: _semanticColor),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
