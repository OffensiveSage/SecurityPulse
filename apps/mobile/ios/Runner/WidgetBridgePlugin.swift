// WidgetBridgePlugin.swift
// Security Pulse — Flutter ↔ iOS widget bridge
//
// Handles MethodChannel calls from Flutter to write DailyCardModel JSON
// to App Group UserDefaults, then triggers WidgetKit timeline reload.
//
// IMPORTANT: Only non-sensitive DailyCardModel data passes through this bridge.
// Never write auth tokens, answers, PII, or incident data.

import Flutter
import WidgetKit

class WidgetBridgePlugin: NSObject, FlutterPlugin {
    private static let channelName = "com.securitypulse/widget_bridge"
    private static let suiteName = "group.com.securitypulse.shared"
    private static let key = "daily_card_model"

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = WidgetBridgePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateDailyCard":
            guard let jsonString = call.arguments as? String else {
                result(FlutterError(
                    code: "INVALID_ARGUMENT",
                    message: "Expected JSON string",
                    details: nil
                ))
                return
            }
            writeDailyCard(jsonString)
            reloadWidgets()
            result(nil)

        case "clearDailyCard":
            clearDailyCard()
            reloadWidgets()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func writeDailyCard(_ jsonString: String) {
        guard let defaults = UserDefaults(suiteName: WidgetBridgePlugin.suiteName) else {
            return
        }
        defaults.set(jsonString, forKey: WidgetBridgePlugin.key)
    }

    private func clearDailyCard() {
        guard let defaults = UserDefaults(suiteName: WidgetBridgePlugin.suiteName) else {
            return
        }
        defaults.removeObject(forKey: WidgetBridgePlugin.key)
    }

    private func reloadWidgets() {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
