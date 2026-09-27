package uz.plugin.video_player.embedded

import android.content.Context
import androidx.lifecycle.Lifecycle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** @param hostLifecycle Lifecycle of the activity hosting Flutter, or null when detached. */
class VideoPlayerViewFactory(
    private val messenger: BinaryMessenger,
    private val hostLifecycle: () -> Lifecycle?,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, id: Int, o: Any?): PlatformView {
        return VideoPlayerView(context, messenger, id, o, hostLifecycle())
    }
}