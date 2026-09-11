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
    appBar: AppBar(title: const Text('Informations personnelles')),
    body: EsgeGlowBackground(
      child: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              const EsgeGlassCard(
                child: Row(
                  children: [
                    EsgeIconBadge(
                      icon: Icons.badge_outlined,
                      color: AppColors.indigo,
                      size: 46,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Gardez vos coordonnées professionnelles à jour pour sécuriser vos échanges.',
                        style: TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 8),
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
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
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
