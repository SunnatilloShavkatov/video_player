package uz.plugin.video_player.models

import android.annotation.SuppressLint
import androidx.media3.ui.AspectRatioFrameLayout


class VideoViewModel(map: Map<*, *>) {
    private var url: String = ""
    private var resizeMode: String = ""
    private var keyRequestHeaders: Map<String, String> = emptyMap()
    private var keyRequestHosts: Set<String> = emptySet()

    init {
        // Support both 'url' and 'assets' keys for backward compatibility
        this.url = (map["url"] as? String) ?: (map["assets"] as? String) ?: ""
        this.resizeMode = (map["resizeMode"] as? String) ?: ""
        this.keyRequestHeaders = (map["keyRequestHeaders"] as? Map<*, *>)
            ?.mapNotNull { (key, value) ->
                if (key is String && value is String) key to value else null
            }
            ?.toMap()
            ?: emptyMap()
        this.keyRequestHosts = (map["keyRequestHosts"] as? List<*>)
            ?.filterIsInstance<String>()
            ?.toSet()
            ?: emptySet()
    }

    fun getUrl(): String {
        return url
    }

    /** Headers sent only with HLS AES-128 key requests. */
    fun getKeyRequestHeaders(): Map<String, String> {
        return keyRequestHeaders
    }

    /** Extra hosts (besides the playlist host) allowed to receive the key headers. */
    fun getKeyRequestHosts(): Set<String> {
        return keyRequestHosts
    }

    @SuppressLint("UnsafeOptInUsageError")
    fun getResizeMode(): Int {
        return when (resizeMode) {
            "fit" -> AspectRatioFrameLayout.RESIZE_MODE_FIT
            "fill" -> AspectRatioFrameLayout.RESIZE_MODE_FILL
            "zoom" -> AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            else -> AspectRatioFrameLayout.RESIZE_MODE_FIT
        }
    }
}