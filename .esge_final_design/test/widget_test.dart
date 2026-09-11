import 'package:flutter_test/flutter_test.dart';
import 'package:esge/main.dart';
import 'package:esge/presentation/pages/auth/login_page.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('affiche la sélection des espaces par rôle', (tester) async {
    await tester.pumpWidget(const ESGEApp());
    expect(find.text('ESGE'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text('Une seule vision.\nToute votre entreprise.'),
      findsOneWidget,
    );
  });

  testWidgets('la connexion ne déborde pas sur un petit écran', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(tester.takeException(), isNull);
    expect(find.text('Bon retour 👋'), findsOneWidget);
  });
}
