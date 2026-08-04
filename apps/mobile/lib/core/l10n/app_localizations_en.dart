// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Security Pulse';

  @override
  String get loadingDefault => 'Loading…';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericMessage =>
      'An unexpected error occurred. Please try again.';

  @override
  String get errorNetworkTitle => 'No connection';

  @override
  String get errorNetworkMessage =>
      'Check your network connection and try again.';

  @override
  String get errorUnauthorizedTitle => 'Access denied';

  @override
  String get errorUnauthorizedMessage =>
      'You do not have permission to view this content.';

  @override
  String get buttonRetry => 'Try again';

  @override
  String get buttonSignIn => 'Sign in with your company account';

  @override
  String get buttonSignOut => 'Sign out';

  @override
  String get emptyScenarioTitle => 'No question today';

  @override
  String get emptyScenarioMessage =>
      'Check back later for your next security question.';

  @override
  String get emptyHistoryTitle => 'No activity yet';

  @override
  String get emptyHistoryMessage =>
      'Your completed questions will appear here.';

  @override
  String get incidentReportWarningCredentials =>
      'Never enter your password or MFA code in this form.';

  @override
  String get scenarioAnswerSubmit => 'Submit answer';
}
