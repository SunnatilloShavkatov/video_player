package uz.shs.video_player.models

/**
 * Represents a video quality option available for playback.
 * Extracted from VideoPlayerActivity.QualityOption data class.
 *
 * @property displayName Human-readable quality name (e.g., "1080p", "Auto")
 * @property height Video height in pixels (-1 for auto)
 * @property width Video width in pixels (-1 for auto)
 * @property bitrate Video bitrate (-1 for auto)
 * @property groupIndex ExoPlayer track group index (-1 for auto)
 * @property trackIndex ExoPlayer track index within group (-1 for auto)
 */
data class QualityOption(
    val displayName: String,
    val height: Int,
    val width: Int,
    val bitrate: Int,
    val groupIndex: Int,
    val trackIndex: Int
)
