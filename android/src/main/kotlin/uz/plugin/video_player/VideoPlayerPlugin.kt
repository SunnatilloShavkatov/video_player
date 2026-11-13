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

const val extraArgument = "uz.plugin.video_player.ARGUMENT"
const val playerActivity = 111
const val playerActivityFinish = 222

class VideoPlayerPlugin : FlutterPlugin, ActivityAware,
    PluginRegistry.NewIntentListener, PluginRegistry.ActivityResultListener {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingCallback: VideoPlayerApi.PlayCallback? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    @SuppressLint("UnsafeOptInUsageError")
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding.platformViewRegistry.registerViewFactory(
            "plugins.video/video_player_view",
            // FlutterActivity and FlutterFragmentActivity are LifecycleOwners.
            VideoPlayerViewFactory(binding.binaryMessenger) { (activity as? LifecycleOwner)?.lifecycle }
        )
        VideoPlayerApi.host = this
    }

    /** Starts the fullscreen player; runs on the main thread because it launches an Activity. */
    internal fun playVideo(playerConfigJsonString: String, callback: VideoPlayerApi.PlayCallback) {
        mainHandler.post { startPlayer(playerConfigJsonString, callback) }
    }

    @SuppressLint("UnsafeOptInUsageError")
    internal fun close() {
        mainHandler.post { VideoPlayerActivity.closeCurrentIfActive() }
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
        } catch (e: JSONException) {
            callback.onError("JSON_ERROR", "Invalid JSON format: ${e.message}")
            return
        } catch (e: Exception) {
            callback.onError("JSON_ERROR", "Failed to parse player configuration: ${e.message}")
            return
        }
        val currentActivity = activity
        if (currentActivity == null) {
            callback.onError("NO_ACTIVITY", "Activity is null")
            return
        }
        val intent = Intent(currentActivity.applicationContext, VideoPlayerActivity::class.java)
        intent.putExtra(extraArgument, playerConfiguration)
        pendingCallback = callback
        try {
            currentActivity.startActivityForResult(intent, playerActivity)
        } catch (e: Exception) {
            pendingCallback = null
            callback.onError("START_FAILED", "Failed to start the player: ${e.message}")
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        if (VideoPlayerApi.host === this) {
            VideoPlayerApi.host = null
        }
        pendingCallback?.onCancelled()
        pendingCallback = null
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
        pendingCallback?.onCancelled()
        pendingCallback = null
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
            val pendingResult = pendingCallback ?: return true
            pendingCallback = null

            if (resultCode == playerActivityFinish && data != null) {
                val position: Long = data.getLongExtra("position", 0)
                val duration: Long = data.getLongExtra("duration", 0)
                pendingResult.onFinished(position.toInt(), duration.toInt())
            } else {
                pendingResult.onCancelled()
            }
            return true
        }
        // Not our request code: leave it for other plugins.
        return false
    }

}
