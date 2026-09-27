package uz.plugin.video_player.fullscreen

import android.annotation.SuppressLint
import android.app.PictureInPictureParams
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.Rational
import android.view.View
import android.view.WindowManager
import android.widget.RelativeLayout
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import androidx.lifecycle.Lifecycle
import androidx.media3.common.PlaybackException
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import uz.plugin.video_player.R
import uz.plugin.video_player.bottomsheet.PlayerBottomSheets
import uz.plugin.video_player.databinding.ActivityPlayerBinding
import uz.plugin.video_player.databinding.CustomPlaybackViewBinding
import uz.plugin.video_player.extraArgument
import uz.plugin.video_player.models.PlaybackState
import uz.plugin.video_player.models.PlayerConfiguration
import uz.plugin.video_player.models.PlayerViews
import uz.plugin.video_player.models.QualityOption
import uz.plugin.video_player.player.AudioFocusHandler
import uz.plugin.video_player.player.PlaybackRecoveryManager
import uz.plugin.video_player.player.PlayerController
import uz.plugin.video_player.player.PlayerControllerDelegate
import uz.plugin.video_player.player.PlayerControlsCoordinator
import uz.plugin.video_player.player.PlayerGestureHandler
import uz.plugin.video_player.playerActivityFinish
import uz.plugin.video_player.subtitles.SubtitleController
import uz.plugin.video_player.utils.applyBlackSystemBars
import uz.plugin.video_player.utils.setImmersive
import java.lang.ref.WeakReference
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Full-screen player screen. Owns the Android lifecycle, PiP, orientation and the
 * playback result; everything else lives in focused components:
 * - PlayerController           ExoPlayer lifecycle + playback commands (player/)
 * - PlayerControlsCoordinator  controls state: play icon, spinner, title, resize (player/)
 * - PlayerGestureHandler       taps, double-tap seek, brightness/volume swipe, pinch (player/)
 * - PlaybackRecoveryManager    network-restore and foreground recovery (player/)
 * - AudioFocusHandler          media audio focus (player/)
 * - SubtitleController         sidecar subtitle selection + size (subtitles/)
 * - PlayerBottomSheets         settings, quality, speed, subtitle pickers (bottomsheet/)
 */
@UnstableApi
class VideoPlayerActivity : AppCompatActivity(), PlayerControllerDelegate {

    companion object {
        private const val TAG = "VideoPlayer"
        private const val SEEK_INCREMENT_MS = 10000L
        private const val ORIENTATION_RESTORE_DELAY_MS = 3000L
        private const val PIP_DISMISS_CHECK_DELAY_MS = 300L
        private val PIP_BUTTON_ASPECT_RATIO = Rational(16, 9)
        private val PIP_AUTO_ASPECT_RATIO = Rational(100, 50)

        @Volatile
        private var currentInstance: WeakReference<VideoPlayerActivity>? = null

        /** Programmatically close the active VideoPlayerActivity (called from plugin's close()). */
        fun closeCurrentIfActive() {
            currentInstance?.get()?.let { activity ->
                if (!activity.isFinishing) {
                    activity.finishWithResult()
                }
            }
            currentInstance = null
        }
    }

    private lateinit var playerConfiguration: PlayerConfiguration
    private lateinit var binding: ActivityPlayerBinding
    private lateinit var playerView: PlayerView
    private lateinit var views: PlayerViews
    private lateinit var playerController: PlayerController

    private lateinit var controls: PlayerControlsCoordinator
    private lateinit var gestureHandler: PlayerGestureHandler
    private lateinit var recoveryManager: PlaybackRecoveryManager
    private lateinit var audioFocus: AudioFocusHandler
    private lateinit var subtitles: SubtitleController
    private lateinit var bottomSheets: PlayerBottomSheets

    private val mainHandler = Handler(Looper.getMainLooper())
    private var orientationRestoreRunnable: Runnable? = null
    private var pipDismissCheckRunnable: Runnable? = null

    // Startup guard: playback starts once both the window and the surface are ready.
    private val isSurfaceReady = AtomicBoolean(false)
    private val isWindowReady = AtomicBoolean(false)
    private val isStarted = AtomicBoolean(false)

    private var playbackState: PlaybackState = PlaybackState.PLAYING
    private var wasInPictureInPicture = false
    private var shouldResumeOnForeground = false
    private var hasPlaybackEnded = false
    private var pendingErrorToastMessage: String? = null

