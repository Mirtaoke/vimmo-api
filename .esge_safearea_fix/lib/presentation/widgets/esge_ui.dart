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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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
      gradient: LinearGradient(
        colors: [color.withValues(alpha: .25), color.withValues(alpha: .08)],
      ),
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
        colors: [Color(0xFF0C2D22), AppColors.background, Color(0xFF09241B)],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          top: -120,
          right: -100,
          child: _orb(280, AppColors.cyan, .14),
        ),
        Positioned(
          top: 80,
          left: -150,
          child: _orb(320, AppColors.violet, .10),
        ),
        Positioned(
          bottom: -150,
          right: -120,
          child: _orb(300, AppColors.blue, .08),
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
