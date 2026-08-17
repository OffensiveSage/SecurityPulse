// WidgetBridgePlugin.kt
// Security Pulse — Flutter ↔ Android widget bridge
//
// Handles MethodChannel calls from Flutter to write DailyCardModel JSON
// to SharedPreferences, then triggers widget updates.
//
// IMPORTANT: Only non-sensitive DailyCardModel data passes through this bridge.
// Never write auth tokens, answers, PII, or incident data.

package com.securitypulse.security_pulse

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WidgetBridgePlugin {
    companion object {
        private const val CHANNEL = "com.securitypulse/widget_bridge"
        private const val PREFS_NAME = "security_pulse_widget"
        private const val KEY_DAILY_CARD = "daily_card_model"

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "updateDailyCard" -> {
                        val jsonString = call.arguments as? String
                        if (jsonString == null) {
                            result.error("INVALID_ARGUMENT", "Expected JSON string", null)
                            return@setMethodCallHandler
                        }
                        writeDailyCard(context, jsonString)
                        updateWidgets(context)
                        result.success(null)
                    }
                    "clearDailyCard" -> {
                        clearDailyCard(context)
                        updateWidgets(context)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        private fun writeDailyCard(context: Context, jsonString: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putString(KEY_DAILY_CARD, jsonString).apply()
        }

        private fun clearDailyCard(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().remove(KEY_DAILY_CARD).apply()
        }

        private fun updateWidgets(context: Context) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val widgetComponent = ComponentName(
                    context,
                    "com.securitypulse.widget.DailyCardWidgetReceiver"
                )
                val widgetIds = appWidgetManager.getAppWidgetIds(widgetComponent)
                if (widgetIds.isNotEmpty()) {
                    appWidgetManager.notifyAppWidgetViewDataChanged(widgetIds, android.R.id.text1)
                    // Trigger Glance widget update by sending APPWIDGET_UPDATE broadcast
                    val intent = android.content.Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                    intent.component = widgetComponent
                    intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
                    context.sendBroadcast(intent)
                }
            } catch (_: Exception) {
                // Widget update is best-effort. If widget class is not found, ignore.
            }
        }
    }
}
