package uz.plugin.video_player.embedded

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import androidx.core.net.toUri
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.ui.PlayerView
import uz.plugin.video_player.player.hlsMediaSourceFactory

/**
 * Embedded (inline) player: owns the ExoPlayer, its view and position polling.
 * Knows nothing about Flutter — events go to [Listener], and [VideoPlayerView]
 * maps them onto the per-view method channel. All time values are seconds.
 */
@SuppressLint("UnsafeOptInUsageError")
class EmbeddedPlayerController(context: Context, private val listener: Listener) : Player.Listener {

    interface Listener {
        /** One of "idle", "buffering", "ready", "ended", "playing", "paused", "error". */
        fun onStatus(status: String)
        fun onPosition(seconds: Double)
        fun onDurationReady(seconds: Double)
        fun onFinished()
    }

    private companion object {
        const val POSITION_INTERVAL_MS = 1000L
    }

    private val player = ExoPlayer.Builder(context).build()
    private val playerView = PlayerView(context).apply {
        layoutParams = FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        player = this@EmbeddedPlayerController.player
        useController = false
        keepScreenOn = true
    }
    private val container = FrameLayout(context).apply {
        layoutParams = FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        addView(playerView)
    }
    private val handler = Handler(Looper.getMainLooper())
    private var isReleased = false

    // Platform views can be resized without the PlayerView re-measuring; nudge it.
    private var lastWidth = 0
    private var lastHeight = 0
    private val layoutListener = ViewTreeObserver.OnGlobalLayoutListener {
        if (isReleased) return@OnGlobalLayoutListener
        if (container.width != lastWidth || container.height != lastHeight) {
            lastWidth = container.width
            lastHeight = container.height
            runCatching { playerView.requestLayout() }
        }
    }

    private val positionTicker = object : Runnable {
        override fun run() {
            if (isReleased) return
            reportPosition()
            handler.postDelayed(this, POSITION_INTERVAL_MS)
        }
    }

    val view: View get() = container

    init {
        player.addListener(this)
        container.viewTreeObserver.addOnGlobalLayoutListener(layoutListener)
    }

    // MARK: - Loading

    /** Remote or raw URI. HLS (".m3u8" / "hls" in the URL) sends [keyHeaders] with AES-128 key requests. */
    fun loadUrl(url: String, keyHeaders: Map<String, String>, resizeMode: Int) {
        val isHls = url.contains(".m3u8") || url.contains("hls", ignoreCase = true)
        val mediaSource = if (isHls) {
            hlsMediaSourceFactory(DefaultDataSource.Factory(container.context), keyHeaders)
                .createMediaSource(MediaItem.fromUri(url.toUri()))
        } else {
            progressiveSource(url.toUri())
        }
        load(mediaSource, resizeMode)
    }

    /** Flutter asset path, e.g. "assets/video.mp4". */
    fun loadAsset(path: String, resizeMode: Int) {
        load(progressiveSource("asset:///flutter_assets/$path".toUri()), resizeMode)
    }

    private fun progressiveSource(uri: Uri): MediaSource =
        ProgressiveMediaSource.Factory(DefaultDataSource.Factory(container.context))
            .createMediaSource(MediaItem.fromUri(uri))

    private fun load(mediaSource: MediaSource, resizeMode: Int) {
        if (isReleased) return
        playerView.resizeMode = resizeMode
        player.setMediaSource(mediaSource)
        player.prepare()
        player.playWhenReady = true
    }

    // MARK: - Commands

    fun play() = player.play()

    fun pause() = player.pause()

    fun setMuted(muted: Boolean) {
        player.volume = if (muted) 0f else 1f
    }

    fun seekTo(seconds: Double) = player.seekTo((seconds * 1000).toLong())

    /** Duration in seconds, or 0.0 while unknown. */
    fun durationSeconds(): Double {
        val durationMs = player.duration
        return if (durationMs != C.TIME_UNSET && durationMs > 0) durationMs / 1000.0 else 0.0
    }

    // MARK: - Position

    private fun startPositionUpdates() {
        stopPositionUpdates()
        handler.post(positionTicker)
    }

    private fun stopPositionUpdates() {
        handler.removeCallbacks(positionTicker)
    }

    private fun reportPosition() {
        val positionMs = player.currentPosition
        if (positionMs != C.TIME_UNSET && positionMs >= 0) {
            listener.onPosition(positionMs / 1000.0)
        }
    }

    // MARK: - Player.Listener

    override fun onPlaybackStateChanged(playbackState: Int) {
        if (isReleased) return
        val status = when (playbackState) {
            Player.STATE_IDLE -> {
                stopPositionUpdates()
                "idle"
            }
            Player.STATE_BUFFERING -> "buffering"
            Player.STATE_READY -> {
                // Polling is driven by onIsPlayingChanged; report the current position once
                if (!player.isPlaying) reportPosition()
                durationSeconds().takeIf { it > 0 }?.let(listener::onDurationReady)
                "ready"
            }
            Player.STATE_ENDED -> {
                stopPositionUpdates()
                listener.onFinished()
                "ended"
            }
            else -> return
        }
        listener.onStatus(status)
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        if (isReleased) return
        // Poll position only while actually playing; stop when paused or buffering
        if (isPlaying) {
            startPositionUpdates()
        } else {
            stopPositionUpdates()
            reportPosition()
        }
        listener.onStatus(if (isPlaying) "playing" else "paused")
    }

    override fun onPositionDiscontinuity(
        oldPosition: Player.PositionInfo,
        newPosition: Player.PositionInfo,
        reason: Int,
    ) {
        // While playing, the next poll tick reports the new position
        if (!isReleased && !player.isPlaying) reportPosition()
    }

    override fun onPlayerError(error: PlaybackException) {
        if (!isReleased) listener.onStatus("error")
    }

    // MARK: - Release

    /** Order matters: listeners first, then surface, then the player (EGLSurfaceTexture fix). */
    fun release() {
        if (isReleased) return
        isReleased = true
        stopPositionUpdates()
        handler.removeCallbacksAndMessages(null)
        player.removeListener(this)
        container.viewTreeObserver.removeOnGlobalLayoutListener(layoutListener)
        runCatching { player.stop() }
        player.clearVideoSurface()
        playerView.player = null
        runCatching { player.release() }
    }
}
