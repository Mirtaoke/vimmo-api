import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class EsgeGradientButton extends StatelessWidget {
  const EsgeGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: AppColors.actionGradient),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppColors.violet.withValues(alpha: .28),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: AppColors.text),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class EsgeGlassCard extends StatelessWidget {
  const EsgeGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.borderColor,
  });
  final Widget child;
  final EdgeInsets padding;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: gradient == null ? AppColors.surface : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor ?? AppColors.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x27000000),
          blurRadius: 20,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: child,
  );
}

class EsgeStatusChip extends StatelessWidget {
  const EsgeStatusChip(this.label, {super.key, this.color = AppColors.cyan});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
    ),
  );
}

class EsgeFilterChip extends StatelessWidget {
  const EsgeFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final Color color;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: false,
    backgroundColor: color.withValues(alpha: .07),
    selectedColor: color.withValues(alpha: .20),
    side: BorderSide(
      color: color.withValues(alpha: selected ? .58 : .20),
      width: selected ? 1.25 : 1,
    ),
    labelStyle: TextStyle(
      color: selected ? color : AppColors.textSoft,
      fontSize: 11,
      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
    ),
  );
}

class EsgeIconBadge extends StatelessWidget {
  const EsgeIconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.cyan,
    this.size = 42,
  });
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(size * .32),
      border: Border.all(color: color.withValues(alpha: .20)),
    ),
    child: Icon(icon, color: color, size: size * .48),
  );
}

class EsgeGlowBackground extends StatelessWidget {
  const EsgeGlowBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE0F5E8), AppColors.background, Color(0xFFF9FFFB)],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          top: -120,
          right: -100,
          child: _orb(280, AppColors.cyan, .24),
        ),
        Positioned(
          top: 80,
          left: -150,
          child: _orb(320, AppColors.violet, .12),
        ),
        Positioned(
          bottom: -150,
          right: -120,
          child: _orb(300, AppColors.green, .12),
        ),
        child,
      ],
    ),
  );

  static Widget _orb(double size, Color color, double opacity) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    ),
  );
}
