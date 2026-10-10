import 'package:flutter_test/flutter_test.dart';
import 'package:irfandevs77/app.dart';
import 'package:flutter/material.dart';
import 'package:irfandevs77/services/firebase_service.dart';
import 'package:irfandevs77/theme/portfolio_theme.dart';
import 'package:irfandevs77/widgets/portfolio_frame.dart';
import 'package:irfandevs77/widgets/portfolio_search.dart';

void main() {
  test('admin access requires the boolean admin custom claim', () {
    expect(FirebaseService.hasAdminRoleClaim({'admin': true}), isTrue);
    expect(FirebaseService.hasAdminRoleClaim({'admin': 'true'}), isFalse);
    expect(FirebaseService.hasAdminRoleClaim({'role': 'admin'}), isFalse);
    expect(FirebaseService.hasAdminRoleClaim({}), isFalse);
  });

  testWidgets('shows Firebase connection details on the setup screen', (
    tester,
  ) async {
    await tester.pumpWidget(const IrfanDevs77App(firebaseConfigured: false));

    expect(find.text('Connect your Firebase project'), findsOneWidget);
    expect(find.textContaining('irfandevs77-d9520'), findsOneWidget);
  });

  testWidgets('mobile navigation groups social destinations together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: PortfolioTheme.light,
        home: const Scaffold(body: PortfolioNavigation(activeRoute: '/')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Search the whole site'), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    expect(find.text('Social'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('About'), findsNothing);
    expect(find.text('GitHub'), findsNothing);
    expect(find.text('Instagram'), findsNothing);
    expect(find.text('Contact'), findsNothing);
  });

  testWidgets(
    'compact mobile navigation keeps search visible without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: PortfolioTheme.light,
          home: const Scaffold(body: PortfolioNavigation(activeRoute: '/')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Search the whole site'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('contact screen shows validated contact workflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const IrfanDevs77App(firebaseConfigured: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Social').last);
    await tester.pumpAndSettle();

    expect(find.text('Send a message'), findsOneWidget);
    expect(find.text('Your email'), findsOneWidget);
    expect(find.text('Your message'), findsOneWidget);
    await tester.ensureVisible(find.text('Send message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send message'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Enter a valid email.'), findsOneWidget);
    expect(find.text('Please write at least 10 characters.'), findsOneWidget);
  });

  testWidgets('mobile login offers regular account creation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const IrfanDevs77App(firebaseConfigured: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('desktop navigation exposes one Social tab and account login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: PortfolioTheme.light,
        home: const Scaffold(body: PortfolioNavigation(activeRoute: '/')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    expect(find.text('About'), findsNothing);
    expect(find.text('GitHub'), findsNothing);
    expect(find.text('Instagram'), findsNothing);
    expect(find.text('Contact'), findsNothing);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byTooltip('Search the whole site'), findsOneWidget);
  });

  testWidgets('site search finds Synora releases and opens the result', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PortfolioTheme.light,
        home: const Scaffold(body: Center(child: PortfolioSearchButton())),
        routes: {
          '/synora': (_) =>
              const Scaffold(body: Center(child: Text('Synora release page'))),
        },
      ),
    );

    await tester.tap(find.byTooltip('Search the whole site'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Synora APK');
    await tester.pumpAndSettle();

    expect(find.text('Synora APK releases'), findsOneWidget);
    await tester.tap(find.text('Synora APK releases'));
    await tester.pumpAndSettle();
    expect(find.text('Synora release page'), findsOneWidget);
  });
}
