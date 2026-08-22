/// Mock implementation of [ScenarioRepository] for local development.
///
/// Rotates through four security scenarios keyed by day-of-week so that
/// reloading the app on a different day shows a different question.
/// History and progress are pre-populated so every screen has content to show.
library;

import '../../domain/models/response_record.dart';
import '../../domain/models/scenario.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/repositories/scenario_repository.dart';

class MockScenarioRepository implements ScenarioRepository {
  static const _scenarios = [
    _ScenarioSeed(
      scenario: Scenario(
        id: 'scenario-phishing',
        title: 'Suspicious Email from IT Support',
        prompt:
            'You receive an email from "IT-Support@yourcompany.co" asking you '
            'to verify your credentials by clicking a link due to a "mandatory '
            'security upgrade." The email includes your company\'s logo and '
            'threatens account suspension if you don\'t act within 24 hours.',
        category: 'Phishing',
        options: [
          AnswerOption(
            id: 'ph-1',
            text:
                'Click the link and enter your credentials to avoid losing access',
          ),
          AnswerOption(
            id: 'ph-2',
            text: 'Forward the email to the security team and delete it',
            displayOrder: 1,
          ),
          AnswerOption(
            id: 'ph-3',
            text: 'Reply to the sender asking if the email is legitimate',
            displayOrder: 2,
          ),
          AnswerOption(
            id: 'ph-4',
            text: 'Ignore the email and do nothing',
            displayOrder: 3,
          ),
        ],
      ),
      correctOptionId: 'ph-2',
      explanation:
          'This email shows several classic phishing indicators: a slightly '
          'misspelled domain (.co instead of .com), urgency tactics threatening '
          'account suspension, and a request to enter credentials through an '
          'email link. Legitimate IT departments never ask employees to verify '
          'passwords through email links.',
      recommendedAction:
          'Report suspicious emails to your security team using the designated '
          'reporting process. Never click links in unexpected emails asking for '
          'credentials. When in doubt, contact IT through a known, trusted '
          'channel such as your company directory or IT service portal.',
    ),
    _ScenarioSeed(
      scenario: Scenario(
        id: 'scenario-mfa-fatigue',
        title: 'Repeated MFA Push Notifications',
        prompt:
            'You receive 10 MFA approval push notifications in quick succession '
            'on your phone even though you haven\'t tried to log in. A colleague '
            'then messages you on Teams saying "I accidentally sent you a few '
            'pushes, just approve one to clear them."',
        category: 'MFA Fatigue',
        options: [
          AnswerOption(
            id: 'mf-1',
            text:
                'Approve one notification to clear the queue as your colleague asked',
          ),
          AnswerOption(
            id: 'mf-2',
            text:
                'Deny all notifications, change your password immediately, and report it to the security team',
            displayOrder: 1,
          ),
          AnswerOption(
            id: 'mf-3',
            text: 'Ignore the notifications until they stop',
            displayOrder: 2,
          ),
          AnswerOption(
            id: 'mf-4',
            text: 'Call your colleague back to confirm before approving',
            displayOrder: 3,
          ),
        ],
      ),
      correctOptionId: 'mf-2',
      explanation:
          'This is an MFA fatigue (push bombing) attack. Attackers spam MFA '
          'requests hoping the target approves one out of annoyance or confusion. '
          'The Teams message is a social engineering attempt — your "colleague\'s" '
          'account may already be compromised. Approving even one push grants '
          'the attacker full access.',
      recommendedAction:
          'Deny all unexpected MFA pushes immediately. Change your password and '
          'report the incident to your security team. Never approve an MFA '
          'request you did not initiate, even when asked by a colleague.',
    ),
    _ScenarioSeed(
      scenario: Scenario(
        id: 'scenario-ransomware',
        title: 'Encrypted Files Message',
        prompt: 'You return from lunch to find a message on your screen: '
            '"Your files have been encrypted. Pay 2 BTC within 48 hours to '
            'recover them. Do NOT restart your computer." '
            'Several files on your desktop now have a .locked extension.',
        category: 'Ransomware',
        options: [
          AnswerOption(
            id: 'rw-1',
            text:
                'Pay the ransom — it\'s the fastest way to recover your files',
          ),
          AnswerOption(
            id: 'rw-2',
            text:
                'Immediately disconnect your device from the network, do not restart, and call the security operations centre',
            displayOrder: 1,
          ),
          AnswerOption(
            id: 'rw-3',
            text: 'Restart the computer to see if the message goes away',
            displayOrder: 2,
          ),
          AnswerOption(
            id: 'rw-4',
            text: 'Delete the .locked files to contain the spread',
            displayOrder: 3,
          ),
        ],
      ),
      correctOptionId: 'rw-2',
      explanation:
          'Ransomware spreads across network shares the moment it encrypts files. '
          'Disconnecting from the network immediately limits the blast radius. '
          'Restarting can trigger additional encryption or destroy forensic '
          'evidence. Paying the ransom does not guarantee file recovery and '
          'funds further criminal activity.',
      recommendedAction:
          'Disconnect from Wi-Fi and unplug the network cable. Do not restart '
          'or shut down. Call your security operations centre immediately. '
          'Preserve the device for forensic investigation.',
    ),
    _ScenarioSeed(
      scenario: Scenario(
        id: 'scenario-social-eng',
        title: 'CEO Emergency Wire Transfer',
        prompt:
            'You receive an urgent email — apparently from your CEO — asking you '
            'to process a confidential wire transfer of '
            r'$47,000 to a new vendor '
            "before end of day. The email says to keep it secret from your manager "
            "because it's a surprise acquisition deal.",
        category: 'Social Engineering',
        options: [
          AnswerOption(
            id: 'se-1',
            text:
                'Process the transfer — the CEO is rarely wrong and the deadline is urgent',
          ),
          AnswerOption(
            id: 'se-2',
            text:
                'Verify the request by calling the CEO directly using a phone number from the company directory, then follow normal approval procedures',
            displayOrder: 1,
          ),
          AnswerOption(
            id: 'se-3',
            text:
                'Reply to the email to confirm the details before transferring',
            displayOrder: 2,
          ),
          AnswerOption(
            id: 'se-4',
            text:
                'Forward the email to your manager even though the CEO said not to',
            displayOrder: 3,
          ),
        ],
      ),
      correctOptionId: 'se-2',
      explanation:
          'This is a Business Email Compromise (BEC) / CEO fraud attack. '
          'Attackers spoof executive email addresses to pressure employees into '
          'bypassing controls. The secrecy request and artificial urgency are '
          'major red flags. Replying to the email confirms contact with the '
          'attacker, not the real CEO.',
      recommendedAction:
          'Always verify unexpected financial requests out-of-band — call the '
          'requester directly using a number from your company directory, '
          'never one provided in the suspicious email. Follow all normal '
          'financial approval processes regardless of claimed urgency.',
    ),
  ];

