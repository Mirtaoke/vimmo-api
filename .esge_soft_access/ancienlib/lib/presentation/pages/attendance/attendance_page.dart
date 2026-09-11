import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/attendance/attendance_cubit.dart';
import '../../../business_logic/attendance/attendance_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/feature_scaffold.dart';
import '../../widgets/analytics_widgets.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AttendanceCubit, AttendanceState>(
        builder: (_, state) => FeatureScaffold(
          title: 'Présence & pointage',
          subtitle: 'Contrôle du site, du Wi-Fi et de la géolocalisation',
          icon: Icons.fingerprint,
          color: AppColors.coral,
          actions: const [
            'Mon pointage',
            'Présents',
            'Absents',
            'Retards',
            'Historique',
            'Paramétrage',
          ],
          children: [
            const KpiStrip(
              items: [
                ('Présents', '38', Icons.badge, AppColors.lime),
                ('Retards', '3', Icons.schedule, AppColors.gold),
                ('Absents', '4', Icons.person_off, AppColors.coral),
              ],
            ),
            const SizedBox(height: 18),
            _check('Zone GPS autorisée', state.isGpsVerified),
            _check('Réseau Wi-Fi conforme', state.isWifiVerified),
            _check('Pointage enregistré', state.isCheckedIn),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: state.isGpsVerified
                  ? context.read<AttendanceCubit>().checkIn
                  : context.read<AttendanceCubit>().verifyLocation,
              icon: const Icon(Icons.location_searching),
              label: Text(
                state.isGpsVerified
                    ? 'Pointer maintenant'
                    : 'Vérifier ma position',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: AppColors.coral,
              ),
            ),
          ],
        ),
      );
  Widget _check(String label, bool ok) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: AppColors.workspaceLight,
      borderRadius: BorderRadius.circular(20),
    ),
    child: ListTile(
      leading: Icon(
        ok ? Icons.check_circle : Icons.radio_button_unchecked,
        color: ok ? AppColors.success : AppColors.muted,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: Text(
        ok ? 'Conforme' : 'À vérifier',
        style: const TextStyle(color: Colors.white54),
      ),
    ),
  );
}
