//
//  DailyCardModel.swift
//  SecurityPulseWidget
//
//  Non-sensitive data model shared between the Flutter app and the iOS widget.
//  The Flutter app writes this to the App Group UserDefaults.
//  The widget extension reads it via TimelineProvider.
//
//  IMPORTANT: This struct must only contain non-sensitive fields.
//  Never add: auth tokens, is_correct, explanation, employee PII,
//  incident data, or any confidential corporate content.
//

import Foundation

/// Completion state of the daily scenario.
enum DailyCardCompletionState: String, Codable {
    case available
    case completed
    case noAssignment = "no_assignment"
    case offline
    case signedOut = "signed_out"
}

/// Minimal model written to App Group storage by the Flutter app.
/// Read by the WidgetKit TimelineProvider.
struct DailyCardModel: Codable {
    /// UUID of the scenario. Used to construct the deep link.
    let scenarioId: String?
    /// Short title of the scenario (max 80 characters).
    let title: String
    /// Current completion state.
    let completionState: DailyCardCompletionState
    /// Deep link route to open in the Flutter app.
    let deepLinkRoute: String?
    /// When this cache entry expires. Widget shows offline state after this.
    let expiresAt: Date?

    /// Returns the deep link URL for this card, or nil if unavailable.
    var deepLinkURL: URL? {
        guard let route = deepLinkRoute else { return nil }
        return URL(string: "securitypulse://\(route)")
    }

    /// App Group identifier — must match the entitlement in both targets.
    /// Replace with your organisation's App Group identifier.
    static let appGroupIdentifier = "group.com.securitypulse.shared"

    /// UserDefaults key for the daily card model.
    static let defaultsKey = "daily_card_model"

    /// Reads the current model from App Group UserDefaults.
    /// Returns a signed-out fallback if no data is present.
    static func read() -> DailyCardModel {
        guard
            let defaults = UserDefaults(suiteName: appGroupIdentifier),
            let data = defaults.data(forKey: defaultsKey),
            let model = try? JSONDecoder().decode(DailyCardModel.self, from: data)
        else {
            return DailyCardModel(
                scenarioId: nil,
                title: "Sign in to see today's question",
                completionState: .signedOut,
                deepLinkRoute: nil,
                expiresAt: nil
            )
        }

        // Check expiry
        if let expiresAt = model.expiresAt, expiresAt < Date() {
            return DailyCardModel(
                scenarioId: model.scenarioId,
                title: model.title,
                completionState: .offline,
                deepLinkRoute: model.deepLinkRoute,
                expiresAt: model.expiresAt
            )
        }

        return model
    }
}
