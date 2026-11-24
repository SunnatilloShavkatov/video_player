package uz.plugin.video_player.player

/**
 * Brightness swipe levels `0..max`, read from the system setting (`0..255`) or from the window's own
 * `screenBrightness` (`0f..1f`, negative while the window follows the system). Pure Kotlin for JVM tests.
 */
internal object BrightnessLevel {
    const val SYSTEM_MAX = 255

    fun fromSystem(value: Int, max: Int): Double = value.coerceIn(0, SYSTEM_MAX).toDouble() * max / SYSTEM_MAX

    fun fromWindow(value: Float, max: Int): Double? =
        if (value < 0f) null else value.coerceAtMost(1f).toDouble() * max

    fun step(level: Double, max: Int): Int = level.toInt().coerceIn(0, max)
}
