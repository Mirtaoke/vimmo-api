import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esge/main.dart';
import 'package:esge/business_logic/auth/auth_cubit.dart';
import 'package:esge/business_logic/dashboard/dashboard_cubit.dart';
import 'package:esge/presentation/pages/auth/login_page.dart';
import 'package:esge/presentation/pages/dashboard/home_shell.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('affiche la sélection des espaces par rôle', (tester) async {
    await tester.pumpWidget(const ESGEApp());
    expect(find.text('ESGE'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Pilotez votre entreprise\navec clarté.'), findsOneWidget);
  });

  testWidgets('la connexion ne déborde pas sur un petit écran', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back 👋'), findsOneWidget);
  });

  testWidgets(
    'la déconnexion ne reconstruit pas HomeShell avec un utilisateur nul',
    (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AuthCubit()),
            BlocProvider(create: (_) => DashboardCubit()),
          ],
          child: const MaterialApp(home: HomeShell()),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
