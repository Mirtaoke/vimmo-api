import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/esge_ui.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController controller = PageController();
  int index = 0;

  static const slides = [
    (
      'Pilotez votre entreprise\navec clarté.',
      'Finance, équipes, stock, CRM et présence dans une expérience unique.',
      Icons.insights_rounded,
      'Vue consolidée',
    ),
    (
      'Contrôlez chaque\nvalidation.',
      'Le workflow suit exactement la saisie, le contrôle, la validation, l’exécution et la traçabilité.',
      Icons.verified_user_rounded,
      'Workflow sécurisé',
    ),
    (
      'Transformez chaque\nopportunité.',
      'Suspects, prospects, rendez-vous, propositions et clients restent connectés dans le même parcours.',
      Icons.trending_up_rounded,
      'CRM complet',
    ),
  ];

  static const illustrations = [
    'assets/images/onboarding_control.png',
    'assets/images/onboarding_workflow.png',
    'assets/images/onboarding_growth.png',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: EsgeGlowBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const BrandMark(compact: true),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _finish(context),
                    child: const Text(
                      'Passer',
                      style: TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: slides.length,
                onPageChanged: (value) => setState(() => index = value),
                itemBuilder: (_, i) => _slide(slides[i], i),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == index ? 23 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: i == index
                              ? const LinearGradient(
                                  colors: AppColors.actionGradient,
                                )
                              : null,
                          color: i == index ? null : AppColors.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  EsgeGradientButton(
                    label: index == slides.length - 1
                        ? 'Commencer'
                        : 'Continuer',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      if (index < slides.length - 1) {
                        controller.nextPage(
                          duration: const Duration(milliseconds: 330),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        _finish(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _slide((String, String, IconData, String) slide, int i) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
    child: Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: i == 1
                    ? const [
                        Color(0xFF0B382A),
                        Color(0xFF377E61),
                        Color(0xFF123E31),
                      ]
                    : const [
                        Color(0xFF0B382A),
                        Color(0xFF17694D),
                        Color(0xFF4C8D6C),
                      ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.cyan.withValues(alpha: .18)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: .15),
                  blurRadius: 28,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -60,
                  top: -60,
                  child: _orb(220, AppColors.cyan.withValues(alpha: .12)),
                ),
                Positioned(
                  left: -60,
                  bottom: -70,
                  child: _orb(210, AppColors.violet.withValues(alpha: .15)),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(29),
                    child: Image.asset(
                      illustrations[i],
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 20,
                  child: EsgeStatusChip(slide.$4, color: AppColors.green),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(29),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xC20B382A)],
                        stops: [.52, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 20,
                  child: Row(
                    children: [
                      _mini(Icons.account_balance_wallet_outlined, 'Finance'),
                      const SizedBox(width: 8),
                      _mini(Icons.inventory_2_outlined, 'Stock'),
                      const SizedBox(width: 8),
                      _mini(Icons.people_alt_outlined, 'CRM'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          slide.$1,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 29,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          slide.$2,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSoft,
            height: 1.45,
            fontSize: 12.5,
          ),
        ),
      ],
    ),
  );

  Widget _mini(IconData icon, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.cyan),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  void _finish(BuildContext context) => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
  );
}
