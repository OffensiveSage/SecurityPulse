// SecurityPulseWidgetBundle.swift
// Security Pulse — WidgetKit entry point
//
// Registers the SecurityPulseWidget with the system.

import SwiftUI
import WidgetKit

@main
struct SecurityPulseWidgetBundle: WidgetBundle {
    var body: some Widget {
        SecurityPulseWidget()
    }
}
