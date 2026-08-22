/// Domain models for the daily scenario feature.
///
/// These are immutable value objects representing a cybersecurity scenario,
/// its answer options, and the result after submission.
library;

import 'package:flutter/foundation.dart';

/// A cybersecurity awareness scenario presented to the employee.
@immutable
class Scenario {
  const Scenario({
    required this.id,
    required this.title,
    required this.prompt,
    required this.category,
    required this.options,
    this.difficulty = 'beginner',
  });

  /// Creates a [Scenario] from a JSON map (API response).
  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: json['id'] as String,
      title: json['title'] as String,
      prompt: json['prompt'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      options: (json['answer_options'] as List<dynamic>)
          .map(
            (e) => AnswerOption.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  /// Unique identifier for the scenario.
  final String id;

  /// Short title summarizing the scenario (max 80 chars per widget contract).
  final String title;

  /// The scenario description presenting a cybersecurity situation.
  final String prompt;

  /// Category of the scenario (e.g., Phishing, Password Security).
  final String category;

  /// Difficulty level (beginner, intermediate, advanced).
  final String difficulty;

  /// Available answer choices (max 4 per product spec).
  final List<AnswerOption> options;
}

/// A single answer choice within a scenario.
@immutable
class AnswerOption {
  const AnswerOption({
    required this.id,
    required this.text,
    this.displayOrder = 0,
  });

  /// Creates an [AnswerOption] from a JSON map (API response).
  factory AnswerOption.fromJson(Map<String, dynamic> json) {
    return AnswerOption(
      id: json['id'] as String,
      text: json['text'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  /// Unique identifier for this option.
  final String id;

  /// The answer text displayed to the employee.
  final String text;

  /// Display order for consistent rendering.
  final int displayOrder;
}

/// The result returned after the employee submits an answer.
///
/// Contains correctness, explanation, and recommended action.
/// Per the product spec, [isCorrect] is never served before submission.
@immutable
class ScenarioResult {
  const ScenarioResult({
    required this.scenarioId,
    required this.selectedOptionId,
    required this.correctOptionId,
    required this.isCorrect,
    required this.explanation,
    required this.recommendedAction,
  });

  /// Creates a [ScenarioResult] from a JSON map (API response).
  factory ScenarioResult.fromJson(Map<String, dynamic> json) {
    // Find the correct option ID from the answer_options list
    final answerOptions = json['answer_options'] as List<dynamic>;
    final correctOption = answerOptions.firstWhere(
      (opt) => (opt as Map<String, dynamic>)['is_correct'] == true,
    ) as Map<String, dynamic>;

    return ScenarioResult(
      scenarioId: json['scenario_id'] as String,
      selectedOptionId: json['selected_option_id'] as String,
      correctOptionId: correctOption['id'] as String,
      isCorrect: json['is_correct'] as bool,
      explanation: json['explanation'] as String,
      recommendedAction: json['recommended_action'] as String,
    );
  }

  /// The scenario this result belongs to.
  final String scenarioId;

  /// The option the employee selected.
  final String selectedOptionId;

  /// The correct option (revealed after submission).
  final String correctOptionId;

  /// Whether the employee answered correctly.
  final bool isCorrect;

  /// Explanation of why the correct answer is correct.
  final String explanation;

  /// The recommended secure action the employee should take.
  final String recommendedAction;
}
