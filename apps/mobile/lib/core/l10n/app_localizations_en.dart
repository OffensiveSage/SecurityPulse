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
  String get errorUnauthenticatedTitle => 'Sign in required';

  @override
  String get errorUnauthenticatedMessage => 'Please sign in to continue.';

  @override
  String get errorNotFoundTitle => 'Not found';

  @override
  String get errorNotFoundMessage =>
      'The requested resource could not be found.';

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

  @override
  String get incidentReportFabLabel => 'Report';

  @override
  String get incidentReportScreenTitle => 'Report suspicious activity';

  @override
  String get incidentReportTypeLabel => 'Type of incident';

  @override
  String get incidentReportTypeHint => 'Select incident type';

  @override
  String get incidentReportTitleLabel => 'Title';

  @override
  String get incidentReportTitleHint => 'Brief summary of the incident';

  @override
  String get incidentReportDescriptionLabel => 'Description';

  @override
  String get incidentReportDescriptionHint =>
      'Describe what happened in detail';

  @override
  String get incidentReportOccurredAtLabel => 'When did this happen?';

  @override
  String get incidentReportSeverityLabel => 'Severity (optional)';

  @override
  String get incidentReportSenderUrlLabel => 'Sender or URL';

  @override
  String get incidentReportSystemAffectedLabel =>
      'System or application affected';

  @override
  String get incidentReportDeviceTypeLabel => 'Device type';

  @override
  String get incidentReportLastLocationLabel => 'Last known location';

  @override
  String get incidentReportDataClassificationLabel => 'Data classification';

  @override
  String get incidentReportAttachmentLabel => 'Add attachment';

  @override
  String get incidentReportAttachmentComingSoon => 'Attachments coming soon';

  @override
  String get incidentReportSubmitButton => 'Submit report';

  @override
  String get incidentReportSubmitting => 'Submitting report…';

  @override
  String incidentReportUrgentGuidance(String phoneNumber) {
    return 'For urgent incidents, also contact the Security Operations Center at $phoneNumber.';
  }

  @override
  String get incidentReceiptTitle => 'Report submitted';

  @override
  String incidentReceiptReportId(String reportId) {
    return 'Report ID: $reportId';
  }

  @override
  String get incidentReceiptDoneButton => 'Done';

  @override
  String get incidentReceiptViewReportsButton => 'View my reports';

  @override
  String get incidentHistoryScreenTitle => 'My reports';

  @override
  String get incidentHistoryEmptyTitle => 'No reports';

  @override
  String get incidentHistoryEmptyMessage =>
      'Your submitted incident reports will appear here.';

  @override
  String get incidentDetailScreenTitle => 'Report details';

  @override
  String get incidentReportValidationRequired => 'This field is required';

  @override
  String get incidentReportValidationTitleLength =>
      'Title must be 5–100 characters';

  @override
  String get incidentReportValidationDescriptionLength =>
      'Description must be 10–2000 characters';

  @override
  String get incidentReportValidationFutureDate =>
      'Date cannot be in the future';

  @override
  String get incidentStatusSubmitted => 'Submitted';

  @override
  String get incidentStatusAcknowledged => 'Acknowledged';

  @override
  String get incidentStatusInvestigating => 'Investigating';

  @override
  String get incidentStatusResolved => 'Resolved';

  @override
  String get incidentStatusClosed => 'Closed';

  @override
  String get incidentSeverityLow => 'Low';

  @override
  String get incidentSeverityMedium => 'Medium';

  @override
  String get incidentSeverityHigh => 'High';

  @override
  String get incidentSeverityCritical => 'Critical';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsNotificationToggleLabel => 'Daily reminder';

  @override
  String get settingsNotificationToggleDescription =>
      'Get a daily notification when your security challenge is ready';

  @override
  String get settingsNotificationPermissionDenied =>
      'Notification permission is required. Enable it in device settings.';

  @override
  String get notificationTitle => 'Security Pulse';

  @override
  String get notificationBody => 'Your daily security challenge is ready';

  @override
  String progressStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String progressCompleted(int completed, int total) {
    return '$completed of $total completed';
  }

  @override
  String get campaignEligibleBadge => 'Prize draw eligible';

  @override
  String get campaignEligibleSemantics =>
      'You are eligible for the current prize draw';

  @override
  String get scenarioStartButton => 'Start Challenge';

  @override
  String get scenarioChallengeReadyTitle => 'Today\'s Challenge';

  @override
  String get scenarioEstimatedTime => '~2 min';

  @override
  String scenarioOptionsCount(int count) => '$count options';

  @override
  String get scenarioStreakKept => 'Streak maintained!';

  @override
  String get scenarioKeepGoing => 'Come back tomorrow to keep learning';

  @override
  String get signInWelcomeTitle => 'Welcome back';

  @override
  String get navToday => 'Today';

  @override
  String get navHistory => 'History';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get profileScreenTitle => 'Profile';

  @override
  String get profileEmptyTitle => 'No activity yet';

  @override
  String get profileEmptyMessage =>
      'Complete your first scenario to see your profile.';

  @override
  String get profileStreakLabel => 'day streak';

  @override
  String get profileTotalResponsesLabel => 'Responses';

  @override
  String get profileAccuracyLabel => 'Accuracy';

  @override
  String get profileStreakDaysLabel => 'Streak';

  @override
  String get profileBadgesSectionTitle => 'Badges';

  @override
  String get profileBadgeCampaignEligible => 'Prize draw eligible';

  @override
  String get profileBadgeFirstScenario => 'First challenge';

  @override
  String get profileBadgeWeekStreak => '7-day streak';

  @override
  String profileDisplayNameSemantics(String name) {
    return 'Your anonymised employee identifier is $name';
  }

  @override
  String profileAccuracySemantics(String percent) {
    return '$percent accuracy rate';
  }

  @override
  String get settingsAccountSectionTitle => 'Account';

  @override
  String get settingsProfileLabel => 'Profile';

  @override
  String get settingsPreferencesSectionTitle => 'Preferences';

  @override
  String get settingsAppSectionTitle => 'App';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get settingsPrivacyLabel => 'Privacy Policy';

  @override
  String get settingsSupportLabel => 'Support';

  @override
  String get settingsSignOutLabel => 'Sign out';

  @override
  String get settingsUrlDialogTitle => 'Open in browser';

  @override
  String get settingsUrlDialogBody =>
      'Copy this address to open it in your browser:';

  @override
  String get settingsUrlDialogClose => 'Close';

  @override
  String get modeSelectorTitle => 'How will you use Security Pulse?';

  @override
  String get modeSelectorSubtitle =>
      'Choose the experience that fits you best.';

  @override
  String get modeWorkTitle => 'Work';

  @override
  String get modeWorkSubtitle =>
      'Your organisation’s security awareness platform';

  @override
  String get modeSchoolTitle => 'School';

  @override
  String get modeSchoolSubtitle => 'For students and teachers';

  @override
  String get modePersonalTitle => 'Personal';

  @override
  String get modePersonalSubtitle =>
      'Learn at your own pace, no account needed';

  @override
  String get modeAlreadyHaveAccount => 'Already have a Work account? Sign in';

  @override
  String get guestWelcomeTitle => 'Welcome to Security Pulse';

  @override
  String get guestWelcomeSubtitle =>
      'Learn to spot cyber threats — no account required.';

  @override
  String get guestStartButton => 'Start exploring';

  @override
  String get guestSignInLink => 'Sign in with existing account';

  @override
  String get guestPrivacyNote => 'No personal data is collected in guest mode.';

  @override
  String get classJoinTitle => 'Join your class';

  @override
  String get classJoinRoleStudent => 'Student';

  @override
  String get classJoinRoleTeacher => 'Teacher';

  @override
  String get classJoinCodeLabel => 'Class code';

  @override
  String get classJoinCodeHint => 'e.g. SEC-2024';

  @override
  String get classJoinButton => 'Join class';

  @override
  String get classJoinValidationRequired => 'Class code is required';

  @override
  String get classJoinValidationLength => 'Code must be 3–20 characters';

  @override
  String get topicPacksTitle => 'Security Topics';

  @override
  String get topicPacksDemoBanner =>
      'Exploring as guest — sign in to track your progress.';

  @override
  String get topicPacksChallengeCount => '8 challenges';

  @override
  String topicPacksStartToast(String category) {
    return 'Loading a $category challenge…';
  }

  @override
  String get leaderboardTitle => 'This Week’s Leaders';

  @override
  String get leaderboardSubtitle => 'Your class';

  @override
  String get leaderboardDemoBanner => 'Showing demo leaderboard data.';

  @override
  String get leaderboardStreakLabel => 'streak';

  @override
  String get leaderboardCompletedLabel => 'completed';

  @override
  String get leaderboardYouLabel => 'You';

  @override
  String get navLeaderboard => 'Leaderboard';

  @override
  String get navTopics => 'Topics';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get teacherDashboardTitle => 'Your Classroom';

  @override
  String get teacherDashboardDemoBanner =>
      'Showing demo data for class SEC-101.';

  @override
  String get teacherDashboardActiveStudents => 'Active Students';

  @override
  String get teacherDashboardAvgCompletion => 'Avg Completion';

  @override
  String get teacherDashboardTopStreak => 'Top Streak';

  @override
  String get teacherDashboardRecentActivity => 'Recent Activity';

  @override
  String get teacherDashboardAssignButton => 'Assign challenge';

  @override
  String get teacherDashboardAssignComingSoon =>
      'Scenario assignment coming soon.';

  @override
  String get teacherDashboardViewLeaderboard => 'View leaderboard';
}
