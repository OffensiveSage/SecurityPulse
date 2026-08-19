// DailyCardWidget.kt
// Security Pulse — Android home-screen widget using Jetpack Glance
//
// Security:
// - Only reads DailyCardModel from SharedPreferences
// - Never reads auth tokens, answer correctness, or PII
// - All actions deep-link to the Flutter app (server-side auth enforced there)

package com.securitypulse.widget

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.*
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

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

// Brand colours
private val brandBlue   = ColorProvider(Color.parseColor("#1A56DB"))
private val brandGreen  = ColorProvider(Color.parseColor("#057A55"))
private val white       = ColorProvider(Color.WHITE)
private val lightBlue   = ColorProvider(Color.parseColor("#EBF5FF"))
private val lightGreen  = ColorProvider(Color.parseColor("#DEF7EC"))
private val lightGray   = ColorProvider(Color.parseColor("#F3F4F6"))
private val textDark    = ColorProvider(Color.parseColor("#111928"))
private val textMuted   = ColorProvider(Color.parseColor("#6B7280"))

@Composable
private fun DailyCardWidgetContent(context: Context, model: DailyCardModel) {
    val action = deepLinkAction(context, model)

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(white)
            .cornerRadius(16)
            .clickable(action),
    ) {
        Column(modifier = GlanceModifier.fillMaxSize()) {

            // ── Blue accent bar at the top ──────────────────────────────
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .height(6.dp)
                    .background(brandBlue),
            ) {}

            // ── Main content ────────────────────────────────────────────
            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .padding(horizontal = 14.dp, vertical = 12.dp),
            ) {
                // App label row
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "Security Pulse",
                        style = TextStyle(
                            color = brandBlue,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                    )
                }

                Spacer(modifier = GlanceModifier.height(10.dp))

                when (model.completionState) {
                    CompletionState.AVAILABLE    -> AvailableContent(model)
                    CompletionState.COMPLETED    -> CompletedContent()
                    CompletionState.NO_ASSIGNMENT -> NoAssignmentContent()
                    CompletionState.OFFLINE      -> StatusContent("Offline", isWarning = true)
                    CompletionState.SIGNED_OUT   -> StatusContent("Sign in →", isWarning = false)
                }
            }
        }
    }
}

@Composable
private fun AvailableContent(model: DailyCardModel) {
    Column(modifier = GlanceModifier.fillMaxSize()) {
        // Challenge badge
        Box(
            modifier = GlanceModifier
                .background(lightBlue)
                .cornerRadius(6)
                .padding(horizontal = 8.dp, vertical = 4.dp),
        ) {
            Text(
                text = "Daily Challenge",
                style = TextStyle(
                    color = brandBlue,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
        }

        Spacer(modifier = GlanceModifier.height(8.dp))

        Text(
            text = model.title.take(72),
            style = TextStyle(
                color = textDark,
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium,
            ),
            maxLines = 3,
            modifier = GlanceModifier.semantics {
                contentDescription = "Security Pulse: ${model.title}. Tap to answer."
            },
        )

        Spacer(modifier = GlanceModifier.defaultWeight())

        Text(
            text = "Tap to answer →",
            style = TextStyle(
                color = brandBlue,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
private fun CompletedContent() {
    Column(modifier = GlanceModifier.fillMaxSize()) {
        Box(
            modifier = GlanceModifier
                .background(lightGreen)
                .cornerRadius(6)
                .padding(horizontal = 8.dp, vertical = 4.dp),
        ) {
            Text(
                text = "Completed",
                style = TextStyle(
                    color = brandGreen,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                ),
            )
        }

        Spacer(modifier = GlanceModifier.height(8.dp))

        Text(
            text = "Today's challenge done!",
            style = TextStyle(
                color = textDark,
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium,
            ),
            modifier = GlanceModifier.semantics {
                contentDescription = "Security Pulse: Today's question completed."
            },
        )

        Spacer(modifier = GlanceModifier.defaultWeight())

        Text(
            text = "See your history →",
            style = TextStyle(
                color = brandGreen,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
            ),
        )
    }
}

@Composable
private fun NoAssignmentContent() {
    Column(modifier = GlanceModifier.fillMaxSize()) {
        Text(
            text = "No question today",
            style = TextStyle(
                color = textDark,
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium,
            ),
            modifier = GlanceModifier.semantics {
                contentDescription = "Security Pulse: No question assigned today."
            },
        )
        Spacer(modifier = GlanceModifier.height(6.dp))
        Text(
            text = "Check back tomorrow",
            style = TextStyle(color = textMuted, fontSize = 11.sp),
        )
    }
}

@Composable
private fun StatusContent(label: String, isWarning: Boolean) {
    Column(modifier = GlanceModifier.fillMaxSize()) {
        Text(
            text = label,
            style = TextStyle(
                color = if (isWarning) textMuted else brandBlue,
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium,
            ),
            modifier = GlanceModifier.semantics {
                contentDescription = "Security Pulse: $label."
            },
        )
        Spacer(modifier = GlanceModifier.height(6.dp))
        Text(
            text = if (isWarning) "Tap to retry" else "Tap to open app",
            style = TextStyle(color = textMuted, fontSize = 11.sp),
        )
    }
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
