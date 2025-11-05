package uz.shs.video_player

import android.annotation.SuppressLint
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import androidx.media3.common.C
import androidx.media3.common.MediaItem
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
import androidx.core.net.toUri

class VideoPlayerView internal constructor(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Any?
) :
    PlatformView, MethodCallHandler, Player.Listener {
    private var playerView: PlayerView
    private var player: ExoPlayer
    private val methodChannel: MethodChannel
    private val handler = Handler(Looper.getMainLooper())
    private var positionUpdateRunnable: Runnable? = null
    private var containerView: FrameLayout
    private var layoutListener: ViewTreeObserver.OnGlobalLayoutListener? = null
    
    override fun getView(): View {
        return containerView
    }

    init {
        // Init ExoPlayer
        player = ExoPlayer.Builder(context).build()
        player.addListener(this)
        playerView = PlayerView(context)
        // Set layout params
        playerView.layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        // Set player to view immediately
        playerView.player = player
        playerView.useController = false
        playerView.keepScreenOn = true
        
        // Wrap PlayerView in container to handle size changes
        containerView = FrameLayout(context)
        containerView.layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        containerView.addView(playerView)
        
        // Add layout listener to handle orientation changes
        setupLayoutListener()
        
        methodChannel = MethodChannel(messenger, "plugins.video/video_player_view_$id")
        // Init methodCall Listener
        methodChannel.setMethodCallHandler(this)
        
        // Load video from creation params if provided
        if (creationParams is Map<*, *>) {
            loadFromCreationParams(creationParams)
        }
    }
    
    private fun setupLayoutListener() {
        layoutListener = ViewTreeObserver.OnGlobalLayoutListener {
            // Force layout update when size changes (e.g., orientation change)
            playerView.requestLayout()
            playerView.invalidate()
        }
        containerView.viewTreeObserver.addOnGlobalLayoutListener(layoutListener)
    }
    
    @SuppressLint("UnsafeOptInUsageError")
    private fun loadFromCreationParams(params: Map<*, *>) {
        val viewModel = VideoViewModel(params)
        val url = viewModel.getUrl()
        val resizeMode = viewModel.getResizeMode()
        
        if (url.isNotEmpty()) {
            playerView.resizeMode = resizeMode
            
            // Determine if it's HTTP URL or asset
            val uri = if (url.contains("http")) {
                url.toUri()
            } else {
                "asset:///flutter_assets/$url".toUri()
            }
            
            val dataSourceFactory: DataSource.Factory = DefaultDataSource.Factory(playerView.context)
            val mediaSource: MediaSource = if (url.contains("http")) {
                HlsMediaSource.Factory(dataSourceFactory)
                    .createMediaSource(MediaItem.fromUri(uri))
            } else {
                ProgressiveMediaSource.Factory(dataSourceFactory)
                    .createMediaSource(MediaItem.fromUri(uri))
            }
            
            player.setMediaSource(mediaSource)
            player.prepare()
            player.playWhenReady = true
        }
    }

    override fun onMethodCall(methodCall: MethodCall, result: MethodChannel.Result) {
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
        player.pause()
        result.success(null)
    }

    private fun play(result: MethodChannel.Result) {
        player.play()
        result.success(null)
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun mute(result: MethodChannel.Result) {
        player.volume = 0f
        result.success(null)
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun unmute(result: MethodChannel.Result) {
        player.volume = 1f
        result.success(null)
    }

    // set and load new Url
    @SuppressLint("UnsafeOptInUsageError")
    private fun setUrl(methodCall: MethodCall, result: MethodChannel.Result) {
        val args = VideoViewModel(methodCall.arguments as Map<*, *>)
        val dataSourceFactory: DataSource.Factory = DefaultDataSource.Factory(playerView.context)
        val hlsMediaSource: HlsMediaSource = HlsMediaSource.Factory(dataSourceFactory)
            .createMediaSource(MediaItem.fromUri(args.getUrl()))
        playerView.player = player
        playerView.keepScreenOn = true
        playerView.useController = false
        playerView.resizeMode = args.getResizeMode()
        player.setMediaSource(hlsMediaSource)
        player.prepare()
        player.playWhenReady = true
        // Duration will be sent automatically when player becomes ready (via onPlaybackStateChanged)
        result.success(null)
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun setAssets(methodCall: MethodCall, result: MethodChannel.Result) {
        val args = VideoViewModel(methodCall.arguments as Map<*, *>)
        val uri = "asset:///flutter_assets/${args.getUrl()}".toUri()
        val dataSourceFactory: DataSource.Factory = DefaultDataSource.Factory(playerView.context)
        val mediaSource: MediaSource = ProgressiveMediaSource.Factory(dataSourceFactory)
            .createMediaSource(MediaItem.fromUri(uri))
        playerView.player = player
        playerView.keepScreenOn = true
        playerView.useController = false
        playerView.resizeMode = args.getResizeMode()
        player.setMediaSource(mediaSource)
        player.prepare()
        player.playWhenReady = true
        // Duration will be sent automatically when player becomes ready (via onPlaybackStateChanged)
        result.success(null)
    }

    private fun getDuration(result: MethodChannel.Result) {
        val durationMs = player.duration
        if (durationMs != C.TIME_UNSET && durationMs > 0) {
            // Convert milliseconds to seconds
            val durationSeconds = durationMs / 1000.0
            result.success(durationSeconds)
        } else {
            result.success(0.0)
        }
    }

    private fun seekTo(methodCall: MethodCall, result: MethodChannel.Result) {
        val args = methodCall.arguments as? Map<*, *>
        val seconds = args?.get("seconds") as? Double
        if (seconds != null) {
            // Convert seconds to milliseconds
            val positionMs = (seconds * 1000).toLong()
            player.seekTo(positionMs)
            result.success(null)
        } else {
            result.error("INVALID_ARGUMENT", "seconds parameter is required", null)
        }
    }

    private fun startPositionUpdates() {
        stopPositionUpdates()
        positionUpdateRunnable = object : Runnable {
            override fun run() {
                try {
                    val positionMs = player.currentPosition
                    if (positionMs != C.TIME_UNSET && positionMs >= 0) {
                        // Convert milliseconds to seconds
                        val positionSeconds = positionMs / 1000.0
                        // Ensure we're on main thread for method channel
                        handler.post {
                            methodChannel.invokeMethod("positionUpdate", positionSeconds, null)
                        }
                    }
                } catch (e: Exception) {
                    // Ignore errors, continue updates
                }
                // Schedule next update (1 second interval)
                handler.postDelayed(this, 1000)
            }
        }
        handler.post(positionUpdateRunnable!!)
    }

    private fun stopPositionUpdates() {
        positionUpdateRunnable?.let {
            handler.removeCallbacks(it)
            positionUpdateRunnable = null
        }
    }

    // Player.Listener implementation
    override fun onPlaybackStateChanged(playbackState: Int) {
        when (playbackState) {
            Player.STATE_READY -> {
                // Start position updates when player is ready
                startPositionUpdates()
                // Send duration ready event when available
                handler.post {
                    val durationMs = player.duration
                    if (durationMs != C.TIME_UNSET && durationMs > 0) {
                        val durationSeconds = durationMs / 1000.0
                        methodChannel.invokeMethod("durationReady", durationSeconds, null)
                    }
                }
            }
            Player.STATE_ENDED, Player.STATE_IDLE -> {
                stopPositionUpdates()
            }
        }
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        // No action needed for position updates
    }

    override fun dispose() {
        // Remove layout listener
        layoutListener?.let {
            containerView.viewTreeObserver.removeOnGlobalLayoutListener(it)
            layoutListener = null
        }
        
        stopPositionUpdates()
        player.removeListener(this)
        player.pause()
        player.release()
    }
}