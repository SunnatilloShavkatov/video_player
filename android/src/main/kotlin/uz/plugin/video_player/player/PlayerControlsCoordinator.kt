package uz.plugin.video_player.player

import android.content.res.Configuration
import android.view.View
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import uz.plugin.video_player.R
import uz.plugin.video_player.models.PlayerViews

/**
 * Keeps the full-screen controls in sync with player state: play/pause icon,
 * loading spinner, title placement and resize mode. Does not control playback.
 */
@UnstableApi
class PlayerControlsCoordinator(
    private val playerView: PlayerView,
    private val views: PlayerViews,
    private val title: String,
) {

    /** Landscape shows the title in the top bar; portrait shows it below. */
    fun applyTitle(orientation: Int) {
        views.title.text = title
        views.title1.text = title
        val isLandscape = orientation == Configuration.ORIENTATION_LANDSCAPE
        views.title.visibility = if (isLandscape) View.VISIBLE else View.INVISIBLE
        views.title1.visibility = if (isLandscape) View.GONE else View.VISIBLE
    }

    fun applyOrientation(orientation: Int) {
        applyTitle(orientation)
        if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
            views.zoom.visibility = View.VISIBLE
        } else {
            views.zoom.visibility = View.GONE
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
        }
    }

    fun showBuffering() {
        views.playPause.visibility = View.GONE
        views.progressBar.visibility = View.VISIBLE
        setBufferingIndicator(PlayerView.SHOW_BUFFERING_ALWAYS)
    }

    fun showReady() {
        views.playPause.visibility = View.VISIBLE
        views.progressBar.visibility = View.GONE
        setBufferingIndicator(PlayerView.SHOW_BUFFERING_NEVER)
    }

    fun showError() {
        showReady()
        setPlayIcon(isPlaying = false)
    }

    fun setPlayIcon(isPlaying: Boolean) {
        views.playPause.setImageResource(if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play)
    }

    /** Zoom button: zoom → fit → fill → zoom, with the icon showing the next mode. */
    fun cycleResizeMode() {
        val (nextMode, icon) = when (playerView.resizeMode) {
            AspectRatioFrameLayout.RESIZE_MODE_ZOOM -> AspectRatioFrameLayout.RESIZE_MODE_FIT to R.drawable.ic_fit
            AspectRatioFrameLayout.RESIZE_MODE_FILL -> AspectRatioFrameLayout.RESIZE_MODE_ZOOM to R.drawable.ic_crop_fit
            AspectRatioFrameLayout.RESIZE_MODE_FIT -> AspectRatioFrameLayout.RESIZE_MODE_FILL to R.drawable.ic_stretch
            else -> return
        }
        views.zoom.setImageResource(icon)
        playerView.resizeMode = nextMode
    }

    // Media3's own spinner only matters while our controller (with its spinner) is hidden.
    private fun setBufferingIndicator(mode: Int) {
        if (!playerView.isControllerFullyVisible) {
            playerView.setShowBuffering(mode)
        }
    }
}
