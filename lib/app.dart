import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/shell/app_shell.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';

class CheckScanApp extends StatelessWidget {
  const CheckScanApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('ru'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          if (!state.ready) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!state.onboardingDone) {
            return OnboardingPage(state: state);
          }
          return AppShell(state: state);
        },
      ),
    );
  }
}