    private val controllerOrNull: PlayerController?
        get() = if (::playerController.isInitialized) playerController else null

    // MARK: - Lifecycle

    @SuppressLint("AppCompatMethod")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        currentInstance = WeakReference(this)
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() = finishWithResult()
        })
        playerConfiguration = try {
            readConfiguration()
        } catch (_: Exception) {
            finish()
            return
        }
        // Critical MTK EglMakeCurrent Crash Fix:
        // FLAG_SECURE and Window properties MUST be set BEFORE setContentView.
        // Doing it after introduces a race condition on SurfaceView's EGL context creation.
        if (!playerConfiguration.isScreenshotEnabled) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
        window.applyBlackSystemBars()

        binding = ActivityPlayerBinding.inflate(layoutInflater)
        setContentView(binding.root)
        actionBar?.hide()
        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { view, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.updatePadding(
                left = systemBars.left,
                top = systemBars.top,
                right = systemBars.right,
                bottom = systemBars.bottom,
            )
            WindowInsetsCompat.CONSUMED
        }

        playerView = binding.exoPlayerView
        views = bindPlayerViews()
        setUpComponents()
        bindControlActions()

        // 1. Window render pipeline ready
        window.decorView.post {
            isWindowReady.set(true)
            tryStartPlayback()
        }
        // 2. Surface ready
        playerView.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                isSurfaceReady.set(true)
                tryStartPlayback()
            }

            override fun onViewDetachedFromWindow(v: View) {}
        })
    }

    override fun onPause() {
        super.onPause()
        if (!isInPictureInPictureMode) {
            cancelPendingRunnables()
        }
        val controller = controllerOrNull ?: return
        shouldResumeOnForeground = controller.shouldResumeOnHostResume()
        controller.pauseForTransientLoss()
        if (isInPictureInPictureMode) {
            if (shouldResumeOnForeground) {
                controller.resumeAfterTransientLoss()
            }
            bottomSheets.dismissAll()
        }
    }

    override fun onResume() {
        super.onResume()
        audioFocus.request()
        resumePlaybackIfNeeded()
        gestureHandler.syncBrightnessWithSystem()
    }

    override fun onRestart() {
        super.onRestart()
        resumePlaybackIfNeeded()
    }

    override fun onStop() {
        super.onStop()
        val controller = controllerOrNull ?: return
        if (isInPictureInPictureMode) {
            // In PiP mode, keep player alive but pause if not playing
            if (!controller.isPlaying()) controller.pause()
        } else if (controller.isPlaying()) {
            // Don't release on stop (orientation/fullscreen changes, backgrounding); onDestroy
            // releases. Preserve play intent so foreground return and network recovery resume.
            controller.pauseForTransientLoss()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (currentInstance?.get() === this) {
            currentInstance = null
        }
        // Finished in onCreate (bad configuration) before anything was set up.
        if (!::bottomSheets.isInitialized) return

        cancelPendingRunnables()
        try {
            // REDMI 10A/MTK FIX: Detach player from view and hide it BEFORE release
            playerView.player = null
            playerView.visibility = View.GONE
            controllerOrNull?.release()
            mainHandler.removeCallbacksAndMessages(null)
            audioFocus.abandon()
            recoveryManager.stop()
        } catch (_: IllegalArgumentException) {
            // Ignore cleanup exceptions during shutdown races
        }
        bottomSheets.dismissAll()
    }

    // MARK: - Setup

    @Suppress("DEPRECATION")
    private fun readConfiguration(): PlayerConfiguration =
        intent.getSerializableExtra(extraArgument) as PlayerConfiguration

    private fun bindPlayerViews(): PlayerViews {
        // The controller layout is inflated by Media3 inside the PlayerView.
        val controller = CustomPlaybackViewBinding.bind(
            playerView.findViewById<RelativeLayout>(R.id.custom_playback)
        )
        return PlayerViews(
            close = controller.videoClose,
            pip = controller.videoPip,
            share = controller.ivShareMovie,
            more = controller.videoMore,
            title = controller.videoTitle,
            title1 = controller.videoTitle1,
            rewind = controller.videoRewind,
            forward = controller.videoForward,
            playPause = controller.videoPlayPause,
            progressBar = controller.videoProgressBar,
            zoom = controller.zoom,
            orientation = controller.orientation,
            customPlayback = controller.customPlayback,
            layoutBrightness = binding.layoutBrightness,
            brightnessSeekbar = binding.brightnessSeek,
            layoutVolume = binding.layoutVolume,
            volumeSeekBar = binding.volumeSeek,
        )
    }

    private fun setUpComponents() {
        controls = PlayerControlsCoordinator(playerView, views, playerConfiguration.title)
        controls.applyTitle(resources.configuration.orientation)

        val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        gestureHandler = PlayerGestureHandler(this, playerView, views, audioManager) { forward ->
            if (forward) controllerOrNull?.seekForward(SEEK_INCREMENT_MS)
            else controllerOrNull?.seekBackward(SEEK_INCREMENT_MS)
        }
        gestureHandler.attach()

        audioFocus = AudioFocusHandler(audioManager) {
            controllerOrNull?.pause()
            playerView.hideController()
        }
        audioFocus.request()

        recoveryManager = PlaybackRecoveryManager(this, { controllerOrNull }) {
            lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED) || isInPictureInPictureMode
        }
        recoveryManager.start()

        subtitles = SubtitleController(this, playerView, playerConfiguration) { controllerOrNull }
        bottomSheets = PlayerBottomSheets(this, playerConfiguration, subtitles) { controllerOrNull }
    }

    private fun bindControlActions() {
        val canShare = !playerConfiguration.playVideoFromAsset && playerConfiguration.movieShareLink.isNotBlank()
        views.share.visibility = if (canShare) View.VISIBLE else View.GONE
        views.close.setOnClickListener { finishWithResult() }
        views.share.setOnClickListener { shareMovieLink() }
        views.pip.setOnClickListener { enterPip(PIP_BUTTON_ASPECT_RATIO) }
        views.more.setOnClickListener { bottomSheets.showSettings() }
        views.rewind.setOnClickListener { controllerOrNull?.seekBackward(SEEK_INCREMENT_MS) }
        views.forward.setOnClickListener { controllerOrNull?.seekForward(SEEK_INCREMENT_MS) }
        views.playPause.setOnClickListener { togglePlayback() }
        views.zoom.setOnClickListener { controls.cycleResizeMode() }
        views.orientation.setOnClickListener { toggleOrientation() }
    }

    private fun tryStartPlayback() {
        if (isWindowReady.get() && isSurfaceReady.get() && isStarted.compareAndSet(false, true)) {
            startPlaybackSafely()
        }
    }

    private fun startPlaybackSafely() {
        try {
            val sourceUrl = if (playerConfiguration.playVideoFromAsset) {
                playerConfiguration.assetPath
            } else {
                playerConfiguration.videoUrl
            }
            playerController = PlayerController(this, this)
            playerController.initialize(
                sourceUrl,
                playerConfiguration.lastPosition,
                playerConfiguration.subtitles,
                playerConfiguration.keyRequestHeaders.orEmpty(),
            )
            playerController.attachToView(playerView)
            subtitles.restore()
        } catch (error: Exception) {
            onStartFailed(error)
        } catch (error: OutOfMemoryError) {
            onStartFailed(error)
        }
    }

    private fun onStartFailed(error: Throwable) {
        Log.e(TAG, "Failed to start playback: ${error.message}", error)
        pendingErrorToastMessage = getString(R.string.video_player_error_retry)
        onPlaybackStateChanged(PlaybackState.ERROR)
    }

    // MARK: - Actions

    private fun togglePlayback() {
        val controller = controllerOrNull ?: return
        when {
            hasPlaybackEnded -> {
                hasPlaybackEnded = false
                controller.seekTo(0)
                controller.play()
            }
            playbackState == PlaybackState.ERROR -> controller.retryPlayback(shouldResumePlayback = true)
            controller.isPlaying() -> controller.pause()
            else -> controller.play()
        }
    }

    /** Force the other orientation, then hand control back to the sensor after a delay. */
    private fun toggleOrientation() {
        requestedOrientation = if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        } else {
            ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
        }
        orientationRestoreRunnable?.let { mainHandler.removeCallbacks(it) }
        orientationRestoreRunnable = Runnable {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR
        }.also { mainHandler.postDelayed(it, ORIENTATION_RESTORE_DELAY_MS) }
    }

    private fun shareMovieLink() {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/html"
            putExtra(Intent.EXTRA_TEXT, playerConfiguration.movieShareLink)
        }
        startActivity(Intent.createChooser(intent, "Share using..."))
    }

    /** Report position/duration in seconds to the plugin and close. */
    private fun finishWithResult() {
        val controller = controllerOrNull
        val result = Intent().apply {
            putExtra("position", (controller?.getCurrentPosition() ?: 0L) / 1000)
            putExtra("duration", (controller?.getDuration() ?: 0L) / 1000)
        }
        controller?.getPlayer()?.stop()
        setResult(playerActivityFinish, result)
        finish()
    }

    private fun resumePlaybackIfNeeded() {
        if (controllerOrNull == null || !shouldResumeOnForeground || isInPictureInPictureMode) return
        recoveryManager.resumeAfterForeground()
    }

    private fun cancelPendingRunnables() {
        gestureHandler.cancelPendingTaps()
        orientationRestoreRunnable?.let { mainHandler.removeCallbacks(it) }
        pipDismissCheckRunnable?.let { mainHandler.removeCallbacks(it) }
        orientationRestoreRunnable = null
        pipDismissCheckRunnable = null
    }

    // MARK: - Picture-in-Picture

    private fun enterPip(aspectRatio: Rational) {
        val builder = PictureInPictureParams.Builder().setAspectRatio(aspectRatio)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(false)
        }
        try {
            enterPictureInPictureMode(builder.build())
        } catch (e: Exception) {
            // Catch all exceptions including system bugs (NPE, RemoteException, etc.)
            Log.w(TAG, "Failed to enter PiP", e)
        }
    }

    override fun onUserLeaveHint() {
        if (packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE) && !isInPictureInPictureMode) {
            enterPip(PIP_AUTO_ASPECT_RATIO)
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        if (isInPictureInPictureMode) {
            playerView.hideController()
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            wasInPictureInPicture = true
            return
        }
        // Exiting PiP: let the lifecycle settle, then tell "user closed the PiP window"
        // (not visible, not a config change) apart from "returned to the app".
        pipDismissCheckRunnable?.let { mainHandler.removeCallbacks(it) }
        pipDismissCheckRunnable = Runnable {
            val isVisible = lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)
            if (!isVisible && !isChangingConfigurations && wasInPictureInPicture) {
                finishWithResult()
            } else {
                playerView.showController()
            }
            wasInPictureInPicture = false
        }.also { mainHandler.postDelayed(it, PIP_DISMISS_CHECK_DELAY_MS) }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        val isLandscape = newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE
        window.setImmersive(isLandscape, findViewById(R.id.player_activity))
        controls.applyOrientation(newConfig.orientation)
        bottomSheets.onOrientationChanged()
    }

    // MARK: - PlayerControllerDelegate

    override fun onPlayerReady() {
        playerView.showController()
    }

    override fun onPlaybackStateChanged(state: PlaybackState) {
        playbackState = state
        when (state) {
            PlaybackState.BUFFERING, PlaybackState.PLAYING, PlaybackState.PAUSED -> {
                hasPlaybackEnded = false
                pendingErrorToastMessage = null
                if (state == PlaybackState.BUFFERING) controls.showBuffering() else controls.showReady()
            }

            PlaybackState.ERROR -> {
                hasPlaybackEnded = false
                controls.showError()
                val message = pendingErrorToastMessage ?: getString(R.string.video_player_error_retry)
                Toast.makeText(this, message, Toast.LENGTH_LONG).show()
                pendingErrorToastMessage = null
            }

            PlaybackState.IDLE -> Unit
        }
    }

    override fun onPlayerError(error: PlaybackException) {
        pendingErrorToastMessage = getString(
            if (recoveryManager.hasConnection()) R.string.video_player_error_retry
            else R.string.video_player_error_no_internet
        )
        Log.e(TAG, "Playback error: ${error.message}", error)
    }

    override fun onTracksChanged(qualities: List<QualityOption>) {
        bottomSheets.availableQualities = listOf(QualityOption(playerConfiguration.autoText, -1, -1, -1, -1, -1)) + qualities
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        if (isPlaying) {
            playbackState = PlaybackState.PLAYING
            controls.setPlayIcon(isPlaying = true)
        } else if (!hasPlaybackEnded && playbackState != PlaybackState.ERROR) {
            playbackState = PlaybackState.PAUSED
            controls.setPlayIcon(isPlaying = false)
        }
    }

    override fun onPlaybackEnded() {
        hasPlaybackEnded = true
        controls.setPlayIcon(isPlaying = false)
        playerView.showController()
    }
}
