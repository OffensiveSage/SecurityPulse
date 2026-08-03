//
//  SecurityPulseWidget.swift
//  SecurityPulseWidget
//
//  iOS/iPadOS home-screen widget using SwiftUI and WidgetKit.
//
//  Setup required (Xcode):
//  1. Add a Widget Extension target named "SecurityPulseWidget"
//  2. Add the App Group entitlement to both the Runner and this extension
//  3. Replace the App Group identifier in DailyCardModel.swift
//  4. Configure the URL scheme "securitypulse" in Runner's Info.plist
//
//  Security:
//  - Only reads DailyCardModel from App Group storage
//  - Never reads auth tokens, answer correctness, or PII
//  - All actions deep-link to the Flutter app (server-side auth enforced there)
//

import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct DailyCardTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyCardEntry {
        DailyCardEntry(
            date: Date(),
            model: DailyCardModel(
                scenarioId: nil,
                title: "Today's security question",
                completionState: .available,
                deepLinkRoute: nil,
                expiresAt: nil
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyCardEntry) -> Void) {
        completion(DailyCardEntry(date: Date(), model: DailyCardModel.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyCardEntry>) -> Void) {
        let model = DailyCardModel.read()
        let entry = DailyCardEntry(date: Date(), model: model)

        // Refresh after 1 hour or at model expiry, whichever is sooner
        let nextRefresh = model.expiresAt.map { min($0, Date().addingTimeInterval(3600)) }
            ?? Date().addingTimeInterval(3600)

        let timeline = Timeline(
            entries: [entry],
            policy: .after(nextRefresh)
        )
        completion(timeline)
    }
}

// MARK: - Entry

struct DailyCardEntry: TimelineEntry {
    let date: Date
    let model: DailyCardModel
}

// MARK: - Widget Views

struct SecurityPulseWidgetEntryView: View {
    let entry: DailyCardEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch entry.model.completionState {
            case .available:
                AvailableCardView(model: entry.model)
            case .completed:
                CompletedCardView()
            case .noAssignment:
                NoAssignmentCardView()
            case .offline, .signedOut:
                OfflineCardView(state: entry.model.completionState)
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct AvailableCardView: View {
    let model: DailyCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Security Pulse", systemImage: "shield.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            Text(model.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(3)

            Spacer()

            Text("Answer now →")
                .font(.caption.weight(.medium))
                .foregroundStyle(.blue)
        }
        .padding()
        .widgetURL(model.deepLinkURL)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Security Pulse: \(model.title). Tap to answer.")
    }
}

struct CompletedCardView: View {
    var body: some View {
        VStack(spacing: 8) {
            Label("Security Pulse", systemImage: "shield.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(.green)

            Text("Completed today")
                .font(.subheadline.weight(.medium))

            Spacer()
        }
        .padding()
        .accessibilityLabel("Security Pulse: Today's question completed.")
    }
}

struct NoAssignmentCardView: View {
    var body: some View {
        VStack(spacing: 8) {
            Label("Security Pulse", systemImage: "shield.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text("No question today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .accessibilityLabel("Security Pulse: No question assigned today.")
    }
}

struct OfflineCardView: View {
    let state: DailyCardCompletionState

    var body: some View {
        VStack(spacing: 8) {
            Label("Security Pulse", systemImage: "shield.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Image(systemName: state == .signedOut ? "lock.fill" : "wifi.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(state == .signedOut ? "Sign in to continue" : "Offline")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .accessibilityLabel(state == .signedOut ? "Security Pulse: Sign in to see your question." : "Security Pulse: Offline.")
    }
}

// MARK: - Widget Configuration

struct SecurityPulseWidget: Widget {
    let kind: String = "SecurityPulseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyCardTimelineProvider()) { entry in
            SecurityPulseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Security Pulse")
        .description("View your daily security question.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
