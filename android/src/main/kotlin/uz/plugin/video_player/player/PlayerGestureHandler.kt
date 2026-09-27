package uz.plugin.video_player.player

import android.annotation.SuppressLint
import android.app.Activity
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import uz.plugin.video_player.models.PlayerViews
import kotlin.math.abs

/**
 * Full-screen player gestures: single tap shows/hides the controller, double tap
 * seeks (left half back, right half forward), vertical swipe changes brightness
 * (left) or volume (right), pinch switches fit/zoom. No playback logic.
 *
 * @param onSeek Called for a double tap; `forward` is true on the right half
 */
@UnstableApi
class PlayerGestureHandler(
    private val activity: Activity,
    private val playerView: PlayerView,
    private val views: PlayerViews,
    private val audioManager: AudioManager,
    private val onSeek: (forward: Boolean) -> Unit,
) : GestureDetector.SimpleOnGestureListener(), ScaleGestureDetector.OnScaleGestureListener {

    private companion object {
        const val BRIGHTNESS_MAX = 30
        const val BRIGHTNESS_DEFAULT = 15
        const val BRIGHTNESS_STEP = 0.2
        const val VOLUME_STEP = 0.2
        const val SCREEN_BRIGHTNESS_SCALE = 1.0f / BRIGHTNESS_MAX
    }

    private val gestureDetector = GestureDetector(activity, this)
    private val scaleGestureDetector = ScaleGestureDetector(activity, this)
    private val handler = Handler(Looper.getMainLooper())

    // Taps on the video while the controller is hidden / on the controller while shown.
    private val videoTaps = TapTracker(handler, onSingleTap = playerView::showController, onDoubleTap = ::seekFromTap)
    private val controllerTaps = TapTracker(handler, onSingleTap = playerView::hideController, onDoubleTap = ::seekFromTap)

    private var brightness = BRIGHTNESS_DEFAULT.toDouble()
    private val maxBrightness = BRIGHTNESS_MAX + 1.0
    private var volume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble()
    private val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC) + 1.0
    private var scaleFactor = 0f

    init {
        views.brightnessSeekbar.apply {
            isEnabled = false
            max = BRIGHTNESS_MAX
            progress = BRIGHTNESS_DEFAULT
        }
        views.volumeSeekBar.apply {
            isEnabled = false
            max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            progress = volume.toInt()
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    fun attach() {
        playerView.setOnTouchListener { _, event ->
            if (event.pointerCount == 2) {
                scaleGestureDetector.onTouchEvent(event)
            } else if (!playerView.isControllerFullyVisible && event.pointerCount == 1) {
                gestureDetector.onTouchEvent(event)
                if (event.action == MotionEvent.ACTION_UP) {
                    views.layoutBrightness.visibility = View.GONE
                    views.layoutVolume.visibility = View.GONE
                }
            }
            true
        }
        views.customPlayback.setOnTouchListener { _, event ->
            if (event.pointerCount == 1 && event.action == MotionEvent.ACTION_UP) {
                controllerTaps.onTapUp(event.x)
            }
            true
        }
    }

    /** Re-read the system brightness (it may have changed while backgrounded). */
    fun syncBrightnessWithSystem() {
        brightness = try {
            Settings.System.getInt(activity.contentResolver, Settings.System.SCREEN_BRIGHTNESS)
                .toDouble().coerceIn(0.0, BRIGHTNESS_MAX.toDouble())
        } catch (_: Settings.SettingNotFoundException) {
            BRIGHTNESS_DEFAULT.toDouble()
        }
        views.brightnessSeekbar.progress = brightness.toInt()
    }

    fun cancelPendingTaps() {
        videoTaps.cancel()
        controllerTaps.cancel()
    }

    private fun seekFromTap(x: Float) {
        onSeek(x >= playerView.width / 2f)
    }

    // MARK: - GestureDetector

    override fun onSingleTapUp(e: MotionEvent): Boolean {
        videoTaps.onTapUp(e.x)
        return false
    }

    override fun onScroll(e1: MotionEvent?, e2: MotionEvent, distanceX: Float, distanceY: Float): Boolean {
        if (abs(distanceX) >= abs(distanceY)) return true
        val increase = distanceY > 0
        if (e2.x < playerView.width / 2f) {
            views.layoutBrightness.visibility = View.VISIBLE
            views.layoutVolume.visibility = View.GONE
            val newValue = if (increase) brightness + BRIGHTNESS_STEP else brightness - BRIGHTNESS_STEP
            if (newValue in 0.0..maxBrightness) {
                brightness = newValue
                views.brightnessSeekbar.progress = brightness.toInt()
                activity.window.attributes = activity.window.attributes.apply {
                    screenBrightness = SCREEN_BRIGHTNESS_SCALE * brightness.toInt()
                }
            }
        } else {
            views.layoutBrightness.visibility = View.GONE
            views.layoutVolume.visibility = View.VISIBLE
            val newValue = if (increase) volume + VOLUME_STEP else volume - VOLUME_STEP
            if (newValue in 0.0..maxVolume) {
                volume = newValue
                views.volumeSeekBar.progress = volume.toInt()
                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume.toInt(), 0)
            }
        }
        return true
    }

    // MARK: - ScaleGestureDetector

    override fun onScale(detector: ScaleGestureDetector): Boolean {
        scaleFactor = detector.scaleFactor
        return true
    }

    override fun onScaleBegin(detector: ScaleGestureDetector): Boolean = true

    override fun onScaleEnd(detector: ScaleGestureDetector) {
        playerView.resizeMode = if (scaleFactor > 1) {
            AspectRatioFrameLayout.RESIZE_MODE_ZOOM
        } else {
            AspectRatioFrameLayout.RESIZE_MODE_FIT
        }
    }
}

/**
 * Tells a single tap from a double tap on raw tap-up events: a second tap within
 * [TIMEOUT_MS] is a double tap, otherwise the single-tap action runs after the timeout.
 */
private class TapTracker(
    private val handler: Handler,
    private val onSingleTap: () -> Unit,
    private val onDoubleTap: (x: Float) -> Unit,
) {
    private companion object {
        const val TIMEOUT_MS = 300L
    }

    private var lastTapAt = -1L
    private var pendingSingleTap: Runnable? = null

    fun onTapUp(x: Float) {
        lastTapAt = if (lastTapAt == -1L) {
            System.currentTimeMillis()
        } else {
            if (System.currentTimeMillis() - lastTapAt <= TIMEOUT_MS) onDoubleTap(x) else onSingleTap()
            -1L
        }
        pendingSingleTap?.let { handler.removeCallbacks(it) }
        pendingSingleTap = Runnable {
            if (lastTapAt != -1L) {
                onSingleTap()
                lastTapAt = -1L
            }
        }.also { handler.postDelayed(it, TIMEOUT_MS) }
    }

    fun cancel() {
        pendingSingleTap?.let { handler.removeCallbacks(it) }
        pendingSingleTap = null
    }
}
