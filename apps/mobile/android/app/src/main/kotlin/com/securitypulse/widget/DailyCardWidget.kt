// DailyCardWidget.kt
// Security Pulse — Android home-screen widget using Jetpack Glance
//
// Setup required (Android Studio):
// 1. Add Jetpack Glance dependencies to build.gradle
// 2. Register the widget receiver in AndroidManifest.xml
// 3. Create res/xml/security_pulse_widget_info.xml
//
// Security:
// - Only reads DailyCardModel from SharedPreferences
// - Never reads auth tokens, answer correctness, or PII
// - All actions deep-link to the Flutter app (server-side auth enforced there)

package com.securitypulse.widget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.*
import androidx.glance.semantics.semantics
import androidx.glance.semantics.contentDescription
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import android.graphics.Color
import androidx.glance.action.Action
import androidx.glance.appwidget.action.actionStartActivity
import android.content.Intent

class DailyCardWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val model = DailyCardModel.read(context)
        provideContent {
            GlanceTheme {
                DailyCardWidgetContent(context = context, model = model)
            }
        }
    }
}

@Composable
private fun DailyCardWidgetContent(context: Context, model: DailyCardModel) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(Color.WHITE))
            .padding(12.dp)
            .clickable(deepLinkAction(context, model)),
        contentAlignment = Alignment.TopStart,
    ) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            // Header
            Text(
                text = "Security Pulse",
                style = TextStyle(
                    color = ColorProvider(Color.parseColor("#6B7280")),
                ),
            )

            Spacer(modifier = GlanceModifier.defaultWeight())

            // Content based on state
            when (model.completionState) {
                CompletionState.AVAILABLE -> AvailableContent(model)
                CompletionState.COMPLETED -> CompletedContent()
                CompletionState.NO_ASSIGNMENT -> NoAssignmentContent()
                CompletionState.OFFLINE -> OfflineContent("Offline")
                CompletionState.SIGNED_OUT -> OfflineContent("Sign in to continue")
            }

            Spacer(modifier = GlanceModifier.defaultWeight())
        }
    }
}

@Composable
private fun AvailableContent(model: DailyCardModel) {
    Column {
        Text(
            text = model.title,
            style = TextStyle(
                color = ColorProvider(Color.parseColor("#111928")),
            ),
            maxLines = 3,
            modifier = GlanceModifier.semantics {
                contentDescription = "Security Pulse: ${model.title}. Tap to answer."
            },
        )
        Spacer(modifier = GlanceModifier.height(8.dp))
        Text(
            text = "Answer now →",
            style = TextStyle(
                color = ColorProvider(Color.parseColor("#1A56DB")),
            ),
        )
    }
}

@Composable
private fun CompletedContent() {
    Text(
        text = "✓ Completed today",
        style = TextStyle(color = ColorProvider(Color.parseColor("#057A55"))),
        modifier = GlanceModifier.semantics {
            contentDescription = "Security Pulse: Today's question completed."
        },
    )
}

@Composable
private fun NoAssignmentContent() {
    Text(
        text = "No question today",
        style = TextStyle(color = ColorProvider(Color.parseColor("#6B7280"))),
        modifier = GlanceModifier.semantics {
            contentDescription = "Security Pulse: No question assigned today."
        },
    )
}

@Composable
private fun OfflineContent(label: String) {
    Text(
        text = label,
        style = TextStyle(color = ColorProvider(Color.parseColor("#6B7280"))),
        modifier = GlanceModifier.semantics {
            contentDescription = "Security Pulse: $label."
        },
    )
}

private fun deepLinkAction(context: Context, model: DailyCardModel): Action {
    val uri = model.deepLinkUri?.let { Uri.parse(it) }
        ?: Uri.parse("securitypulse:///")
    val intent = Intent(Intent.ACTION_VIEW, uri).apply {
        setPackage(context.packageName)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK
    }
    return actionStartActivity(intent)
}

class DailyCardWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = DailyCardWidget()
}
