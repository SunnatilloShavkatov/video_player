package uz.shs.video_player.models

import android.annotation.SuppressLint
import androidx.media3.ui.AspectRatioFrameLayout


class VideoViewModel(map: Map<*, *>) {
    private var url: String = ""
    private var resizeMode: String = ""

    init {
        // Support both 'url' and 'assets' keys for backward compatibility
        this.url = (map["url"] as? String) ?: (map["assets"] as? String) ?: ""
        this.resizeMode = (map["resizeMode"] as? String) ?: ""
    }

    fun getUrl(): String {
        return url
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