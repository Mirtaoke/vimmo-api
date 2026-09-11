import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/auth/auth_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/esge_ui.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController departmentController;
  final phoneController = TextEditingController(text: '+229 01 97 00 00 00');

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.user!;
    nameController = TextEditingController(text: user.fullName);
    emailController = TextEditingController(text: user.email);
    departmentController = TextEditingController(text: user.department);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    departmentController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 56,
      title: const Text(
        'Informations personnelles',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
    ),
    body: EsgeGlowBackground(
      child: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF182B55), Color(0xFF5968B0)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo.withValues(alpha: .22),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mon identité professionnelle',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coordonnées utilisées dans ESGE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .72),
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const EsgeStatusChip('Vérifié', color: Color(0xFFA8F0C5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'COORDONNÉES',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140B281E),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _field(nameController, 'Nom complet', Icons.person_outline),
                    _field(
                      emailController,
                      'Adresse e-mail',
                      Icons.alternate_email_rounded,
                      email: true,
                    ),
                    _field(phoneController, 'Téléphone', Icons.phone_outlined),
                    _field(
                      departmentController,
                      'Département',
                      Icons.apartment_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              EsgeGradientButton(
                label: 'Enregistrer les modifications',
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool email = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: const TextStyle(fontSize: 10.5),
        prefixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Champ obligatoire';
        if (email && !value.contains('@')) return 'Adresse e-mail invalide';
        return null;
      },
    ),
  );

  void _save() {
    if (!formKey.currentState!.validate()) return;
    context.read<AuthCubit>().updateProfile(
      fullName: nameController.text.trim(),
      email: emailController.text.trim(),
      department: departmentController.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informations enregistrées avec succès.')),
    );
  }
}
