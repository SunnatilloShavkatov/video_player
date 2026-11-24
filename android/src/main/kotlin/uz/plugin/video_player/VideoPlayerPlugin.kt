package uz.plugin.video_player

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import org.json.JSONException
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import uz.plugin.video_player.embedded.VideoPlayerViewFactory
import uz.plugin.video_player.fullscreen.VideoPlayerActivity
import uz.plugin.video_player.models.PlayerConfiguration
import uz.plugin.video_player.utils.KeyHeaderSessions

const val extraArgument = "uz.plugin.video_player.ARGUMENT"
const val extraKeyHeadersSession = "uz.plugin.video_player.KEY_HEADERS_SESSION"
// Distinctive codes (low 16 bits, as FragmentActivity requires) so other plugins' results are never mistaken for ours.
const val playerActivity = 0x5650
const val playerActivityFinish = 0x5651
const val playerActivitySessionLost = 0x5652

class VideoPlayerPlugin : FlutterPlugin, ActivityAware,
    PluginRegistry.NewIntentListener, PluginRegistry.ActivityResultListener {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingCallback: VideoPlayerApi.PlayCallback? = null
    private val pendingCloseCallbacks = mutableListOf<VideoPlayerApi.CloseCallback>()
    private var keyHeadersSession: String? = null

    @Volatile
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    @SuppressLint("UnsafeOptInUsageError")
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding.platformViewRegistry.registerViewFactory(
            "plugins.video/video_player_view",
            // FlutterActivity and FlutterFragmentActivity are LifecycleOwners.
            VideoPlayerViewFactory(binding.binaryMessenger) { (activity as? LifecycleOwner)?.lifecycle }
        )
        VideoPlayerHosts.registry.add(this)
    }

    /** Whether this engine has an Activity to start the player from. */
    internal val hasActivity: Boolean
        get() = activity != null

    /** Whether a player started by this engine has not reported its result yet. */
    internal val hasActivePlayer: Boolean
        get() = pendingCallback != null

    /** Starts the fullscreen player; runs on the main thread because it launches an Activity. */
    internal fun playVideo(playerConfigJsonString: String, callback: VideoPlayerApi.PlayCallback) {
        mainHandler.post { startPlayer(playerConfigJsonString, callback) }
    }

    /** Closes the player; [callback] runs once the player's result has been delivered, or at once if none is open. */
    @SuppressLint("UnsafeOptInUsageError")
    internal fun close(callback: VideoPlayerApi.CloseCallback) {
        mainHandler.post {
            val closing = VideoPlayerActivity.closeCurrentIfActive()
            if (pendingCallback == null) {
                callback.onClosed()
                return@post
            }
            // Launched but not created yet: its onCreate finishes at once, and the result completes the close.
            if (!closing) VideoPlayerActivity.requestCloseOnCreate()
            pendingCloseCallbacks.add(callback)
        }
    }

    /** The player's result arrived or never will: drop its key headers and any close waiting for its onCreate. */
    @SuppressLint("UnsafeOptInUsageError")
    private fun endPlayerSession() {
        keyHeadersSession?.let(KeyHeaderSessions::remove)
        keyHeadersSession = null
        VideoPlayerActivity.clearCloseOnCreate()
    }

    private fun completePendingCloses() {
        if (pendingCloseCallbacks.isEmpty()) return
        val callbacks = pendingCloseCallbacks.toList()
        pendingCloseCallbacks.clear()
        callbacks.forEach { it.onClosed() }
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun startPlayer(playerConfigJsonString: String, callback: VideoPlayerApi.PlayCallback) {
        if (pendingCallback != null) {
            callback.onError("PLAYER_ALREADY_ACTIVE", "A video player is already active")
            return
        }
        if (playerConfigJsonString.isEmpty()) {
            callback.onError("INVALID_CONFIG", "playerConfigJsonString is missing or empty")
            return
        }
        val playerConfiguration = try {
            PlayerConfiguration.fromJson(playerConfigJsonString)
        } catch (_: JSONException) {
            // org.json messages quote the whole input, which may carry keyRequestHeaders; never pass them on.
            callback.onError("JSON_ERROR", "Invalid player configuration JSON")
            return
        } catch (e: Exception) {
            callback.onError("JSON_ERROR", "Failed to parse player configuration: ${e.javaClass.simpleName}")
            return
        }
        val currentActivity = activity
        if (currentActivity == null) {
            callback.onError("NO_ACTIVITY", "Activity is null")
            return
        }
        VideoPlayerActivity.clearCloseOnCreate()
        val session = playerConfiguration.keyRequestHeaders.orEmpty().takeIf { it.isNotEmpty() }
            ?.let(KeyHeaderSessions::put)
        val intent = Intent(currentActivity.applicationContext, VideoPlayerActivity::class.java)
        intent.putExtra(extraArgument, playerConfiguration.copy(keyRequestHeaders = emptyMap()))
        session?.let { intent.putExtra(extraKeyHeadersSession, it) }
        pendingCallback = callback
        keyHeadersSession = session
        try {
            currentActivity.startActivityForResult(intent, playerActivity)
        } catch (e: Exception) {
            pendingCallback = null
            endPlayerSession()
            callback.onError("START_FAILED", "Failed to start the player: ${e.message}")
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        VideoPlayerHosts.registry.remove(this)
        if (pendingCallback != null) endPlayerSession()
        pendingCallback?.onCancelled()
        pendingCallback = null
        completePendingCloses()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // Keep pendingCallback: the player's result is delivered to the recreated activity.
        cleanupActivityBinding()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        // No activity will deliver the player's result; complete the Dart future as cancelled.
        if (pendingCallback != null) endPlayerSession()
        pendingCallback?.onCancelled()
        pendingCallback = null
        completePendingCloses()
        cleanupActivityBinding()
    }

    private fun cleanupActivityBinding() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    // Not consumed: other plugins (deep links, notifications) must still see new intents.
    override fun onNewIntent(intent: Intent): Boolean {
        return false
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == playerActivity) {
            val pendingResult = pendingCallback
            pendingCallback = null
            if (pendingResult == null) {
                completePendingCloses()
                return true
            }
            endPlayerSession()

            if (resultCode == playerActivityFinish && data != null) {
                val position: Long = data.getLongExtra("position", 0)
                val duration: Long = data.getLongExtra("duration", 0)
                pendingResult.onFinished(position.toInt(), duration.toInt())
            } else if (resultCode == playerActivitySessionLost) {
                pendingResult.onError("SESSION_LOST", "The player session was lost; start playback again")
            } else {
                pendingResult.onCancelled()
            }
            completePendingCloses()
            return true
        }
        // Not our request code: leave it for other plugins.
        return false
    }

}
