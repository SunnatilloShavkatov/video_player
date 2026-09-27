package uz.plugin.video_player.utils

import android.graphics.Color
import android.os.Build
import android.view.View
import android.view.Window
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat

/** Black status and navigation bars without the system contrast scrim. */
fun Window.applyBlackSystemBars() {
    @Suppress("DEPRECATION")
    statusBarColor = Color.BLACK
    applyBlackNavigationBar()
}

fun Window.applyBlackNavigationBar() {
    @Suppress("DEPRECATION")
    navigationBarColor = Color.BLACK
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        @Suppress("DEPRECATION")
        isNavigationBarContrastEnforced = false
    }
}

/**
 * Immersive mode (landscape) hides the system bars until swiped in;
 * leaving it shows them again.
 */
fun Window.setImmersive(immersive: Boolean, rootView: View) {
    WindowCompat.setDecorFitsSystemWindows(this, !immersive)
    val controller = WindowInsetsControllerCompat(this, rootView)
    if (immersive) {
        controller.hide(WindowInsetsCompat.Type.systemBars())
        controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    } else {
        controller.show(WindowInsetsCompat.Type.systemBars())
    }
    applyBlackNavigationBar()
}
