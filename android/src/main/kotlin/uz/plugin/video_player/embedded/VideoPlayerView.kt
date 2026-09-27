package uz.plugin.video_player.embedded

import android.content.Context
import android.view.View
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView
import uz.plugin.video_player.models.VideoViewModel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Embedded player platform view. Maps the per-view channel
 * `plugins.video/video_player_view_<id>` onto [EmbeddedPlayerController]:
 * commands in via [onMethodCall], events out via [EmbeddedPlayerController.Listener].
 * Follows the host activity: paused while it is stopped, resumed if it was playing.
 */
class VideoPlayerView internal constructor(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Any?,
    private val hostLifecycle: Lifecycle?,
) : PlatformView, MethodCallHandler, EmbeddedPlayerController.Listener, DefaultLifecycleObserver {

    private val isDisposed = AtomicBoolean(false)
    private var methodChannel: MethodChannel? = MethodChannel(messenger, "plugins.video/video_player_view_$id")
    private val controller = EmbeddedPlayerController(context, this)

    init {
        methodChannel?.setMethodCallHandler(this)
        hostLifecycle?.addObserver(this)
        if (creationParams is Map<*, *>) {
            loadFromCreationParams(VideoViewModel(creationParams))
        }
    }

    override fun getView(): View? = if (isDisposed.get()) null else controller.view

    private fun loadFromCreationParams(params: VideoViewModel) {
        val url = params.getUrl()
        when {
            url.isEmpty() -> Unit
            url.startsWith("http://") || url.startsWith("https://") ->
                controller.loadUrl(url, params.getKeyRequestHeaders(), params.getResizeMode())
            else -> controller.loadAsset(url, params.getResizeMode())
        }
    }

    // MARK: - Commands (Dart → native)

    override fun onMethodCall(methodCall: MethodCall, result: MethodChannel.Result) {
        if (isDisposed.get()) {
            result.error("DISPOSED", "VideoPlayerView already disposed", null)
            return
        }
        when (methodCall.method) {
            "setUrl" -> respond(result, "SET_URL_ERROR", "Failed to set URL") {
                val args = VideoViewModel(methodCall.arguments as Map<*, *>)
                if (args.getUrl().isEmpty()) {
                    result.error("INVALID_URL", "URL cannot be empty", null)
                    return@respond
                }
                controller.loadUrl(args.getUrl(), args.getKeyRequestHeaders(), args.getResizeMode())
                result.success(null)
            }
            "setAssets" -> respond(result, "SET_ASSETS_ERROR", "Failed to set asset") {
                val args = VideoViewModel(methodCall.arguments as Map<*, *>)
                if (args.getUrl().isEmpty()) {
                    result.error("INVALID_ASSET", "Asset path cannot be empty", null)
                    return@respond
                }
                controller.loadAsset(args.getUrl(), args.getResizeMode())
                result.success(null)
            }
            "play" -> respond(result, "PLAY_ERROR", "Failed to play") {
                controller.play()
                result.success(null)
            }
            "pause" -> respond(result, "PAUSE_ERROR", "Failed to pause") {
                controller.pause()
                result.success(null)
            }
            "mute" -> respond(result, "MUTE_ERROR", "Failed to mute") {
                controller.setMuted(true)
                result.success(null)
            }
            "unmute" -> respond(result, "UNMUTE_ERROR", "Failed to unmute") {
                controller.setMuted(false)
                result.success(null)
            }
            "getDuration" -> respond(result, "GET_DURATION_ERROR", "Failed to get duration") {
                result.success(controller.durationSeconds())
            }
            "seekTo" -> respond(result, "SEEK_ERROR", "Failed to seek") {
                val seconds = (methodCall.arguments as? Map<*, *>)?.get("seconds") as? Double
                if (seconds == null || seconds < 0) {
                    result.error("INVALID_ARGUMENT", "seconds parameter required", null)
                    return@respond
                }
                controller.seekTo(seconds)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Runs [block], which must answer [result]; an exception becomes `errorCode`. */
    private inline fun respond(result: MethodChannel.Result, errorCode: String, message: String, block: () -> Unit) {
        try {
            block()
        } catch (e: Exception) {
            result.error(errorCode, "$message: ${e.message}", null)
        }
    }

    // MARK: - Events (native → Dart)

    override fun onStatus(status: String) = send("playerStatus", status)

    override fun onPosition(seconds: Double) = send("positionUpdate", seconds)

    override fun onDurationReady(seconds: Double) = send("durationReady", seconds)

    override fun onFinished() = send("finished", null)

    private fun send(method: String, arguments: Any?) {
        if (isDisposed.get()) return
        try {
            methodChannel?.invokeMethod(method, arguments, null)
        } catch (_: Exception) {
            // Channel disposed, ignore
        }
    }

    // MARK: - Host lifecycle

    override fun onStop(owner: LifecycleOwner) = controller.onHostStopped()

    override fun onStart(owner: LifecycleOwner) = controller.onHostStarted()

    override fun dispose() {
        if (!isDisposed.compareAndSet(false, true)) return
        hostLifecycle?.removeObserver(this)
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        controller.release()
    }
}
