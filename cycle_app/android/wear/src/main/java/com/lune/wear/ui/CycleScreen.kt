package com.lune.wear.ui

import android.content.Context
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.Text
import com.lune.wear.data.CycleData

// ---------------------------------------------------------------------------
// Bilingual strings (Arabic + English)
// ---------------------------------------------------------------------------
private object WatchStrings {
    fun days(context: Context, current: Int, max: Int): String {
        val locale = context.resources.configuration.locales[0].language
        return if (locale == "ar") "$current من $max يوم" else "$current of $max days"
    }

    fun daysUntil(context: Context, days: Int): String {
        val locale = context.resources.configuration.locales[0].language
        return if (locale == "ar") "$days يوم حتى الدورة" else "$days days until period"
    }

    fun logPeriod(context: Context): String {
        val locale = context.resources.configuration.locales[0].language
        return if (locale == "ar") "تسجيل الدورة" else "Log Period"
    }

    fun synced(context: Context): String {
        val locale = context.resources.configuration.locales[0].language
        return if (locale == "ar") "متزامن" else "Synced"
    }

    fun noConnection(context: Context): String {
        val locale = context.resources.configuration.locales[0].language
        return if (locale == "ar") "لا يوجد اتصال" else "No connection"
    }

    fun phase(context: Context, phase: String): String {
        val locale = context.resources.configuration.locales[0].language
        if (locale == "ar") {
            return when (phase.lowercase()) {
                "menstruation", "period" -> "حيض"
                "follicular" -> "جريبية"
                "ovulation" -> "تبويض"
                "luteal" -> "لوتينية"
                else -> phase
            }
        }
        return phase.replaceFirstChar { it.uppercase() }
    }
}

@Composable
fun CycleScreen(
    cycleData: CycleData,
    connected: Boolean,
    onLogPeriod: () -> Unit
) {
    val context = LocalContext.current
    val animatedProgress by animateFloatAsState(
        targetValue = cycleData.progress,
        animationSpec = tween(durationMillis = 800),
        label = "progress"
    )

    ScalingLazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        item {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier.size(140.dp)
            ) {
                CycleRing(
                    progress = animatedProgress,
                    phase = cycleData.phase
                )
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "${cycleData.currentValue}",
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    Text(
                        text = WatchStrings.days(context, cycleData.currentValue, cycleData.maxValue),
                        fontSize = 10.sp,
                        color = Color.White.copy(alpha = 0.7f)
                    )
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = WatchStrings.phase(context, cycleData.phase),
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = phaseColor(cycleData.phase),
                textAlign = TextAlign.Center
            )
        }

        item {
            if (cycleData.daysUntilPeriod > 0) {
                Text(
                    text = WatchStrings.daysUntil(context, cycleData.daysUntilPeriod),
                    fontSize = 10.sp,
                    color = Color.White.copy(alpha = 0.6f),
                    textAlign = TextAlign.Center
                )
            }
        }

        item {
            Spacer(modifier = Modifier.height(12.dp))
            Button(
                onClick = onLogPeriod,
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFFE91E63)
                ),
                modifier = Modifier.size(60.dp)
            ) {
                Text(
                    text = WatchStrings.logPeriod(context),
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        item {
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = if (connected) WatchStrings.synced(context) else WatchStrings.noConnection(context),
                fontSize = 9.sp,
                color = if (connected) Color(0xFF4CAF50) else Color(0xFFFF5722),
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
fun CycleRing(progress: Float, phase: String) {
    val ringColor = phaseColor(phase)
    val trackColor = Color.White.copy(alpha = 0.15f)

    Canvas(modifier = Modifier.fillMaxSize()) {
        val strokeWidth = 10.dp.toPx()
        val padding = strokeWidth / 2
        val arcSize = Size(size.width - strokeWidth, size.height - strokeWidth)
        val topLeft = Offset(padding, padding)

        drawArc(
            color = trackColor,
            startAngle = -90f,
            sweepAngle = 360f,
            useCenter = false,
            topLeft = topLeft,
            size = arcSize,
            style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
        )

        drawArc(
            color = ringColor,
            startAngle = -90f,
            sweepAngle = 360f * progress,
            useCenter = false,
            topLeft = topLeft,
            size = arcSize,
            style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
        )
    }
}

fun phaseColor(phase: String): Color {
    return when (phase.lowercase()) {
        "menstruation", "period", "حيض" -> Color(0xFFE91E63)
        "follicular", "جريبية" -> Color(0xFF9C27B0)
        "ovulation", "تبويض" -> Color(0xFFFF9800)
        "luteal", "لوتينية" -> Color(0xFF2196F3)
        else -> Color(0xFF4CAF50)
    }
}
