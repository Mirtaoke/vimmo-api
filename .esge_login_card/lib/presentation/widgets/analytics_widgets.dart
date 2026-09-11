import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'esge_ui.dart';

class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key, required this.items});
  final List<(String, String, IconData, Color)> items;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(items.length, (i) {
      final item = items[i];
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
          child: EsgeGlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EsgeIconBadge(icon: item.$3, color: item.$4, size: 31),
                    const Spacer(),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: item.$4,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: item.$4, blurRadius: 7)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.$2,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.$1,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 8.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}

class BalanceVisual extends StatelessWidget {
  const BalanceVisual({super.key, required this.value});
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 162,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B3B2C), Color(0xFF27775A), Color(0xFF69A982)],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.cyan.withValues(alpha: .18),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -12,
          top: -28,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white70,
                  size: 19,
                ),
                SizedBox(width: 7),
                Text(
                  'SOLDE DISPONIBLE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.green,
                  size: 15,
                ),
                SizedBox(width: 4),
                Text(
                  '+8,4 % ce mois',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class PipelineBar extends StatelessWidget {
  const PipelineBar({super.key});
  @override
  Widget build(BuildContext context) => EsgeGlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'PIPELINE COMMERCIAL',
              style: TextStyle(
                color: AppColors.textSoft,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            Spacer(),
            EsgeStatusChip('+12 %', color: AppColors.green),
          ],
        ),
        const SizedBox(height: 15),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Row(
            children: const [
              Expanded(
                flex: 34,
                child: ColoredBox(
                  color: AppColors.cyan,
                  child: SizedBox(height: 9),
                ),
              ),
              Expanded(
                flex: 26,
                child: ColoredBox(
                  color: AppColors.blue,
                  child: SizedBox(height: 9),
                ),
              ),
              Expanded(
                flex: 22,
                child: ColoredBox(
                  color: AppColors.violet,
                  child: SizedBox(height: 9),
                ),
              ),
              Expanded(
                flex: 18,
                child: ColoredBox(
                  color: AppColors.green,
                  child: SizedBox(height: 9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _LegendDot('Prospects', AppColors.cyan),
            _LegendDot('Propositions', AppColors.blue),
            _LegendDot('Négociation', AppColors.violet),
            _LegendDot('Clients', AppColors.green),
          ],
        ),
      ],
    ),
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(color: AppColors.textSoft, fontSize: 7.5),
      ),
    ],
  );
}

class SparklineBars extends StatelessWidget {
  const SparklineBars({
    super.key,
    this.values = const [34, 52, 42, 68, 58, 76, 61],
    this.height = 78,
  });
  final List<double> values;
  final double height;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        values.length,
        (i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              height: values[i],
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: i.isEven
                      ? const [AppColors.violet, AppColors.cyan]
                      : const [Color(0xFF417D65), AppColors.blue],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ProgressTile extends StatelessWidget {
  const ProgressTile({
    super.key,
    required this.title,
    required this.meta,
    required this.value,
    required this.progress,
    required this.icon,
    required this.color,
  });
  final String title, meta, value;
  final double progress;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 8.5,
                ),
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppColors.surface3,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
