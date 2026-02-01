package uz.shs.video_player.models

/**
 * Represents the current playback state of the video player.
 * Extracted from VideoPlayerActivity to improve code organization.
 */
enum class PlaybackState {
    /** Video is actively playing */
    PLAYING,

    /** Video is paused */
    PAUSED,

    /** Video is buffering/loading */
    BUFFERING,

    /** Player is idle (not initialized or stopped) */
    IDLE
}
