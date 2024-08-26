package uz.shs.video_player

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import com.google.gson.Gson
import io.flutter.embedding.android.FlutterActivity
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

const val EXTRA_ARGUMENT = "uz.shs.video_player.ARGUMENT"
const val PLAYER_ACTIVITY = 111
const val PLAYER_ACTIVITY_FINISH = 222

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
                val gson = Gson()
                val playerConfiguration =
                    gson.fromJson(playerConfigJsonString, PlayerConfiguration::class.java)
                val intent = Intent(activity?.applicationContext, VideoPlayerActivity::class.java)
                intent.putExtra(EXTRA_ARGUMENT, playerConfiguration)
                activity?.startActivityForResult(intent, PLAYER_ACTIVITY)
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
        activity = binding.activity as FlutterActivity
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
        if (requestCode == PLAYER_ACTIVITY && resultCode == PLAYER_ACTIVITY_FINISH) {
            val position: Long = data?.getLongExtra("position", 0) ?: 0
            val duration: Long = data?.getLongExtra("duration", 0) ?: 0
            resultMethod?.success(listOf(position.toInt(), duration.toInt()))
        }
        return true
    }

    private val handler = Handler(Looper.getMainLooper())
    private var runnable: Runnable? = null
}
