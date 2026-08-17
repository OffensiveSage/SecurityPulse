import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The application name displayed in the UI
  ///
  /// In en, this message translates to:
  /// **'Security Pulse'**
  String get appName;

  /// Default loading indicator message
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingDefault;

  /// Generic error title shown when an unhandled error occurs
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// Generic error message shown when an unhandled error occurs
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorGenericMessage;

  /// Error title shown when network is unavailable
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get errorNetworkTitle;

  /// Error message shown when network is unavailable
  ///
  /// In en, this message translates to:
  /// **'Check your network connection and try again.'**
  String get errorNetworkMessage;

  /// Error title shown when user lacks permission
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get errorUnauthorizedTitle;

  /// Error message shown when user lacks permission. Does not reveal why access was denied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view this content.'**
  String get errorUnauthorizedMessage;

  /// Label for retry buttons
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get buttonRetry;

  /// Sign in button label. References company account to clarify SSO is used.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your company account'**
  String get buttonSignIn;

  /// Sign out button label
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get buttonSignOut;

  /// Shown when no scenario is assigned to the employee today
  ///
  /// In en, this message translates to:
  /// **'No question today'**
  String get emptyScenarioTitle;

  /// Shown when no scenario is assigned to the employee today
  ///
  /// In en, this message translates to:
  /// **'Check back later for your next security question.'**
  String get emptyScenarioMessage;

  /// Shown when the employee has no response history
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get emptyHistoryTitle;

  /// Shown when the employee has no response history
  ///
  /// In en, this message translates to:
  /// **'Your completed questions will appear here.'**
  String get emptyHistoryMessage;

  /// REQUIRED security warning displayed in the incident report form. Must appear on every step of the wizard.
  ///
  /// In en, this message translates to:
  /// **'Never enter your password or MFA code in this form.'**
  String get incidentReportWarningCredentials;

  /// Submit button label in the scenario answer screen
  ///
  /// In en, this message translates to:
  /// **'Submit answer'**
  String get scenarioAnswerSubmit;

  /// Loading message shown while fetching the daily scenario
  ///
  /// In en, this message translates to:
  /// **'Loading today’s scenario…'**
  String get scenarioLoadingMessage;

  /// Section heading for the daily scenario question
  ///
  /// In en, this message translates to:
  /// **'Daily Security Challenge'**
  String get scenarioDailyChallenge;

  /// Label above the answer options prompting the employee to choose
  ///
  /// In en, this message translates to:
  /// **'Select your answer'**
  String get scenarioSelectPrompt;

  /// Title shown when the employee answers correctly
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get scenarioCorrectTitle;

  /// Title shown when the employee answers incorrectly
  ///
  /// In en, this message translates to:
  /// **'Not quite right'**
  String get scenarioIncorrectTitle;

  /// Heading for the explanation section in the scenario result
  ///
  /// In en, this message translates to:
  /// **'Why this matters'**
  String get scenarioExplanationHeading;

  /// Heading for the recommended action section in the scenario result
  ///
  /// In en, this message translates to:
  /// **'What you should do'**
  String get scenarioRecommendedActionHeading;

  /// Banner text shown after the employee completes the daily scenario
  ///
  /// In en, this message translates to:
  /// **'Today’s challenge completed'**
  String get scenarioCompletedBanner;

  /// Loading message shown while the answer is being submitted
  ///
  /// In en, this message translates to:
  /// **'Submitting your answer…'**
  String get scenarioSubmitting;

  /// Subtitle shown on the sign-in screen below the app name
  ///
  /// In en, this message translates to:
  /// **'Corporate cybersecurity awareness'**
  String get signInSubtitle;

  /// Accessible label for the sign-in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with your company account'**
  String get signInButtonLabel;

  /// Loading message shown during sign-in
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signInLoading;

  /// Error message shown when sign-in fails
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again.'**
  String get signInError;

  /// Privacy note shown below the sign-in button
  ///
  /// In en, this message translates to:
  /// **'By signing in you agree to your organisation’s acceptable use policy.'**
  String get signInPrivacyNote;

  /// Title of the sign-out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// Body text of the sign-out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to access Security Pulse.'**
  String get signOutConfirmMessage;

  /// Cancel button in the sign-out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get signOutCancel;

  /// Title shown when the session has expired
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get authSessionExpiredTitle;

  /// Message shown when the session has expired
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get authSessionExpired;

  /// Title for the response history screen
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyScreenTitle;

  /// Accessibility label for a correctly answered history item
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get historyItemCorrect;

  /// Accessibility label for an incorrectly answered history item
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get historyItemIncorrect;

  /// FAB label on the home screen for reporting incidents
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get incidentReportFabLabel;

  /// Title for the incident report form screen
  ///
  /// In en, this message translates to:
  /// **'Report suspicious activity'**
  String get incidentReportScreenTitle;

  /// Label for the report type dropdown
  ///
  /// In en, this message translates to:
  /// **'Type of incident'**
  String get incidentReportTypeLabel;

  /// Hint text for the report type dropdown
  ///
  /// In en, this message translates to:
  /// **'Select incident type'**
  String get incidentReportTypeHint;

  /// Label for the incident title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get incidentReportTitleLabel;

  /// Hint text for the incident title field
  ///
  /// In en, this message translates to:
  /// **'Brief summary of the incident'**
  String get incidentReportTitleHint;

  /// Label for the incident description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get incidentReportDescriptionLabel;

  /// Hint text for the incident description field
  ///
  /// In en, this message translates to:
  /// **'Describe what happened in detail'**
  String get incidentReportDescriptionHint;

  /// Label for the date/time picker
  ///
  /// In en, this message translates to:
  /// **'When did this happen?'**
  String get incidentReportOccurredAtLabel;

  /// Label for the severity selector
  ///
  /// In en, this message translates to:
  /// **'Severity (optional)'**
  String get incidentReportSeverityLabel;

  /// Label for the sender/URL field in email/link reports
  ///
  /// In en, this message translates to:
  /// **'Sender or URL'**
  String get incidentReportSenderUrlLabel;

  /// Label for the affected system field in unauthorized access reports
  ///
  /// In en, this message translates to:
  /// **'System or application affected'**
  String get incidentReportSystemAffectedLabel;

  /// Label for the device type dropdown in lost device reports
  ///
  /// In en, this message translates to:
  /// **'Device type'**
  String get incidentReportDeviceTypeLabel;

  /// Label for the last known location field in lost device reports
  ///
  /// In en, this message translates to:
  /// **'Last known location'**
  String get incidentReportLastLocationLabel;

  /// Label for the data classification dropdown in data exposure reports
  ///
  /// In en, this message translates to:
  /// **'Data classification'**
  String get incidentReportDataClassificationLabel;

  /// Label for the attachment button
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get incidentReportAttachmentLabel;

  /// Tooltip for the disabled attachment button
  ///
  /// In en, this message translates to:
  /// **'Attachments coming soon'**
  String get incidentReportAttachmentComingSoon;

  /// Label for the submit button
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get incidentReportSubmitButton;

  /// Loading message during report submission
  ///
  /// In en, this message translates to:
  /// **'Submitting report…'**
  String get incidentReportSubmitting;

  /// Urgent guidance banner shown for critical incidents
  ///
  /// In en, this message translates to:
  /// **'For urgent incidents, also contact the Security Operations Center at {phoneNumber}.'**
  String incidentReportUrgentGuidance(String phoneNumber);

  /// Title on the receipt screen after successful submission
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get incidentReceiptTitle;

  /// Shows the report ID on the receipt screen
  ///
  /// In en, this message translates to:
  /// **'Report ID: {reportId}'**
  String incidentReceiptReportId(String reportId);

  /// Done button on the receipt screen that returns to dashboard
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get incidentReceiptDoneButton;

  /// Button on receipt screen to navigate to report history
  ///
  /// In en, this message translates to:
  /// **'View my reports'**
  String get incidentReceiptViewReportsButton;

  /// Title for the incident report history screen
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get incidentHistoryScreenTitle;

  /// Empty state title when no reports exist
  ///
  /// In en, this message translates to:
  /// **'No reports'**
  String get incidentHistoryEmptyTitle;

  /// Empty state message when no reports exist
  ///
  /// In en, this message translates to:
  /// **'Your submitted incident reports will appear here.'**
  String get incidentHistoryEmptyMessage;

  /// Title for the incident report detail screen
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get incidentDetailScreenTitle;

  /// Validation error for required fields
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get incidentReportValidationRequired;

  /// Validation error for title length
  ///
  /// In en, this message translates to:
  /// **'Title must be 5–100 characters'**
  String get incidentReportValidationTitleLength;

  /// Validation error for description length
  ///
  /// In en, this message translates to:
  /// **'Description must be 10–2000 characters'**
  String get incidentReportValidationDescriptionLength;

  /// Validation error for future date
  ///
  /// In en, this message translates to:
  /// **'Date cannot be in the future'**
  String get incidentReportValidationFutureDate;

  /// Display label for submitted status
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get incidentStatusSubmitted;

  /// Display label for acknowledged status
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get incidentStatusAcknowledged;

  /// Display label for investigating status
  ///
  /// In en, this message translates to:
  /// **'Investigating'**
  String get incidentStatusInvestigating;

  /// Display label for resolved status
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get incidentStatusResolved;

  /// Display label for closed status
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get incidentStatusClosed;

  /// Display label for low severity
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get incidentSeverityLow;

  /// Display label for medium severity
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get incidentSeverityMedium;

  /// Display label for high severity
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get incidentSeverityHigh;

  /// Display label for critical severity
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get incidentSeverityCritical;

  /// Title for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// Label for the notification preference toggle
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsNotificationToggleLabel;

  /// Description for the notification preference toggle
  ///
  /// In en, this message translates to:
  /// **'Get a daily notification when your security challenge is ready'**
  String get settingsNotificationToggleDescription;

  /// Message shown when notification permission is denied
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required. Enable it in device settings.'**
  String get settingsNotificationPermissionDenied;

  /// Title for the daily reminder notification. Static and non-sensitive.
  ///
  /// In en, this message translates to:
  /// **'Security Pulse'**
  String get notificationTitle;

  /// Body for the daily reminder notification. Static and non-sensitive.
  ///
  /// In en, this message translates to:
  /// **'Your daily security challenge is ready'**
  String get notificationBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
