import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esge/main.dart';
import 'package:esge/business_logic/auth/auth_cubit.dart';
import 'package:esge/business_logic/dashboard/dashboard_cubit.dart';
import 'package:esge/business_logic/cash/cash_cubit.dart';
import 'package:esge/business_logic/disbursements/disbursement_cubit.dart';
import 'package:esge/core/theme/app_colors.dart';
import 'package:esge/presentation/pages/auth/login_page.dart';
import 'package:esge/presentation/pages/dashboard/home_shell.dart';
import 'package:esge/presentation/pages/dashboard/quick_access_page.dart';
import 'package:esge/presentation/pages/auth/role_selection_page.dart';
import 'package:esge/presentation/pages/dashboard/role_dashboard_page.dart';
import 'package:esge/presentation/pages/profile/profile_page.dart';
import 'package:esge/presentation/pages/cash/cash_page.dart';
import 'package:esge/presentation/pages/notifications/notifications_page.dart';
import 'package:esge/presentation/widgets/feature_scaffold.dart';
import 'package:esge/presentation/widgets/esge_ui.dart';
import 'package:esge/data/models/user_model.dart';
import 'package:esge/data/repositories/esge_repository.dart';
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
    final authCubit = AuthCubit()..signInAs(UserRole.caissier);
    await tester.pumpWidget(
      BlocProvider.value(
        value: authCubit,
        child: const MaterialApp(
          home: QuickAccessPage(type: QuickAccessType.vouchers),
        ),
      ),
    );
    expect(find.text('Bons récents'), findsOneWidget);
    expect(find.text('Achat fournitures bureau'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'internet');
    await tester.pump();
    expect(find.text('Abonnement internet'), findsOneWidget);
    expect(find.text('Achat fournitures bureau'), findsNothing);
    await authCubit.close();
  });

  testWidgets('les cartes de recherche ouvrent leur destination sans erreur', (
    tester,
  ) async {
    final authCubit = AuthCubit()..signInAs(UserRole.dg);
    await tester.pumpWidget(
      BlocProvider.value(
        value: authCubit,
        child: const MaterialApp(home: GlobalSearchPage()),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Stock'));
    await tester.pump();
    expect(find.text('Articles'), findsOneWidget);
    expect(find.text('Bons récents'), findsNothing);
    await tester.tap(find.text('Tout'));
    await tester.pump();
    await tester.tap(find.text('Bons récents'));
    await tester.pumpAndSettle();
    expect(find.text('Achat fournitures bureau'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await authCubit.close();
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
    expect(find.text('Choisissez votre espace'), findsOneWidget);
    expect(find.text('ESPACES MÉTIER'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Administrateur'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le rôle choisi est conservé jusqu’au tableau de bord', (
    tester,
  ) async {
    final authCubit = AuthCubit();
    final dashboardCubit = DashboardCubit();
    addTearDown(authCubit.close);
    addTearDown(dashboardCubit.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authCubit),
          BlocProvider.value(value: dashboardCubit),
        ],
        child: const MaterialApp(home: RoleSelectionPage()),
      ),
    );
    final continueButton = find.byType(EsgeGradientButton);
    await tester.scrollUntilVisible(
      continueButton,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -90));
    await tester.pumpAndSettle();
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    expect(find.text('Espace Directeur général'), findsOneWidget);
    final loginButton = find.byType(EsgeGradientButton);
    await tester.scrollUntilVisible(
      loginButton,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    expect(authCubit.state.user?.role, UserRole.dg);
    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets('la priorité du tableau de bord ouvre sa fiche', (tester) async {
    addTearDown(tester.view.resetViewPadding);
    final authCubit = AuthCubit()..signInAs(UserRole.dg);
    final disbursementCubit = DisbursementCubit(EsgeRepository());
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authCubit),
          BlocProvider.value(value: disbursementCubit),
        ],
        child: const MaterialApp(home: RoleDashboardPage(role: UserRole.dg)),
      ),
    );
    final priority = find.text('PRIORITÉ');
    await tester.scrollUntilVisible(
      priority,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    await tester.pump();
    await tester.tap(priority);
    await tester.pumpAndSettle();
    expect(find.text('Demandes & validations'), findsWidgets);
    expect(tester.takeException(), isNull);
    await authCubit.close();
    await disbursementCubit.close();
  });

  testWidgets('les réglages du profil ouvrent leurs pages', (tester) async {
    final authCubit = AuthCubit()..signInAs(UserRole.comptable);
    await tester.pumpWidget(
      BlocProvider.value(
        value: authCubit,
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    expect(find.text('Compte'), findsOneWidget);
    expect(find.text('Comptable'), findsOneWidget);
    expect(find.text('Fonction'), findsNothing);
    expect(find.text('Service'), findsNothing);
    expect(find.text('Permissions'), findsNothing);
    expect(find.text('Historique de connexion'), findsNothing);
    expect(find.text('Administrateur'), findsNothing);
    expect(find.text('Langue'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Informations personnelles'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Informations personnelles'));
    await tester.pumpAndSettle();
    expect(find.text('Enregistrer les modifications'), findsOneWidget);
    await tester.tap(find.text('Ajouter ou modifier'));
    await tester.pumpAndSettle();
    expect(find.text('Galerie'), findsOneWidget);
    expect(find.text('Caméra'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Changer le mot de passe'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Changer le mot de passe'));
    await tester.pumpAndSettle();
    expect(find.text('Mettre à jour le mot de passe'), findsOneWidget);
    await authCubit.close();
  });

  testWidgets('un espace commercial reste limité à son périmètre', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoleDashboardPage(role: UserRole.commercial)),
    );
    await tester.scrollUntilVisible(
      find.text('3 accès'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('3 accès'), findsOneWidget);
  });

  testWidgets('les mouvements récents se filtrent par module', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoleDashboardPage(role: UserRole.commercial)),
    );
    await tester.scrollUntilVisible(
      find.text('Mouvements récents'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Pointage').last);
    await tester.pump();
    expect(find.text('Pointage d’arrivée'), findsOneWidget);
    expect(find.text('Nova Conseil'), findsNothing);
  });

  testWidgets('les actions filtrent une liste paginée sous la recherche', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FeatureScaffold(
          title: 'Caisse',
          subtitle: 'Test des données',
          icon: Icons.wallet_outlined,
          color: AppColors.orange,
          actions: ['Entrées', 'Sorties'],
          showHero: false,
          leadingChildren: [Text('SOLDE DISPONIBLE')],
          children: [SizedBox()],
        ),
      ),
    );
    expect(find.byKey(const ValueKey('action-0-active')), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('SOLDE DISPONIBLE')).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('action-0-active'))).dy,
      ),
    );
    await tester.tap(find.text('Sorties'));
    await tester.pump();
    expect(find.byKey(const ValueKey('action-1-active')), findsOneWidget);
    final sortiesIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('action-1-active')),
        matching: find.byIcon(Icons.north_east_rounded),
      ),
    );
    expect(sortiesIcon.color, AppColors.coral);
    expect(find.text('Afficher les éléments'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Mission commerciale 01'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mission commerciale 01'), findsOneWidget);
    final secondPage = find.byKey(const ValueKey('page-2'));
    await tester.ensureVisible(secondPage);
    await tester.pumpAndSettle();
    await tester.tap(secondPage);
    await tester.pump();
    expect(find.text('Frais de fonctionnement 11'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seul le caissier peut créer un bon de caisse', (tester) async {
    final cashCubit = CashCubit();
    await tester.pumpWidget(
      BlocProvider.value(
        value: cashCubit,
        child: const MaterialApp(home: CashPage(canCreateCashVoucher: false)),
      ),
    );
    expect(find.text('Nouveau bon de caisse'), findsNothing);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cashCubit,
        child: const MaterialApp(home: CashPage(canCreateCashVoucher: true)),
      ),
    );
    await tester.pump();
    expect(find.text('Nouveau bon de caisse'), findsOneWidget);
    await cashCubit.close();
  });

  testWidgets('une entrée de stock ouvre tous ses détails', (tester) async {
    final authCubit = AuthCubit()..signInAs(UserRole.magasinier);
    await tester.pumpWidget(
      BlocProvider.value(
        value: authCubit,
        child: const MaterialApp(
          home: FeatureScaffold(
            title: 'Stock & logistique',
            subtitle: 'Test',
            icon: Icons.inventory_2,
            color: AppColors.orange,
            actions: ['Entrées', 'Sorties'],
            children: [],
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Papier A4 Premium 01'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Papier A4 Premium 01'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Justificatif'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Fournisseur'), findsOneWidget);
    expect(find.text('Bon / facture'), findsOneWidget);
    expect(find.text('Prix unitaire'), findsOneWidget);
    expect(find.text('Justificatif'), findsOneWidget);
    expect(find.text('Commentaire'), findsOneWidget);
    await authCubit.close();
  });

  testWidgets('le DG peut décider depuis le détail d’une validation', (
    tester,
  ) async {
    final authCubit = AuthCubit()..signInAs(UserRole.dg);
    await tester.pumpWidget(
      BlocProvider.value(
        value: authCubit,
        child: const MaterialApp(
          home: FeatureScaffold(
            title: 'Demandes & validations',
            subtitle: 'Test',
            icon: Icons.verified_user,
            color: AppColors.indigo,
            actions: ['Demandes'],
            children: [],
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Demandes — dossier 01'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Demandes — dossier 01'));
    await tester.pumpAndSettle();
    expect(find.text('Approuver'), findsOneWidget);
    expect(find.text('Refuser'), findsOneWidget);
    expect(find.text('Retourner'), findsNothing);
    await authCubit.close();
  });

  testWidgets('ouvrir une notification la marque comme lue', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));
    expect(find.text('3 non lues'), findsOneWidget);
    await tester.tap(find.text('Demande à valider'));
    await tester.pump();
    expect(find.text('2 non lues'), findsOneWidget);
  });
}
