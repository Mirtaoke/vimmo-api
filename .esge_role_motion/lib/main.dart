import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'business_logic/attendance/attendance_cubit.dart';
import 'business_logic/auth/auth_cubit.dart';
import 'business_logic/cash/cash_cubit.dart';
import 'business_logic/crm/crm_cubit.dart';
import 'business_logic/dashboard/dashboard_cubit.dart';
import 'business_logic/disbursements/disbursement_cubit.dart';
import 'business_logic/inventory/inventory_cubit.dart';
import 'business_logic/notifications/notification_cubit.dart';
import 'business_logic/providers/provider_cubit.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/esge_repository.dart';
import 'presentation/pages/auth/splash_page.dart';

void main() => runApp(const ESGEApp());

class ESGEApp extends StatelessWidget {
  const ESGEApp({super.key});
  @override
  Widget build(BuildContext context) {
    final repository = EsgeRepository();
    return MultiRepositoryProvider(
      providers: [RepositoryProvider.value(value: repository)],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit()),
          BlocProvider(create: (_) => DashboardCubit()),
          BlocProvider(create: (_) => DisbursementCubit(repository)),
          BlocProvider(create: (_) => ProviderCubit(repository)),
          BlocProvider(create: (_) => InventoryCubit(repository)),
          BlocProvider(create: (_) => CrmCubit(repository)),
          BlocProvider(create: (_) => CashCubit()),
          BlocProvider(create: (_) => AttendanceCubit()),
          BlocProvider(create: (_) => NotificationCubit()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ESGE',
          theme: AppTheme.light,
          home: const SplashPage(),
        ),
      ),
    );
  }
}
