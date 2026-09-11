import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final controller = PageController();
  int index = 0;
  static const slides = [
    (
      'Une seule vision.\nToute votre entreprise.',
      'Pilotez la finance, le stock, les équipes et votre croissance depuis un espace unique.',
      Icons.dashboard_customize_rounded,
    ),
    (
      'Chaque décision,\nparfaitement maîtrisée.',
      'Contrôle comptable, validation DG et exécution caisse dans un workflow clair et traçable.',
      Icons.verified_user_rounded,
    ),
    (
      'Votre croissance\nne s’arrête jamais.',
      'Transformez vos prospects en clients et gardez une longueur d’avance, partout.',
      Icons.trending_up_rounded,
    ),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.connectedCanvas,
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: slides.length,
              onPageChanged: (value) => setState(() => index = value),
              itemBuilder: (_, i) => _slide(slides[i], i),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == index ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == index
                            ? AppColors.appPurple
                            : AppColors.line,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.appPurpleDark,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (index < slides.length - 1) {
                      controller.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    }
                  },
                  child: Text(
                    index == slides.length - 1 ? 'Commencer' : 'Suivant',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _slide((String, String, IconData) slide, int i) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
    child: Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: i == 0
                    ? const [
                        Color(0xFFFFF4EF),
                        Color(0xFFF0EAFE),
                        AppColors.appPurpleDark,
                      ]
                    : i == 1
                    ? const [
                        Color(0xFFFFF6F2),
                        Color(0xFFFFB29F),
                        AppColors.appPurple,
                      ]
                    : const [
                        Color(0xFFF4F0FF),
                        Color(0xFF9D7BEF),
                        AppColors.appPurpleDark,
                      ],
              ),
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: AppColors.appPurple.withValues(alpha: .22),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: Image.asset(
                      'assets/images/esge_onboarding_hero.png',
                      fit: BoxFit.cover,
                      alignment: i == 0
                          ? Alignment.topCenter
                          : Alignment.center,
                      color: i == 0
                          ? null
                          : Colors.white.withValues(alpha: .22),
                      colorBlendMode: BlendMode.screen,
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(slide.$3, size: 16, color: AppColors.appPurple),
                        const SizedBox(width: 7),
                        const Text(
                          'ESGE',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          slide.$1,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 31,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.3,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          slide.$2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            height: 1.5,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}
