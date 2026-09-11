import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.dark = false});
  final bool dark;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: dark ? Colors.white : AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.layers_rounded,
          color: dark ? AppColors.primary : Colors.white,
        ),
      ),
      const SizedBox(width: 11),
      Text(
        AppConstants.appName,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: dark ? Colors.white : AppColors.ink,
        ),
      ),
    ],
  );
}
