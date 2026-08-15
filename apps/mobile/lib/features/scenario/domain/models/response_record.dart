/// A single entry in the user's response history.
library;

import 'package:flutter/foundation.dart';

/// Represents a past response to a scenario.
@immutable
class ResponseRecord {
  const ResponseRecord({
    required this.id,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.submittedAt,
    required this.isCorrect,
  });

  /// Creates a [ResponseRecord] from a JSON map (API response).
  factory ResponseRecord.fromJson(Map<String, dynamic> json) {
    return ResponseRecord(
      id: json['id'] as String,
      scenarioId: json['scenario_id'] as String,
      scenarioTitle: json['scenario_title'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      isCorrect: json['is_correct'] as bool,
    );
  }

  /// Unique identifier for this response.
  final String id;

  /// The scenario that was answered.
  final String scenarioId;

  /// Title of the scenario.
  final String scenarioTitle;

  /// When the response was submitted.
  final DateTime submittedAt;

  /// Whether the response was correct.
  final bool isCorrect;
}
