package uz.shs.video_player

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.util.Util
import androidx.media3.exoplayer.RenderersFactory
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadService
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
import uz.shs.video_player.models.DownloadConfiguration
import uz.shs.video_player.models.MediaItemDownload
import uz.shs.video_player.models.PlayerConfiguration
import uz.shs.video_player.services.DownloadTracker
import uz.shs.video_player.services.DownloadUtil
import uz.shs.video_player.services.MyDownloadService
import kotlin.math.roundToInt

const val EXTRA_ARGUMENT = "uz.shs.video_player.ARGUMENT"
const val PLAYER_ACTIVITY = 111
const val PLAYER_ACTIVITY_FINISH = 222

class VideoPlayerPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.NewIntentListener, PluginRegistry.ActivityResultListener,
    DownloadTracker.Listener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var resultMethod: Result? = null
    private var downloadTracker: DownloadTracker? = null

    @SuppressLint("UnsafeOptInUsageError")
    private lateinit var renderersFactory: RenderersFactory
    private val gson = Gson()

    @SuppressLint("UnsafeOptInUsageError")
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding.platformViewRegistry.registerViewFactory(
            "plugins.video/video_player_view", VideoPlayerViewFactory(binding.binaryMessenger)
        )
        channel = MethodChannel(binding.binaryMessenger, "video_player")
        channel.setMethodCallHandler(this)
        downloadTracker = DownloadUtil.getDownloadTracker(binding.applicationContext)
        startDownloadService(binding.applicationContext)
        downloadTracker!!.addListener(this)
        renderersFactory = DownloadUtil.buildRenderersFactory(binding.applicationContext, false)
        val download = downloadTracker?.getDownload()
        if (download != null) {
            runnable = object : Runnable {
                override fun run() {
                    try {
                        channel.invokeMethod("percent", toJson(download))
                        handler.postDelayed(this, 2000)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
            handler.postDelayed(runnable!!, 2000)
        }
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
        } else if (call.method == "downloadVideo" || call.method == "checkIsDownloadedVideo" || call.method == "getCurrentProgressDownload" || call.method == "pauseDownload" || call.method == "resumeDownload" || call.method == "getStateDownload" || call.method == "getBytesDownloaded" || call.method == "getContentBytesDownload" || call.method == "removeDownload") {
            if (call.hasArgument("downloadConfigJsonString")) {
                val downloadConfigJsonString = call.argument("downloadConfigJsonString") as String?
                val downloadConfiguration =
                    gson.fromJson(downloadConfigJsonString, DownloadConfiguration::class.java)
                val uri = Uri.parse(downloadConfiguration.url)
                val adaptiveMimeType: String? =
                    Util.getAdaptiveMimeTypeForContentType(Util.inferContentType(uri))
                val mediaItem = MediaItem.Builder().setUri(uri).setMediaMetadata(
                    MediaMetadata.Builder().setTitle(downloadConfiguration.title).build()
                ).setMimeType(adaptiveMimeType).build()
                when (call.method) {
                    "downloadVideo" -> {
                        downloadTracker?.toggleDownload(mediaItem, renderersFactory)
                    }

                    "checkIsDownloadedVideo" -> {
                        val isDownloaded = downloadTracker!!.isDownloaded(mediaItem)
                        result.success(isDownloaded)
                    }

                    "getCurrentProgressDownload" -> {
                        val progressDownload =
                            downloadTracker?.getCurrentProgressDownload(mediaItem)
                        result.success(progressDownload)
                    }

                    "pauseDownload" -> {
                        downloadTracker?.pauseDownloading(mediaItem)
                    }

                    "resumeDownload" -> {
                        downloadTracker?.resumeDownload(mediaItem)
                    }

                    "getStateDownload" -> {
                        result.success(downloadTracker?.getStateDownload(mediaItem))
                    }

                    "getBytesDownloaded" -> {
                        result.success(downloadTracker?.getBytesDownloaded(mediaItem))
                    }

                    "getContentBytesDownload" -> {
                        result.success(downloadTracker?.getContentBytesDownload(mediaItem))
                    }

                    "removeDownload" -> {
                        downloadTracker?.removeDownload(mediaItem)
                    }
                }
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
        downloadTracker!!.removeListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
        downloadTracker!!.removeListener(this)
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


    /** Start the download service if it should be running but it's not currently.  */
    @SuppressLint("UnsafeOptInUsageError")
    private fun startDownloadService(context: Context) {
        // Starting the service in the foreground causes notification flicker if there is no scheduled
        // action. Starting it in the background throws an exception if the app is in the background too
        // (e.g. if device screen is locked).
        try {
            DownloadService.start(context, MyDownloadService::class.java)
        } catch (e: IllegalStateException) {
            DownloadService.startForeground(
                context, MyDownloadService::class.java
            )
        }
    }

    val handler = Handler(Looper.getMainLooper())
    private var runnable: Runnable? = null

    @SuppressLint("UnsafeOptInUsageError")
    override fun onDownloadsChanged(download: Download) {
        if (download.state == Download.STATE_DOWNLOADING) {
            runnable = object : Runnable {
                override fun run() {
                    try {
                        channel.invokeMethod("percent", toJson(download))
                        handler.postDelayed(this, 2000)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
            handler.postDelayed(runnable!!, 2000)
        } else {
            if (runnable != null) {
                handler.removeCallbacks(runnable!!)
                channel.invokeMethod("percent", toJson(download))
            }
        }
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun toJson(download: Download): String {
        var percent = download.percentDownloaded.roundToInt()
        if (download.state == Download.STATE_REMOVING) {
            percent = 0
        }
        return gson.toJson(
            MediaItemDownload(
                download.request.id, percent, download.state, download.bytesDownloaded
            )
        )
    }

}
