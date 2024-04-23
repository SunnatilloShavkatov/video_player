package uz.shs.video_player

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
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
        methodChannel = MethodChannel(messenger, "plugins.udevs/video_player_view_$id")
        // Init methodCall Listener
        methodChannel.setMethodCallHandler(this)
    }

    override fun onMethodCall(methodCall: MethodCall, result: MethodChannel.Result) {
        when (methodCall.method) {
            "setUrl" -> setUrl(methodCall, result)
            "setAssets" -> setAssets(methodCall, result)
            else -> result.notImplemented()
        }
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
        val uri = Uri.parse("asset:///flutter_assets/${args.getUrl()}")
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