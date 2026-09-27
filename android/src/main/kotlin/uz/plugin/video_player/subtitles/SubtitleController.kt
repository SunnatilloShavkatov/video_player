package uz.plugin.video_player.subtitles

import android.content.Context
import androidx.core.content.edit
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.PlayerView
import androidx.media3.ui.SubtitleView
import uz.plugin.video_player.models.PlayerConfiguration
import uz.plugin.video_player.player.PlayerController

/**
 * Sidecar subtitle state for the full-screen player: selected track, on/off and
 * font size, persisted across sessions and applied to Media3's [SubtitleView].
 */
@UnstableApi
class SubtitleController(
    context: Context,
    private val playerView: PlayerView,
    private val config: PlayerConfiguration,
    private val controller: () -> PlayerController?,
) {
    companion object {
        val SIZE_OPTIONS = listOf("50%", "75%", "100%", "150%", "200%", "300%")

        private const val PREFS_NAME = "video_player_prefs"
        private const val KEY_ENABLED = "video_player_subtitles_enabled"
        private const val KEY_LANG = "video_player_subtitle_lang"
        private const val KEY_FONT_SIZE = "video_player_subtitle_font_size"
        private const val BOTTOM_MARGIN_DP = 8f
    }

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val density = context.resources.displayMetrics.density

    private var isEnabled = true
    private var currentLabel = config.subtitleOffText
    var sizePercent = 100
        private set

    val hasTracks: Boolean get() = config.subtitles.isNotEmpty()

    /** Track options for the picker; index 0 is "off". */
    val trackOptions: List<String> get() = listOf(config.subtitleOffText) + config.subtitles.map { it.label }

    /** Label for the settings row: the active track, or the "off" text. */
    val selectionLabel: String get() = if (isEnabled) currentLabel else config.subtitleOffText

    /** Restore the saved selection once the player exists. */
    fun restore() {
        val subtitles = config.subtitles
        if (subtitles.isEmpty()) return

        isEnabled = prefs.getBoolean(KEY_ENABLED, true)
        val savedLang = prefs.getString(KEY_LANG, null)
        val track = subtitles.firstOrNull { it.lang == savedLang }
            ?: subtitles.firstOrNull { it.isDefault }
            ?: subtitles.first()
        currentLabel = if (isEnabled) track.label else config.subtitleOffText

        applyBottomMargin()
        applySize(prefs.getInt(KEY_FONT_SIZE, 100))
        controller()?.setSubtitlesEnabled(isEnabled)
        if (isEnabled) {
            controller()?.selectSubtitleLanguage(track.lang)
        }
    }

    /** Select an entry from [trackOptions]; 0 turns subtitles off. */
    fun selectTrack(index: Int) {
        if (index == 0) {
            isEnabled = false
            currentLabel = config.subtitleOffText
            prefs.edit { putBoolean(KEY_ENABLED, false) }
            controller()?.setSubtitlesEnabled(false)
            return
        }
        val track = config.subtitles[index - 1]
        isEnabled = true
        currentLabel = track.label
        prefs.edit {
            putBoolean(KEY_ENABLED, true)
            putString(KEY_LANG, track.lang)
        }
        controller()?.setSubtitlesEnabled(true)
        controller()?.selectSubtitleLanguage(track.lang)
    }

    fun setSizePercent(percent: Int) {
        prefs.edit { putInt(KEY_FONT_SIZE, percent) }
        applySize(percent)
    }

    private fun applySize(percent: Int) {
        sizePercent = percent
        playerView.subtitleView?.setFractionalTextSize(SubtitleView.DEFAULT_TEXT_SIZE_FRACTION * (percent / 100f))
    }

    /**
     * Media3 places cues a fraction of the view height above the bottom by default.
     * Pin them to a fixed 8dp above the bottom of the video frame instead, matching iOS.
     */
    private fun applyBottomMargin() {
        playerView.subtitleView?.apply {
            setBottomPaddingFraction(0f)
            setPadding(0, 0, 0, (BOTTOM_MARGIN_DP * density).toInt())
        }
    }
}
