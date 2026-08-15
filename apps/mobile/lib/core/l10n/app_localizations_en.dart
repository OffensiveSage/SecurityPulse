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

  @override
  String get scenarioLoadingMessage => 'Loading today’s scenario…';

  @override
  String get scenarioDailyChallenge => 'Daily Security Challenge';

  @override
  String get scenarioSelectPrompt => 'Select your answer';

  @override
  String get scenarioCorrectTitle => 'Correct!';

  @override
  String get scenarioIncorrectTitle => 'Not quite right';

  @override
  String get scenarioExplanationHeading => 'Why this matters';

  @override
  String get scenarioRecommendedActionHeading => 'What you should do';

  @override
  String get scenarioCompletedBanner => 'Today’s challenge completed';

  @override
  String get scenarioSubmitting => 'Submitting your answer…';

  @override
  String get signInSubtitle => 'Corporate cybersecurity awareness';

  @override
  String get signInButtonLabel => 'Sign in with your company account';

  @override
  String get signInLoading => 'Signing in…';

  @override
  String get signInError => 'Sign in failed. Please try again.';

  @override
  String get signInPrivacyNote =>
      'By signing in you agree to your organisation’s acceptable use policy.';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmMessage =>
      'You will need to sign in again to access Security Pulse.';

  @override
  String get signOutCancel => 'Cancel';

  @override
  String get authSessionExpiredTitle => 'Session expired';

  @override
  String get authSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get historyScreenTitle => 'History';

  @override
  String get historyItemCorrect => 'Correct';

  @override
  String get historyItemIncorrect => 'Incorrect';
}
