package uz.shs.video_player.models

import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.RelativeLayout
import android.widget.SeekBar
import android.widget.TextView
import androidx.media3.ui.DefaultTimeBar

/**
 * Data class holding references to all player UI views.
 *
 * This container decouples the Activity from direct view access
 * and facilitates passing UI components to helper classes
 * (like ControlsCoordinator, GestureManager).
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
    val timer: LinearLayout,
    val exoPosition: TextView,
    val videoPosition: TextView,
    val zoom: ImageView,
    val orientation: ImageView,
    val exoProgress: DefaultTimeBar,
    val customPlayback: RelativeLayout,
    val layoutBrightness: LinearLayout,
    val brightnessSeekbar: SeekBar,
    val layoutVolume: LinearLayout,
    val volumeSeekBar: SeekBar
)
