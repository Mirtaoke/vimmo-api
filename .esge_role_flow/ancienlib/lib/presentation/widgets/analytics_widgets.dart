import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key, required this.items});
  final List<(String, String, IconData, Color)> items;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 105,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: items
          .map(
            (e) => Container(
              width: 148,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: e.$4.withValues(alpha: .35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(e.$3, color: e.$4, size: 20),
                  const Spacer(),
                  Text(
                    e.$2,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    e.$1,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

class BalanceVisual extends StatelessWidget {
  const BalanceVisual({super.key, required this.value});
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF7048E8), Color(0xFF2E61D4), Color(0xFF10B8AD)],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SOLDE DISPONIBLE',
          style: TextStyle(
            color: Colors.white60,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        SizedBox(height: 55, child: CustomPaint(painter: _LinePainter())),
      ],
    ),
  );
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.lime
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * .8)
      ..cubicTo(
        size.width * .18,
        size.height * .9,
        size.width * .2,
        size.height * .2,
        size.width * .42,
        size.height * .48,
      )
      ..cubicTo(
        size.width * .62,
        size.height * .75,
        size.width * .72,
        0,
        size.width,
        size.height * .12,
      );
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProgressTile extends StatelessWidget {
  const ProgressTile({
    super.key,
    required this.title,
    required this.meta,
    required this.value,
    required this.progress,
    required this.color,
    required this.icon,
  });
  final String title, meta, value;
  final double progress;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    meta,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: AppColors.soft,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class PipelineBar extends StatelessWidget {
  const PipelineBar({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PIPELINE DE CONVERSION',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        ...const [
          ('Suspects', 52, .92, AppColors.cyan),
          ('Qualifiés', 31, .68, AppColors.lime),
          ('Négociation', 14, .42, AppColors.violet),
          ('Clients', 6, .2, AppColors.gold),
        ].map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    e.$1,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: e.$3,
                      minHeight: 9,
                      backgroundColor: AppColors.soft,
                      color: e.$4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${e.$2}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
