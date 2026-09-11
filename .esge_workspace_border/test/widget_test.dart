import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esge/main.dart';
import 'package:esge/business_logic/auth/auth_cubit.dart';
import 'package:esge/business_logic/dashboard/dashboard_cubit.dart';
import 'package:esge/presentation/pages/auth/login_page.dart';
import 'package:esge/presentation/pages/dashboard/home_shell.dart';
import 'package:esge/presentation/pages/dashboard/quick_access_page.dart';
import 'package:esge/presentation/pages/auth/role_selection_page.dart';
import 'package:esge/presentation/pages/dashboard/role_dashboard_page.dart';
import 'package:esge/data/models/user_model.dart';
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
    expect(find.text('Heureux de vous revoir 👋'), findsOneWidget);
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

  testWidgets('les accès rapides ouvrent des listes filtrables', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: QuickAccessPage(type: QuickAccessType.vouchers)),
    );
    expect(find.text('Bons récents'), findsOneWidget);
    expect(find.text('Achat fournitures bureau'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'internet');
    await tester.pump();
    expect(find.text('Abonnement internet'), findsOneWidget);
    expect(find.text('Achat fournitures bureau'), findsNothing);
  });

  testWidgets('les cartes de recherche ouvrent leur destination sans erreur', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GlobalSearchPage()));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Bons récents'));
    await tester.pumpAndSettle();
    expect(find.text('Achat fournitures bureau'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le sélecteur premium des rôles reste lisible sur petit écran', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthCubit(),
        child: const MaterialApp(home: RoleSelectionPage()),
      ),
    );
    expect(find.text('Quel est votre rôle ?'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la priorité du tableau de bord ouvre sa fiche', (tester) async {
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpWidget(
      const MaterialApp(home: RoleDashboardPage(role: UserRole.dg)),
    );
    final priority = find.text('PRIORITÉ');
    await tester.scrollUntilVisible(priority, 250);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    await tester.pump();
    await tester.tap(priority);
    await tester.pumpAndSettle();
    expect(find.text('Action prioritaire'), findsOneWidget);
    final actionButton = find.text('Prendre en charge');
    expect(actionButton, findsOneWidget);
    expect(tester.getBottomRight(actionButton).dy, lessThan(600 - 34));
    expect(tester.takeException(), isNull);
  });
}
