package uz.plugin.video_player.player

import android.content.Context
import androidx.media3.common.util.UnstableApi
import uz.plugin.video_player.utils.NetworkChangeReceiver

/**
 * Recovers playback after a network loss and when the host returns to the
 * foreground. No UI dependencies.
 *
 * @param controller Current player, or null before playback has started
 * @param canRecover Whether the host is visible (started or in PiP) and may resume
 */
@UnstableApi
class PlaybackRecoveryManager(
    context: Context,
    private val controller: () -> PlayerController?,
    private val canRecover: () -> Boolean,
) {
    private val networkReceiver = NetworkChangeReceiver(
        context = context.applicationContext,
        onConnected = ::onNetworkRestored,
        onDisconnected = { controller()?.onNetworkLost() },
    )

    fun start() = networkReceiver.start()

    fun stop() = networkReceiver.stop()

    fun hasConnection(): Boolean = networkReceiver.hasConnection()

    /** Resume after the host comes back to the foreground. */
    fun resumeAfterForeground() {
        val controller = controller() ?: return
        when {
            controller.isRemotePlayback() && !networkReceiver.hasConnection() -> controller.onNetworkLost()
            controller.shouldAutoRecoverAfterNetworkRestore() -> controller.retryPlayback(shouldResumePlayback = true)
            else -> controller.resumeAfterTransientLoss()
        }
    }

    private fun onNetworkRestored() {
        val controller = controller() ?: return
        if (canRecover() && controller.shouldAutoRecoverAfterNetworkRestore()) {
            controller.retryPlayback(shouldResumePlayback = true)
        }
    }
}