  static final _mockHistory = [
    ResponseRecord(
      id: 'resp-1',
      scenarioId: 'scenario-phishing',
      scenarioTitle: 'Suspicious Email from IT Support',
      submittedAt: DateTime(2026, 8, 18),
      isCorrect: true,
    ),
    ResponseRecord(
      id: 'resp-2',
      scenarioId: 'scenario-mfa-fatigue',
      scenarioTitle: 'Repeated MFA Push Notifications',
      submittedAt: DateTime(2026, 8, 17),
      isCorrect: false,
    ),
    ResponseRecord(
      id: 'resp-3',
      scenarioId: 'scenario-ransomware',
      scenarioTitle: 'Encrypted Files Message',
      submittedAt: DateTime(2026, 8, 16),
      isCorrect: true,
    ),
    ResponseRecord(
      id: 'resp-4',
      scenarioId: 'scenario-social-eng',
      scenarioTitle: 'CEO Emergency Wire Transfer',
      submittedAt: DateTime(2026, 8, 15),
      isCorrect: true,
    ),
    ResponseRecord(
      id: 'resp-5',
      scenarioId: 'scenario-phishing',
      scenarioTitle: 'Suspicious Email from IT Support',
      submittedAt: DateTime(2026, 8, 14),
      isCorrect: false,
    ),
  ];

  static const _mockProgress = UserProgress(
    scenariosAssigned: 7,
    scenariosCompleted: 5,
    currentStreakDays: 3,
  );

  /// Picks a scenario based on the day of the week so the question changes
  /// daily without requiring a backend.
  _ScenarioSeed get _todaySeed =>
      _scenarios[DateTime.now().weekday % _scenarios.length];

  @override
  Future<Scenario?> getTodayScenario() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return _todaySeed.scenario;
  }

  @override
  Future<ScenarioResult> submitAnswer({
    required String scenarioId,
    required String selectedOptionId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final seed = _scenarios.firstWhere(
      (s) => s.scenario.id == scenarioId,
      orElse: () => _todaySeed,
    );

    return ScenarioResult(
      scenarioId: scenarioId,
      selectedOptionId: selectedOptionId,
      correctOptionId: seed.correctOptionId,
      isCorrect: selectedOptionId == seed.correctOptionId,
      explanation: seed.explanation,
      recommendedAction: seed.recommendedAction,
    );
  }

  @override
  Future<List<ResponseRecord>> getHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final start = (page - 1) * pageSize;
    if (start >= _mockHistory.length) return [];
    return _mockHistory.skip(start).take(pageSize).toList();
  }

  @override
  Future<UserProgress> getProgress() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _mockProgress;
  }
}

/// Bundles a [Scenario] with its correct answer and result text.
class _ScenarioSeed {
  const _ScenarioSeed({
    required this.scenario,
    required this.correctOptionId,
    required this.explanation,
    required this.recommendedAction,
  });

  final Scenario scenario;
  final String correctOptionId;
  final String explanation;
  final String recommendedAction;
}
