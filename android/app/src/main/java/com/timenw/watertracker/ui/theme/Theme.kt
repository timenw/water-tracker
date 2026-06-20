package com.timenw.watertracker.ui.theme

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val WaterBlue = Color(0xFF1A73E8)
val WaterBlueLight = Color(0xFF4DA3FF)
val WaterBlueDark = Color(0xFF0D47A1)
val AccentCyan = Color(0xFF00BCD4)
val AccentGreen = Color(0xFF4CAF50)
val AccentOrange = Color(0xFFFF9800)
val AccentRed = Color(0xFFF44336)
val SurfaceLight = Color(0xFFF8F9FA)
val OnSurfaceLight = Color(0xFF1C1B1F)

private val LightColorScheme = lightColorScheme(
    primary = WaterBlue,
    onPrimary = Color.White,
    primaryContainer = WaterBlueLight,
    onPrimaryContainer = Color.White,
    secondary = AccentCyan,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFB2EBF2),
    onSecondaryContainer = Color(0xFF00363D),
    tertiary = AccentGreen,
    onTertiary = Color.White,
    background = SurfaceLight,
    onBackground = OnSurfaceLight,
    surface = Color.White,
    onSurface = OnSurfaceLight,
    surfaceVariant = Color(0xFFE7E0EC),
    onSurfaceVariant = Color(0xFF49454F),
    error = AccentRed,
    onError = Color.White,
)

@Composable
fun WaterTrackerTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColorScheme,
        typography = Typography(),
        content = content
    )
}
