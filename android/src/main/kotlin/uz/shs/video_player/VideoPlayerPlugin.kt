package uz.shs.video_player

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import com.google.gson.Gson
import com.google.gson.JsonSyntaxException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import uz.shs.video_player.activities.VideoPlayerActivity
import uz.shs.video_player.models.PlayerConfiguration

const val extraArgument = "uz.shs.video_player.ARGUMENT"
const val playerActivity = 111
const val playerActivityFinish = 222

class VideoPlayerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.NewIntentListener, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var resultMethod: Result? = null

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
            if (call.hasArgument("playerConfigJsonString")) {
                val playerConfigJsonString = call.argument("playerConfigJsonString") as String?
                if (playerConfigJsonString == null || playerConfigJsonString.isEmpty()) {
                    result.error("INVALID_CONFIG", "playerConfigJsonString is null or empty", null)
                    return
                }
                val gson = Gson()
                val playerConfiguration = try {
                    gson.fromJson(playerConfigJsonString, PlayerConfiguration::class.java)
                } catch (e: JsonSyntaxException) {
                    result.error("JSON_ERROR", "Invalid JSON format: ${e.message}", null)
                    return
                }
                if (activity == null) {
                    result.error("NO_ACTIVITY", "Activity is null", null)
                    return
                }
                val intent = Intent(activity!!.applicationContext, VideoPlayerActivity::class.java)
                intent.putExtra(extraArgument, playerConfiguration)
                activity!!.startActivityForResult(intent, playerActivity)
                resultMethod = result
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        if (runnable != null) {
            handler.removeCallbacks(runnable!!)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addOnNewIntentListener(this)
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        return true
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == playerActivity && resultCode == playerActivityFinish) {
            // Check if resultMethod has already been used to avoid double usage
            if (resultMethod == null) {
                return true // No result method to handle the result, so exit
            }
            // Handling null data case
            if (data == null) {
                resultMethod?.success(null)
                resultMethod = null // Ensure the reply object isn't reused
                return true
            }
            // Get position and duration from the intent
            val position: Long = data.getLongExtra("position", 0)
            val duration: Long = data.getLongExtra("duration", 0)
            // Respond with the result
            resultMethod?.success(listOf(position.toInt(), duration.toInt()))
            resultMethod = null // Mark the resultMethod as used
        }
        return true
    }

    private val handler = Handler(Looper.getMainLooper())
    private var runnable: Runnable? = null
}
