import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/esge_ui.dart';
import 'onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: EsgeGlowBackground(
      child: Stack(
        children: [
          Positioned(
            left: -80,
            bottom: 70,
            child: Transform.rotate(
              angle: -.28,
              child: Container(
                width: 280,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.violet.withValues(alpha: .42),
                      AppColors.cyan.withValues(alpha: .06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandMark(),
                  const SizedBox(height: 18),
                  const Text(
                    'Smarter Operations. Stronger Business.',
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 11,
                      letterSpacing: .2,
                    ),
                  ),
                  const SizedBox(height: 42),
                  SizedBox(
                    width: 28,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: AppColors.surface2,
                      color: AppColors.cyan,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
