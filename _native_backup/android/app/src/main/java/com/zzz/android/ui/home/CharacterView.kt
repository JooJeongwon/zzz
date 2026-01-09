package com.zzz.android.ui.home

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun CharacterView(
    status: String,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.size(200.dp),
        contentAlignment = Alignment.Center
    ) {
        // Background Aura
        StatusAura(status = status)

        // Main Character Emoji
        CharacterEmoji(status = status)

        // Status Specific Animations (Zzz, Sweat drops, etc.)
        StatusEffects(status = status)
    }
}

@Composable
fun CharacterEmoji(status: String) {
    val emoji = when (status) {
        "ONLINE" -> "🙂"
        "SLEEP" -> "😴"
        "STUDY" -> "🤓"
        "BUSY" -> "😵"
        else -> "🤔"
    }

    val infiniteTransition = rememberInfiniteTransition(label = "breathing")
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.05f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Text(
        text = emoji,
        fontSize = 100.sp,
        modifier = Modifier.padding(16.dp)
            // Apply scale only for ONLINE to look alive
            .then(if (status == "ONLINE") Modifier.size(100.dp * scale) else Modifier)
    )
}

@Composable
fun StatusAura(status: String) {
    val color = when (status) {
        "ONLINE" -> Color.Green
        "SLEEP" -> Color.Blue
        "STUDY" -> Color(0xFFFFA500) // Orange
        "BUSY" -> Color.Red
        else -> Color.Gray
    }

    val infiniteTransition = rememberInfiniteTransition(label = "aura")
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 0.3f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500),
            repeatMode = RepeatMode.Reverse
        ),
        label = "alpha"
    )
    
    val scale by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500),
            repeatMode = RepeatMode.Restart
        ),
        label = "scale"
    )

    Canvas(modifier = Modifier.fillMaxSize()) {
        drawCircle(
            color = color.copy(alpha = alpha),
            radius = size.minDimension / 2 * scale
        )
    }
}

@Composable
fun StatusEffects(status: String) {
    if (status == "SLEEP") {
        // Zzz Animation
        val zItems = remember { listOf(0, 1, 2) }
        
        zItems.forEachIndexed { index, _ ->
            val infiniteTransition = rememberInfiniteTransition(label = "zzz")
            val yOffset by infiniteTransition.animateFloat(
                initialValue = 0f,
                targetValue = -100f,
                animationSpec = infiniteRepeatable(
                    animation = tween(2000, delayMillis = index * 600, easing = LinearEasing),
                    repeatMode = RepeatMode.Restart
                ),
                label = "y"
            )
            val xOffset by infiniteTransition.animateFloat(
                initialValue = 0f,
                targetValue = 20f,
                animationSpec = infiniteRepeatable(
                    animation = tween(1000, easing = LinearEasing),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "x"
            )
             val alpha by infiniteTransition.animateFloat(
                initialValue = 1f,
                targetValue = 0f,
                animationSpec = infiniteRepeatable(
                    animation = tween(2000, delayMillis = index * 600),
                    repeatMode = RepeatMode.Restart
                ),
                label = "alpha"
            )

            if (alpha > 0) {
                Text(
                    text = "Z",
                    color = Color.Blue.copy(alpha = alpha),
                    fontSize = (20 + index * 5).sp,
                    modifier = Modifier
                        .offset(x = 40.dp + xOffset.dp, y = (-20).dp + yOffset.dp)
                )
            }
        }
    }
}
