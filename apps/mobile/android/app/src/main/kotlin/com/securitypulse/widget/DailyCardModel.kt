// DailyCardModel.kt
// Security Pulse — Android widget data model
//
// Non-sensitive data model shared between the Flutter app and the Android widget.
// The Flutter app writes this to SharedPreferences.
// The Jetpack Glance widget reads it.
//
// IMPORTANT: Only non-sensitive fields are permitted.
// Never add: auth tokens, is_correct, explanation, PII, incident data.

package com.securitypulse.widget

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject
import java.time.Instant

/**
 * Completion state of the daily scenario.
 */
enum class CompletionState {
    AVAILABLE,
    COMPLETED,
    NO_ASSIGNMENT,
    OFFLINE,
    SIGNED_OUT;

    companion object {
        fun fromString(value: String): CompletionState = when (value) {
            "available" -> AVAILABLE
            "completed" -> COMPLETED
            "no_assignment" -> NO_ASSIGNMENT
            "offline" -> OFFLINE
            "signed_out" -> SIGNED_OUT
            else -> OFFLINE
        }
    }
}

/**
 * Minimal model written to SharedPreferences by the Flutter app.
 * Read by the Jetpack Glance AppWidget.
 */
data class DailyCardModel(
    val scenarioId: String?,
    val title: String,
    val completionState: CompletionState,
    val deepLinkRoute: String?,
    val expiresAt: Instant?,
) {
    companion object {
        private const val PREFS_NAME = "security_pulse_widget"
        private const val KEY_DAILY_CARD = "daily_card_model"
        private const val DEEP_LINK_SCHEME = "securitypulse"

        /**
         * Reads the current model from SharedPreferences.
         * Returns a signed-out fallback if no data is present.
         */
        fun read(context: Context): DailyCardModel {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(KEY_DAILY_CARD, null) ?: return signedOut()

            return try {
                val obj = JSONObject(json)
                val expiresAtStr = obj.optString("expiresAt", "")
                val expiresAt = if (expiresAtStr.isNotEmpty()) Instant.parse(expiresAtStr) else null

                // Check expiry
                if (expiresAt != null && Instant.now().isAfter(expiresAt)) {
                    return DailyCardModel(
                        scenarioId = obj.optString("scenarioId").takeIf { it.isNotEmpty() },
                        title = obj.optString("title", "Security Pulse"),
                        completionState = CompletionState.OFFLINE,
                        deepLinkRoute = obj.optString("deepLinkRoute").takeIf { it.isNotEmpty() },
                        expiresAt = expiresAt,
                    )
                }

                DailyCardModel(
                    scenarioId = obj.optString("scenarioId").takeIf { it.isNotEmpty() },
                    title = obj.optString("title", "Security Pulse"),
                    completionState = CompletionState.fromString(
                        obj.optString("completionState", "signed_out")
                    ),
                    deepLinkRoute = obj.optString("deepLinkRoute").takeIf { it.isNotEmpty() },
                    expiresAt = expiresAt,
                )
            } catch (e: Exception) {
                signedOut()
            }
        }

        private fun signedOut() = DailyCardModel(
            scenarioId = null,
            title = "Sign in to see today's question",
            completionState = CompletionState.SIGNED_OUT,
            deepLinkRoute = null,
            expiresAt = null,
        )
    }

    /** Returns the deep link URI string for this card, or null if unavailable. */
    val deepLinkUri: String?
        get() = deepLinkRoute?.let { "$DEEP_LINK_SCHEME://$it" }
}
