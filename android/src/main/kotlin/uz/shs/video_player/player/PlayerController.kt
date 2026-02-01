package uz.shs.video_player.player

import android.content.Context
import androidx.core.net.toUri
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.hls.HlsMediaSource
import uz.shs.video_player.delegates.PlayerControllerDelegate
import uz.shs.video_player.models.PlaybackState
import uz.shs.video_player.models.QualityOption

/**
 * PlayerController manages ExoPlayer lifecycle and playback operations.
 *
 * Extracted from VideoPlayerActivity to improve separation of concerns
 * and follow the iOS component-based architecture pattern.
 *
 * Responsibilities:
 * - ExoPlayer initialization and cleanup
 * - Media source creation (HLS)
 * - Play/pause/seek operations
 * - Playback state management
 * - Video quality track extraction
 *
 * @param context Android context for ExoPlayer creation
 * @param delegate Callback interface for communicating events back to host
 */
@UnstableApi
class PlayerController(
    private val context: Context,
    private val delegate: PlayerControllerDelegate?
) {

    private var player: ExoPlayer? = null
    private val playerListener = createPlayerListener()

    /**
     * Initialize the player with a video URL and optional starting position.
     *
     * @param url Video URL (HLS stream)
     * @param lastPositionSeconds Starting position in seconds
     */
    fun initialize(url: String, lastPositionSeconds: Long) {
        // Create data source factory for network streams
        val dataSourceFactory: DataSource.Factory = DefaultHttpDataSource.Factory()

        // Create HLS media source
        val hlsMediaSource: HlsMediaSource = HlsMediaSource.Factory(dataSourceFactory)
            .createMediaSource(MediaItem.fromUri(url.toUri()))

        // Initialize ExoPlayer
        player = ExoPlayer.Builder(context).build().apply {
            setMediaSource(hlsMediaSource)
            seekTo(lastPositionSeconds * 1000) // Convert seconds to milliseconds
            prepare()
            addListener(playerListener)
            playWhenReady = true
        }

        delegate?.onPlayerReady()
    }

    /**
     * Attach player to a PlayerView for rendering.
     *
     * @param playerView The ExoPlayer PlayerView component
     */
    fun attachToView(playerView: androidx.media3.ui.PlayerView) {
        playerView.player = player
        playerView.keepScreenOn = true
        playerView.useController = true
    }

    /**
     * Start or resume playback.
     */
    fun play() {
        player?.play()
    }

    /**
     * Pause playback.
     */
    fun pause() {
        player?.pause()
    }

    /**
     * Seek to a specific position.
     *
     * @param positionMs Position in milliseconds
     */
    fun seekTo(positionMs: Long) {
        player?.seekTo(positionMs)
    }

    /**
     * Seek forward by specified increment.
     *
     * @param incrementMs Milliseconds to seek forward (default 10 seconds)
     */
    fun seekForward(incrementMs: Long = 10000) {
        player?.let {
            val newPosition = it.currentPosition + incrementMs
            it.seekTo(newPosition.coerceAtMost(it.duration))
        }
    }

    /**
     * Seek backward by specified increment.
     *
     * @param incrementMs Milliseconds to seek backward (default 10 seconds)
     */
    fun seekBackward(incrementMs: Long = 10000) {
        player?.let {
            val newPosition = it.currentPosition - incrementMs
            it.seekTo(newPosition.coerceAtLeast(0))
        }
    }

    /**
     * Get current playback position.
     *
     * @return Current position in milliseconds
     */
    fun getCurrentPosition(): Long = player?.currentPosition ?: 0

    /**
     * Get total duration of the video.
     *
     * @return Duration in milliseconds
     */
    fun getDuration(): Long = player?.duration ?: 0

    /**
     * Check if video is currently playing.
     *
     * @return True if playing, false otherwise
     */
    fun isPlaying(): Boolean = player?.isPlaying ?: false

    /**
     * Get the underlying ExoPlayer instance.
     * Useful for advanced operations not exposed by this controller.
     *
     * @return ExoPlayer instance or null if not initialized
     */
    fun getPlayer(): ExoPlayer? = player

    /**
     * Release all player resources.
     * MUST be called when the player is no longer needed to prevent memory leaks.
     */
    fun release() {
        player?.let {
            it.removeListener(playerListener)
            it.stop()
            it.clearVideoSurface()
            it.release()
        }
        player = null
    }

    /**
     * Create the player event listener for delegating callbacks.
     */
    private fun createPlayerListener() = object : Player.Listener {
        override fun onPlayerError(error: PlaybackException) {
            delegate?.onPlayerError(error)
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            delegate?.onIsPlayingChanged(isPlaying)
        }

        override fun onPlaybackStateChanged(playbackState: Int) {
            val state = when (playbackState) {
                Player.STATE_BUFFERING -> PlaybackState.BUFFERING
                Player.STATE_READY -> if (player?.isPlaying == true) {
                    PlaybackState.PLAYING
                } else {
                    PlaybackState.PAUSED
                }

                Player.STATE_ENDED -> {
                    delegate?.onPlaybackEnded()
                    PlaybackState.IDLE
                }

                Player.STATE_IDLE -> PlaybackState.IDLE
                else -> PlaybackState.IDLE
            }

            delegate?.onPlaybackStateChanged(state)
        }

        override fun onTracksChanged(tracks: Tracks) {
            super.onTracksChanged(tracks)
            val qualities = extractQualityOptions(tracks)
            delegate?.onTracksChanged(qualities)
        }
    }

    /**
     * Extract available video quality options from ExoPlayer tracks.
     *
     * @param tracks ExoPlayer tracks information
     * @return List of quality options sorted by height (descending)
     */
    private fun extractQualityOptions(tracks: Tracks): List<QualityOption> {
        val videoTracks = mutableListOf<QualityOption>()

        tracks.groups.forEachIndexed { groupIndex, group ->
            if (group.type == C.TRACK_TYPE_VIDEO) {
                for (trackIndex in 0 until group.length) {
                    val format = group.getTrackFormat(trackIndex)
                    if (format.height > 0) {
                        videoTracks.add(
                            QualityOption(
                                displayName = "${format.height}p",
                                height = format.height,
                                width = format.width,
                                bitrate = format.bitrate,
                                groupIndex = groupIndex,
                                trackIndex = trackIndex
                            )
                        )
                    }
                }
            }
        }

        // Sort by height descending (highest quality first)
        return videoTracks.sortedByDescending { it.height }.distinctBy { it.height }
    }
}
