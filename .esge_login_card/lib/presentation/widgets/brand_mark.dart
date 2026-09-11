import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.dark = true, this.compact = false});
  final bool dark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 46.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _pill(size * .66, size * .24, -8, -8, const [
                AppColors.aqua,
                AppColors.cyan,
              ]),
              _pill(size * .70, size * .24, -8, 0, const [
                AppColors.blue,
                AppColors.cyan,
              ]),
              _pill(size * .66, size * .24, -8, 8, const [
                AppColors.violet,
                AppColors.violet2,
              ]),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: compact ? 18 : 23,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
                color: AppColors.text,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              const Text(
                'MANAGE • OPERATE • GROW',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _pill(
    double w,
    double h,
    double angleDegrees,
    double y,
    List<Color> colors,
  ) => Transform.translate(
    offset: Offset(0, y),
    child: Transform.rotate(
      angle: angleDegrees * 3.1415926535 / 180,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: .35),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    ),
  );
}
