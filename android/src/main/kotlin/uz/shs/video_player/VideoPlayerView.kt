package uz.shs.video_player

import android.annotation.SuppressLint
import android.content.Context
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
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView
import uz.shs.video_player.models.VideoViewModel
import java.lang.ref.WeakReference
import java.util.concurrent.atomic.AtomicBoolean

class VideoPlayerView internal constructor(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Any?
) : PlatformView, MethodCallHandler, Player.Listener {

    private var playerView: PlayerView? = null
    private var player: ExoPlayer? = null
    private var methodChannel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())

    // ✅ FIXED: WeakReference to prevent leak
    private var positionUpdateRunnable: PositionUpdateRunnable? = null
    private var containerView: FrameLayout? = null
    private var layoutListener: ViewTreeObserver.OnGlobalLayoutListener? = null

    // ✅ FIXED: Atomic flag for thread-safe disposal
    private val isDisposed = AtomicBoolean(false)

    // Layout tracking
    private var lastWidth: Int = 0
    private var lastHeight: Int = 0

    override fun getView(): View? {
        return containerView
    }

    init {
        // Init ExoPlayer
        player = ExoPlayer.Builder(context).build()
        player?.addListener(this)

        playerView = PlayerView(context)
        playerView?.layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        playerView?.player = player
        playerView?.useController = false
        playerView?.keepScreenOn = true

        containerView = FrameLayout(context)
        containerView?.layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        containerView?.addView(playerView)

        setupLayoutListener()

        methodChannel = MethodChannel(messenger, "plugins.video/video_player_view_$id")
        methodChannel?.setMethodCallHandler(this)

        if (creationParams is Map<*, *>) {
            loadFromCreationParams(creationParams)
        }
    }

    private fun setupLayoutListener() {
        layoutListener = ViewTreeObserver.OnGlobalLayoutListener {
            // ✅ FIXED: Check disposal before accessing views
            if (isDisposed.get()) return@OnGlobalLayoutListener

            val container = containerView ?: return@OnGlobalLayoutListener
            val pView = playerView ?: return@OnGlobalLayoutListener

            val currentWidth = container.width
            val currentHeight = container.height
            if (currentWidth != lastWidth || currentHeight != lastHeight) {
                lastWidth = currentWidth
                lastHeight = currentHeight

                // ✅ Safe requestLayout
                try {
                    pView.requestLayout()
                } catch (_: Exception) {
                    // View already disposed, ignore
                }
            }
        }
        containerView?.viewTreeObserver?.addOnGlobalLayoutListener(layoutListener)
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun loadFromCreationParams(params: Map<*, *>) {
        if (isDisposed.get()) return

        val viewModel = VideoViewModel(params)
        val url = viewModel.getUrl()
        val resizeMode = viewModel.getResizeMode()

        if (url.isNotEmpty()) {
            playerView?.resizeMode = resizeMode

            val uri = if (url.startsWith("http://") || url.startsWith("https://")) {
                url.toUri()
            } else {
                "asset:///flutter_assets/$url".toUri()
            }

            val pView = playerView ?: return
            val dataSourceFactory: DataSource.Factory = DefaultDataSource.Factory(pView.context)

            val mediaSource: MediaSource =
                if (url.startsWith("http://") || url.startsWith("https://")) {
                    if (url.contains(".m3u8") || url.contains("hls", ignoreCase = true)) {
                        HlsMediaSource.Factory(dataSourceFactory)
                            .createMediaSource(MediaItem.fromUri(uri))
                    } else {
                        ProgressiveMediaSource.Factory(dataSourceFactory)
                            .createMediaSource(MediaItem.fromUri(uri))
                    }
                } else {
                    ProgressiveMediaSource.Factory(dataSourceFactory)
                        .createMediaSource(MediaItem.fromUri(uri))
                }

            player?.setMediaSource(mediaSource)
            player?.prepare()
            player?.playWhenReady = true
        }
    }

    override fun onMethodCall(methodCall: MethodCall, result: MethodChannel.Result) {
        // ✅ FIXED: Guard all method calls
        if (isDisposed.get()) {
            result.error("DISPOSED", "VideoPlayerView already disposed", null)
            return
        }

        when (methodCall.method) {
            "setUrl" -> setUrl(methodCall, result)
            "setAssets" -> setAssets(methodCall, result)
            "pause" -> pause(result)
            "play" -> play(result)
            "mute" -> mute(result)
            "unmute" -> unmute(result)
            "getDuration" -> getDuration(result)
            "seekTo" -> seekTo(methodCall, result)
            else -> result.notImplemented()
        }
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun pause(result: MethodChannel.Result) {
        try {
            player?.pause()
            result.success(null)
        } catch (e: Exception) {
            result.error("PAUSE_ERROR", "Failed to pause: ${e.message}", null)
        }
    }

    private fun play(result: MethodChannel.Result) {
        try {
            player?.play()
            result.success(null)
        } catch (e: Exception) {
            result.error("PLAY_ERROR", "Failed to play: ${e.message}", null)
        }
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun mute(result: MethodChannel.Result) {
        try {
            player?.volume = 0f
            result.success(null)
        } catch (e: Exception) {
            result.error("MUTE_ERROR", "Failed to mute: ${e.message}", null)
        }
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun unmute(result: MethodChannel.Result) {
        try {
            player?.volume = 1f
            result.success(null)
        } catch (e: Exception) {
            result.error("UNMUTE_ERROR", "Failed to unmute: ${e.message}", null)
        }
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun configurePlayerViewAndLoadMedia(mediaSource: MediaSource, resizeMode: Int) {
        if (isDisposed.get()) return

        playerView?.player = player
        playerView?.keepScreenOn = true
        playerView?.useController = false
        playerView?.resizeMode = resizeMode
        player?.setMediaSource(mediaSource)
        player?.prepare()
        player?.playWhenReady = true
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun setUrl(methodCall: MethodCall, result: MethodChannel.Result) {
        try {
            if (isDisposed.get()) {
                result.error("DISPOSED", "View disposed", null)
                return
            }

            val args = VideoViewModel(methodCall.arguments as Map<*, *>)
            val url = args.getUrl()

            if (url.isEmpty()) {
                result.error("INVALID_URL", "URL cannot be empty", null)
                return
            }

            val pView = playerView ?: run {
                result.error("NO_VIEW", "PlayerView is null", null)
                return
            }

            val dataSourceFactory: DataSource.Factory = DefaultDataSource.Factory(pView.context)
            val uri = url.toUri()

            val mediaSource: MediaSource =
                if (url.contains(".m3u8") || url.contains("hls", ignoreCase = true)) {
                    HlsMediaSource.Factory(dataSourceFactory)
                        .createMediaSource(MediaItem.fromUri(uri))
                } else {
                    ProgressiveMediaSource.Factory(dataSourceFactory)
                        .createMediaSource(MediaItem.fromUri(uri))
                }

            configurePlayerViewAndLoadMedia(mediaSource, args.getResizeMode())
            result.success(null)
        } catch (e: Exception) {
            result.error("SET_URL_ERROR", "Failed to set URL: ${e.message}", null)
        }
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun setAssets(methodCall: MethodCall, result: MethodChannel.Result) {
        try {
            if (isDisposed.get()) {
                result.error("DISPOSED", "View disposed", null)
                return
            }

            val args = VideoViewModel(methodCall.arguments as Map<*, *>)
            val assetPath = args.getUrl()

            if (assetPath.isEmpty()) {
                result.error("INVALID_ASSET", "Asset path cannot be empty", null)
                return
            }

            val uri = "asset:///flutter_assets/$assetPath".toUri()
            val pView = playerView ?: run {
                result.error("NO_VIEW", "PlayerView is null", null)
                return
            }

            val dataSourceFactory: DataSource.Factory = DefaultDataSource.Factory(pView.context)
            val mediaSource: MediaSource = ProgressiveMediaSource.Factory(dataSourceFactory)
                .createMediaSource(MediaItem.fromUri(uri))
            configurePlayerViewAndLoadMedia(mediaSource, args.getResizeMode())
            result.success(null)
        } catch (e: Exception) {
            result.error("SET_ASSETS_ERROR", "Failed to set asset: ${e.message}", null)
        }
    }

    private fun getDuration(result: MethodChannel.Result) {
        try {
            val durationMs = player?.duration
            if (durationMs != null && durationMs != C.TIME_UNSET && durationMs > 0) {
                val durationSeconds = durationMs / 1000.0
                result.success(durationSeconds)
            } else {
                result.success(0.0)
            }
        } catch (e: Exception) {
            result.error("GET_DURATION_ERROR", "Failed to get duration: ${e.message}", null)
        }
    }

    private fun seekTo(methodCall: MethodCall, result: MethodChannel.Result) {
        try {
            val args = methodCall.arguments as? Map<*, *>
            val seconds = args?.get("seconds") as? Double
            if (seconds != null && seconds >= 0) {
                val positionMs = (seconds * 1000).toLong()
                player?.seekTo(positionMs)
                result.success(null)
            } else {
                result.error("INVALID_ARGUMENT", "seconds parameter required", null)
            }
        } catch (e: Exception) {
            result.error("SEEK_ERROR", "Failed to seek: ${e.message}", null)
        }
    }

    // ✅ FIXED: Non-leaking position update runnable
    private inner class PositionUpdateRunnable(
        private val playerRef: WeakReference<ExoPlayer>,
        private val channelRef: WeakReference<MethodChannel>
    ) : Runnable {
        override fun run() {
            // ✅ Check disposal FIRST
            if (isDisposed.get()) return

            val player = playerRef.get() ?: return
            val channel = channelRef.get() ?: return

            try {
                val positionMs = player.currentPosition
                if (positionMs != C.TIME_UNSET && positionMs >= 0) {
                    val positionSeconds = positionMs / 1000.0
                    channel.invokeMethod("positionUpdate", positionSeconds, null)
                }
            } catch (_: Exception) {
                // Stop on error
                return
            }

            // ✅ Re-schedule only if not disposed
            if (!isDisposed.get()) {
                handler.postDelayed(this, 1000)
            }
        }
    }

    private fun startPositionUpdates() {
        stopPositionUpdates()

        val p = player ?: return
        val ch = methodChannel ?: return

        // ✅ FIXED: Use weak references
        val runnable = PositionUpdateRunnable(
            WeakReference(p),
            WeakReference(ch)
        )
        positionUpdateRunnable = runnable
        handler.post(runnable)
    }

    private fun stopPositionUpdates() {
        positionUpdateRunnable?.let {
            handler.removeCallbacks(it)
            positionUpdateRunnable = null
        }
    }

    // Player.Listener implementation
    override fun onPlaybackStateChanged(playbackState: Int) {
        // ✅ FIXED: Guard disposal
        if (isDisposed.get()) return

        val status = when (playbackState) {
            Player.STATE_IDLE -> {
                stopPositionUpdates()
                "idle"
            }

            Player.STATE_BUFFERING -> "buffering"
            Player.STATE_READY -> {
                startPositionUpdates()

                // ✅ Safe duration notification
                val durationMs = player?.duration
                if (durationMs != null && durationMs != C.TIME_UNSET && durationMs > 0) {
                    val durationSeconds = durationMs / 1000.0
                    safeInvokeMethod("durationReady", durationSeconds)
                }
                "ready"
            }

            Player.STATE_ENDED -> {
                stopPositionUpdates()
                "ended"
            }

            else -> null
        }

        status?.let {
            safeInvokeMethod("playerStatus", it)
        }
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        if (isDisposed.get()) return

        val status = if (isPlaying) "playing" else "paused"
        safeInvokeMethod("playerStatus", status)
    }

    override fun onPlayerError(error: PlaybackException) {
        if (isDisposed.get()) return
        safeInvokeMethod("playerStatus", "error")
    }

    // ✅ FIXED: Safe method invocation
    private fun safeInvokeMethod(method: String, arguments: Any?) {
        if (isDisposed.get()) return

        try {
            methodChannel?.invokeMethod(method, arguments, null)
        } catch (_: Exception) {
            // Channel disposed, ignore
        }
    }

    // ✅ PRODUCTION-SAFE DISPOSAL
    override fun dispose() {
        // ✅ Atomic check-and-set to prevent double disposal
        if (!isDisposed.compareAndSet(false, true)) {
            return  // Already disposed
        }

        // CRITICAL ORDER:

        // 1. Stop position updates FIRST
        stopPositionUpdates()

        // 2. Remove ALL handler callbacks/messages
        handler.removeCallbacksAndMessages(null)

        // 3. Remove player listener BEFORE stopping
        player?.removeListener(this)

        // 4. Remove layout listener
        layoutListener?.let { listener ->
            containerView?.viewTreeObserver?.removeOnGlobalLayoutListener(listener)
            layoutListener = null
        }

        // 5. Clear method channel handler
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null

        // 6. Stop player
        player?.let { p ->
            try {
                p.stop()
            } catch (_: Exception) {
                // Ignore stop errors
            }
        }

        // 7. Clear video surface (CRITICAL for EGLSurfaceTexture fix)
        player?.clearVideoSurface()

        // 8. Detach player from view
        playerView?.player = null

        // 9. Release player (LAST)
        player?.let { p ->
            try {
                p.release()
            } catch (_: Exception) {
                // Ignore release errors
            }
        }
        player = null

        // 10. Clear views
        playerView = null
        containerView = null
    }
}
