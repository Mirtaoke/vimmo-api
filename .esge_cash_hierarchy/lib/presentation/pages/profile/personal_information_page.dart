import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
  late final TextEditingController phoneController;
  final imagePicker = ImagePicker();
  XFile? selectedPhoto;
  bool removeExistingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.user!;
    nameController = TextEditingController(text: user.fullName);
    emailController = TextEditingController(text: user.email);
    phoneController = TextEditingController(text: user.phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
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
                    InkWell(
                      onTap: _showPhotoActions,
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _profilePhoto(),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 11,
                              ),
                            ),
                          ),
                        ],
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
              Row(
                children: [
                  const Text(
                    'PHOTO DE PROFIL',
                    style: TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showPhotoActions,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 15),
                    label: const Text(
                      'Ajouter ou modifier',
                      style: TextStyle(fontSize: 9.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Enregistrer les modifications'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _profilePhoto() {
    final currentPath = context.read<AuthCubit>().state.user?.photoUrl;
    final path =
        selectedPhoto?.path ?? (removeExistingPhoto ? null : currentPath);
    return Container(
      width: 58,
      height: 58,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: path == null
          ? const Icon(Icons.person_rounded, color: Colors.white, size: 27)
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
    );
  }

  void _showPhotoActions() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        6,
        18,
        20 + MediaQueryData.fromView(View.of(context)).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photo de profil',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choisissez la source de votre nouvelle photo.',
            style: TextStyle(color: AppColors.textSoft, fontSize: 10),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _photoAction(
                  Icons.photo_library_outlined,
                  'Galerie',
                  AppColors.indigo,
                  () => _pickPhoto(sheetContext, ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _photoAction(
                  Icons.photo_camera_outlined,
                  'Caméra',
                  AppColors.orange,
                  () => _pickPhoto(sheetContext, ImageSource.camera),
                ),
              ),
            ],
          ),
          if (selectedPhoto != null ||
              context.read<AuthCubit>().state.user?.photoUrl != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                setState(() {
                  selectedPhoto = null;
                  removeExistingPhoto = true;
                });
              },
              icon: const Icon(Icons.delete_outline, color: AppColors.red),
              label: const Text(
                'Supprimer la photo',
                style: TextStyle(color: AppColors.red, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _photoAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) => Material(
    color: color.withValues(alpha: .10),
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 7),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _pickPhoto(BuildContext sheetContext, ImageSource source) async {
    Navigator.pop(sheetContext);
    final photo = await imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (!mounted || photo == null) return;
    setState(() {
      selectedPhoto = photo;
      removeExistingPhoto = false;
    });
  }

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
      phone: phoneController.text.trim(),
      photoUrl: selectedPhoto?.path,
      removePhoto: removeExistingPhoto,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informations enregistrées avec succès.')),
    );
  }
}
