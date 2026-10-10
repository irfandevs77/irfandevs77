import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/account_login_page.dart';
import 'screens/admin_dashboard_page.dart';
import 'screens/admin_login_page.dart';
import 'screens/firebase_setup_page.dart';
import 'screens/contact_page.dart';
import 'screens/home_page.dart';
import 'screens/projects_page.dart';
import 'screens/skills_page.dart';
import 'screens/synora_details_page.dart';
import 'theme/app_theme.dart';

class IrfanDevs77App extends StatelessWidget {
  const IrfanDevs77App({
    super.key,
    required this.firebaseConfigured,
    this.configurationError,
  });

  final bool firebaseConfigured;
  final String? configurationError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'irfandevs77',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorObservers: firebaseConfigured && Firebase.apps.isNotEmpty
          ? [PortfolioAnalyticsObserver()]
          : const [],
      initialRoute: '/',
      routes: {
        '/': (_) => firebaseConfigured
            ? const HomePage()
            : FirebaseSetupPage(error: configurationError),
        '/about': (_) => firebaseConfigured
            ? const HomePage()
            : FirebaseSetupPage(error: configurationError),
        '/skills': (_) => firebaseConfigured
            ? const SkillsPage()
            : FirebaseSetupPage(error: configurationError),
        '/projects': (_) => firebaseConfigured
            ? const ProjectsPage()
            : FirebaseSetupPage(error: configurationError),
        '/synora': (context) {
          if (!firebaseConfigured) {
            return FirebaseSetupPage(error: configurationError);
          }
          final sourceUrl = ModalRoute.of(context)?.settings.arguments;
          return SynoraDetailsPage(
            githubUrl: sourceUrl is String && sourceUrl.isNotEmpty
                ? sourceUrl
                : 'https://github.com/irfandevs77',
          );
        },
        '/social': (_) => firebaseConfigured
            ? const ContactPage()
            : FirebaseSetupPage(error: configurationError),
        '/github': (_) => firebaseConfigured
            ? const ContactPage()
            : FirebaseSetupPage(error: configurationError),
        '/instagram': (_) => firebaseConfigured
            ? const ContactPage()
            : FirebaseSetupPage(error: configurationError),
        '/contact': (_) => firebaseConfigured
            ? const ContactPage()
            : FirebaseSetupPage(error: configurationError),
        '/login': (_) => firebaseConfigured
            ? const AccountLoginPage()
            : FirebaseSetupPage(error: configurationError),
        '/overview': (_) => firebaseConfigured
            ? const HomePage()
            : FirebaseSetupPage(error: configurationError),
        '/repositories': (_) => firebaseConfigured
            ? const ContactPage()
            : FirebaseSetupPage(error: configurationError),
        '/packages': (_) => firebaseConfigured
            ? const ProjectsPage()
            : FirebaseSetupPage(error: configurationError),
        '/stars': (_) => firebaseConfigured
            ? const ContactPage()
            : FirebaseSetupPage(error: configurationError),
        '/admin/login': (_) => firebaseConfigured
            ? const AdminLoginPage()
            : FirebaseSetupPage(error: configurationError),
        '/admin': (_) => firebaseConfigured
            ? const AdminDashboardPage()
            : FirebaseSetupPage(error: configurationError),
      },
    );
  }
}

class PortfolioAnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _recordScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _recordScreenView(newRoute);
  }

  void _recordScreenView(Route<dynamic> route) {
    final screenName = route.settings.name;
    if (screenName == null || Firebase.apps.isEmpty) return;
    FirebaseAnalytics.instance.logScreenView(screenName: screenName).catchError(
      (Object error) {
        debugPrint('Could not record analytics screen view: $error');
      },
    );
  }
}
