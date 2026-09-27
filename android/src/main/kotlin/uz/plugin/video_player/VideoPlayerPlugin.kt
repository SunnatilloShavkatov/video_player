package uz.plugin.video_player

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import org.json.JSONException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import uz.plugin.video_player.embedded.VideoPlayerViewFactory
import uz.plugin.video_player.fullscreen.VideoPlayerActivity
import uz.plugin.video_player.models.PlayerConfiguration

const val extraArgument = "uz.plugin.video_player.ARGUMENT"
const val playerActivity = 111
const val playerActivityFinish = 222

class VideoPlayerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.NewIntentListener, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private var resultMethod: Result? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    @SuppressLint("UnsafeOptInUsageError")
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding.platformViewRegistry.registerViewFactory(
            "plugins.video/video_player_view", VideoPlayerViewFactory(binding.binaryMessenger)
        )
        channel = MethodChannel(binding.binaryMessenger, "video_player")
        channel.setMethodCallHandler(this)
    }

    @SuppressLint("UnsafeOptInUsageError")
    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "playVideo") {
            if (resultMethod != null) {
                result.error("PLAYER_ALREADY_ACTIVE", "A video player is already active", null)
                return
            }
            if (call.hasArgument("playerConfigJsonString")) {
                val playerConfigJsonString = call.argument("playerConfigJsonString") as String?
                if (playerConfigJsonString == null || playerConfigJsonString.isEmpty()) {
                    result.error("INVALID_CONFIG", "playerConfigJsonString is null or empty", null)
                    return
                }
                val playerConfiguration = try {
                    PlayerConfiguration.fromJson(playerConfigJsonString)
                } catch (e: JSONException) {
                    result.error("JSON_ERROR", "Invalid JSON format: ${e.message}", null)
                    return
                } catch (e: Exception) {
                    result.error("JSON_ERROR", "Failed to parse player configuration: ${e.message}", null)
                    return
                }
                val currentActivity = activity
                if (currentActivity == null) {
                    result.error("NO_ACTIVITY", "Activity is null", null)
                    return
                }
                val intent =
                    Intent(currentActivity.applicationContext, VideoPlayerActivity::class.java)
                intent.putExtra(extraArgument, playerConfiguration)
                currentActivity.startActivityForResult(intent, playerActivity)
                resultMethod = result
            }
        } else if (call.method == "close") {
            VideoPlayerActivity.closeCurrentIfActive()
            result.success(null)
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        resultMethod = null
        cleanupActivityBinding()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        resultMethod = null
        cleanupActivityBinding()
    }

    private fun cleanupActivityBinding() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        return true
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == playerActivity) {
            val pendingResult = resultMethod ?: return true
            resultMethod = null

            if (resultCode == playerActivityFinish && data != null) {
                val position: Long = data.getLongExtra("position", 0)
                val duration: Long = data.getLongExtra("duration", 0)
                pendingResult.success(listOf(position.toInt(), duration.toInt()))
            } else {
                pendingResult.success(null)
            }
            return true
        }
        return true
    }

}
