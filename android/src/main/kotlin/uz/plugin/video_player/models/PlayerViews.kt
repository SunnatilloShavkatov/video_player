package uz.plugin.video_player.models

import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.RelativeLayout
import android.widget.SeekBar
import android.widget.TextView

/**
 * References to the full-screen player's views (activity layout + the
 * controller layout inflated by Media3), shared by the player components.
 */
data class PlayerViews(
    val close: ImageView,
    val pip: ImageView,
    val share: ImageView,
    val more: ImageView,
    val title: TextView,
    val title1: TextView,
    val rewind: ImageView,
    val forward: ImageView,
    val playPause: ImageView,
    val progressBar: ProgressBar,
    val zoom: ImageView,
    val orientation: ImageView,
    val customPlayback: RelativeLayout,
    val layoutBrightness: LinearLayout,
    val brightnessSeekbar: SeekBar,
    val layoutVolume: LinearLayout,
    val volumeSeekBar: SeekBar,
)
