package uz.plugin.video_player.fullscreen

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.os.Handler
import android.util.Log
import android.util.Rational
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.Lifecycle
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView

/**
 * Picture-in-Picture for the full-screen player: entering (button / leaving the app),
 * the player view while in PiP, and telling "user closed the PiP window" apart from
 * "returned to the app" when PiP ends. [onDismissed] is called for the former.
 */
@UnstableApi
internal class PictureInPictureHandler(
    private val activity: AppCompatActivity,
    private val playerView: PlayerView,
    private val handler: Handler,
    private val onDismissed: () -> Unit,
) {
    private var dismissCheck: Runnable? = null
    private var wasInPictureInPicture = false

    fun enterFromButton() = enter(BUTTON_ASPECT_RATIO)

    /** Call from `onUserLeaveHint`. */
    fun onUserLeaveHint() {
        val supported = activity.packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
        if (supported && !activity.isInPictureInPictureMode) enter(AUTO_ASPECT_RATIO)
    }

    /** Call from `onPictureInPictureModeChanged`. */
    fun onModeChanged(isInPictureInPictureMode: Boolean) {
        if (isInPictureInPictureMode) {
            playerView.hideController()
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            wasInPictureInPicture = true
            return
        }
        // Exiting PiP: let the lifecycle settle, then tell "user closed the PiP window"
        // (not visible, not a config change) apart from "returned to the app".
        cancelPending()
        dismissCheck = Runnable {
            val isVisible = activity.lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)
            if (!isVisible && !activity.isChangingConfigurations && wasInPictureInPicture) {
                onDismissed()
            } else {
                playerView.showController()
            }
            wasInPictureInPicture = false
        }.also { handler.postDelayed(it, DISMISS_CHECK_DELAY_MS) }
    }

    fun cancelPending() {
        dismissCheck?.let { handler.removeCallbacks(it) }
        dismissCheck = null
    }

    private fun enter(aspectRatio: Rational) {
        val builder = PictureInPictureParams.Builder().setAspectRatio(aspectRatio)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(false)
        }
        try {
            activity.enterPictureInPictureMode(builder.build())
        } catch (e: Exception) {
            // Catch all exceptions including system bugs (NPE, RemoteException, etc.)
            Log.w(TAG, "Failed to enter PiP", e)
        }
    }

    private companion object {
        const val TAG = "VideoPlayer"
        const val DISMISS_CHECK_DELAY_MS = 300L
        val BUTTON_ASPECT_RATIO = Rational(16, 9)
        val AUTO_ASPECT_RATIO = Rational(100, 50)
    }
}
