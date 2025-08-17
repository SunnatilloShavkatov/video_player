package uz.shs.video_player

import android.annotation.SuppressLint
import android.content.Context
import android.view.View
import androidx.media3.common.MediaItem
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
    id: Int
) :
    PlatformView, MethodCallHandler {
    private var playerView: PlayerView
    private var player: ExoPlayer
    private val methodChannel: MethodChannel
    override fun getView(): View {
        return playerView
    }

    init {
        // Init WebView
        player = ExoPlayer.Builder(context).build()
        playerView = PlayerView(context)
        methodChannel = MethodChannel(messenger, "plugins.video/video_player_view_$id")
        // Init methodCall Listener
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(methodCall: MethodCall, result: MethodChannel.Result) {
        when (methodCall.method) {
            "setUrl" -> setUrl(methodCall, result)
            "setAssets" -> setAssets(methodCall, result)
            "pause" -> pause(methodCall, result)
            "play" -> play(methodCall, result)
            "mute" -> mute(methodCall, result)
            "unmute" -> unmute(methodCall, result)
            else -> result.notImplemented()
        }
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun pause(methodCall: MethodCall, result: MethodChannel.Result) {
        player.pause()
        result.success(null)
    }

    private fun play(methodCall: MethodCall, result: MethodChannel.Result) {
        player.play()
        result.success(null)
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun mute(methodCall: MethodCall, result: MethodChannel.Result) {
        player.volume = 0f
        result.success(null)
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun unmute(methodCall: MethodCall, result: MethodChannel.Result) {
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
        result.success(null)
    }

    override fun dispose() {
        player.pause()
        player.release()
    }
}