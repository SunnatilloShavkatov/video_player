package uz.shs.video_player.activities

import android.annotation.SuppressLint
import android.app.PictureInPictureParams
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.content.res.Resources
import android.graphics.Color
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Rational
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.ProgressBar
import android.widget.RelativeLayout
import android.widget.SeekBar
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.net.toUri
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.view.updatePadding
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.DefaultTimeBar
import androidx.media3.ui.PlayerView
import androidx.media3.ui.PlayerView.SHOW_BUFFERING_ALWAYS
import androidx.media3.ui.PlayerView.SHOW_BUFFERING_NEVER
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import uz.shs.video_player.R
import uz.shs.video_player.adapters.QualitySpeedAdapter
import uz.shs.video_player.extraArgument
import uz.shs.video_player.models.BottomSheet
import uz.shs.video_player.models.PlayerConfiguration
import uz.shs.video_player.playerActivityFinish
import uz.shs.video_player.services.NetworkChangeReceiver
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.abs

@UnstableApi
class VideoPlayerActivity : AppCompatActivity(), GestureDetector.OnGestureListener,
    ScaleGestureDetector.OnScaleGestureListener, AudioManager.OnAudioFocusChangeListener {

    companion object {
        private const val SEEK_INCREMENT_MS = 10000L
        private const val DOUBLE_CLICK_TIMEOUT_MS = 300L
        private const val BRIGHTNESS_MAX = 30
        private const val BRIGHTNESS_DEFAULT = 15
        private const val BRIGHTNESS_STEP = 0.2
        private const val VOLUME_STEP = 0.2
        private const val SCREEN_BRIGHTNESS_SCALE = 1.0f / 30
        private const val ORIENTATION_CHANGE_DELAY_MS = 3000L
        private const val PIP_ASPECT_RATIO_WIDTH = 16
        private const val PIP_ASPECT_RATIO_HEIGHT = 9
        private const val PIP_ASPECT_RATIO_WIDTH_HINT = 100
        private const val PIP_ASPECT_RATIO_HEIGHT_HINT = 50
    }

    private lateinit var playerView: PlayerView
    private lateinit var player: ExoPlayer
    private lateinit var networkChangeReceiver: NetworkChangeReceiver
    private lateinit var intentFilter: IntentFilter
    private lateinit var playerConfiguration: PlayerConfiguration
    private lateinit var close: ImageView
    private lateinit var pip: ImageView
    private lateinit var shareMovieLinkIv: ImageView
    private lateinit var more: ImageView
    private lateinit var title: TextView
    private lateinit var title1: TextView
    private lateinit var rewind: ImageView
    private lateinit var forward: ImageView
    private lateinit var playPause: ImageView
    private lateinit var progressbar: ProgressBar
    private lateinit var timer: LinearLayout
    private lateinit var exoPosition: TextView
    private lateinit var videoPosition: TextView
    private lateinit var zoom: ImageView
    private lateinit var orientation: ImageView
    private lateinit var exoProgress: DefaultTimeBar
    private lateinit var customPlayback: RelativeLayout
    private lateinit var layoutBrightness: LinearLayout
    private lateinit var brightnessSeekbar: SeekBar
    private lateinit var volumeSeekBar: SeekBar
    private lateinit var layoutVolume: LinearLayout
    private lateinit var audioManager: AudioManager
    private lateinit var gestureDetector: GestureDetector
    private lateinit var scaleGestureDetector: ScaleGestureDetector
    private var isSettingsBottomSheetOpened: Boolean = false
    private var isQualitySpeedBottomSheetOpened: Boolean = false
    private val listOfAllOpenedBottomSheets = mutableListOf<BottomSheetDialog>()
    private var brightness: Double = BRIGHTNESS_DEFAULT.toDouble()
    private var maxBrightness: Double = BRIGHTNESS_MAX + 1.0
    private var volume: Double = 0.0
    private var maxVolume: Double = 0.0
    private var sWidth: Int = 0
    private var currentOrientation: Int = Configuration.ORIENTATION_PORTRAIT
    private var titleText = ""
    private lateinit var url: String
    private var mPlaybackState: PlaybackState? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // STARTUP-SAFE GUARD
    private val isSurfaceReady = AtomicBoolean(false)
    private val isWindowReady = AtomicBoolean(false)
    private val isStarted = AtomicBoolean(false)

    // ✅ FIXED: Store all Runnables for explicit removal
    private var hideControllerRunnable: Runnable? = null
    private var showControllerRunnable: Runnable? = null
    private var orientationRestoreRunnable: Runnable? = null
    private var pipDismissCheckRunnable: Runnable? = null

    private var isNetworkReceiverRegistered = false
    private var wasInPictureInPicture: Boolean = false
    private var availableQualities: List<QualityOption> = emptyList()

    enum class PlaybackState {
        PLAYING, PAUSED, BUFFERING, IDLE
    }

    data class QualityOption(
        val displayName: String,
        val height: Int,
        val width: Int,
        val bitrate: Int,
        val groupIndex: Int,
        val trackIndex: Int
    )

    @SuppressLint("AppCompatMethod")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        onBackPressedDispatcher.addCallback(this, onBackPressedCallback)
        setContentView(R.layout.activity_player)
        actionBar?.hide()

        // Apply FLAG_SECURE safely
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q) {
            window.decorView.post {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        } else {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }

        window.statusBarColor = Color.BLACK
        window.navigationBarColor = Color.BLACK
        val rootView = findViewById<RelativeLayout>(R.id.player_activity)
        ViewCompat.setOnApplyWindowInsetsListener(rootView) { view, insets ->
            val systemBarsInsets = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.updatePadding(
                top = systemBarsInsets.top,
                bottom = systemBarsInsets.bottom,
                left = systemBarsInsets.left,
                right = systemBarsInsets.right
            )
            WindowInsetsCompat.CONSUMED
        }

        val config = intent.getSerializableExtra(extraArgument) as? PlayerConfiguration
        config ?: run {
            finish()
            return
        }
        playerConfiguration = config
        titleText = playerConfiguration.title
        url = playerConfiguration.videoUrl
        currentQuality = "Auto"

        initializeViews()
        mPlaybackState = PlaybackState.PLAYING

        initializeClickListeners()

        sWidth = Resources.getSystem().displayMetrics.widthPixels
        gestureDetector = GestureDetector(this, this)
        scaleGestureDetector = ScaleGestureDetector(this, this)
        brightnessSeekbar.max = BRIGHTNESS_MAX
        brightnessSeekbar.progress = BRIGHTNESS_DEFAULT
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        setAudioFocus()
        maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).toDouble()
        volume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble()
        volumeSeekBar.max = maxVolume.toInt()
        maxVolume += 1.0
        volumeSeekBar.progress = volume.toInt()

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

        listenConnection()
    }

    private fun listenConnection() {
        if (isNetworkReceiverRegistered) {
            return // Already registered
        }

        // IntentFilter create
        intentFilter = IntentFilter("android.net.conn.CONNECTIVITY_CHANGE")

        // NetworkChangeReceiver create
        networkChangeReceiver = object : NetworkChangeReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                super.onReceive(context, intent)
                if (hasInternetConnection()) {
                    rePlayVideo()
                }
            }
        }

        // BroadcastReceiver active
        try {
            registerReceiver(networkChangeReceiver, intentFilter)
            isNetworkReceiverRegistered = true
        } catch (_: Exception) {
            // Failed to register network receiver
        }
    }

    private fun Context.hasInternetConnection(): Boolean {
        val cm = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return false
        val caps = cm.getNetworkCapabilities(network) ?: return false
        return caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) && caps.hasCapability(
            NetworkCapabilities.NET_CAPABILITY_VALIDATED
        )
    }

    private fun rePlayVideo() {
        if (::player.isInitialized) {
            player.prepare()
            player.play()
        }
    }

    private val onBackPressedCallback: OnBackPressedCallback =
        object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (::player.isInitialized && player.isPlaying) {
                    player.stop()
                }
                val intent = Intent()
                intent.putExtra(
                    "position",
                    if (::player.isInitialized) player.currentPosition / 1000 else 0
                )
                intent.putExtra(
                    "duration",
                    if (::player.isInitialized) player.duration / 1000 else 0
                )
                setResult(playerActivityFinish, intent)
                finish()
            }
        }

    override fun onPause() {
        super.onPause()

        // ✅ FIXED: Remove pending callbacks when pausing (except PiP mode)
        if (!isInPictureInPictureMode) {
            cancelAllPendingRunnables()
        }

        if (::player.isInitialized) {
            val isPlaying = player.isPlaying
            player.playWhenReady = false

            if (isInPictureInPictureMode) {
                // In PiP mode, restore playing state
                player.playWhenReady = isPlaying
                dismissAllBottomSheets()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        setAudioFocus()
        if (::player.isInitialized) {
            player.playWhenReady = true
        }
        try {
            // Retrieve and set brightness safely
            val currentBrightness: Int = Settings.System.getInt(
                this.contentResolver, Settings.System.SCREEN_BRIGHTNESS
            )
            brightness = currentBrightness.toDouble().coerceIn(0.0, BRIGHTNESS_MAX.toDouble())
            brightnessSeekbar.progress = brightness.toInt()
        } catch (_: Settings.SettingNotFoundException) {
            // Fallback to default brightness
            brightness = BRIGHTNESS_DEFAULT.toDouble()
            brightnessSeekbar.progress = BRIGHTNESS_DEFAULT
        }
    }

    override fun onRestart() {
        super.onRestart()
        if (::player.isInitialized) {
            player.playWhenReady = true
        }
    }

    override fun onStop() {
        super.onStop()
        if (isInPictureInPictureMode) {
            // In PiP mode, keep player alive but pause if not playing
            if (::player.isInitialized && !player.isPlaying) {
                player.pause()
            }
        } else {
            // Do not release player on stop during orientation/fullscreen changes
            // or when the activity is simply going to background. Rely on onDestroy
            // to release resources when the activity is actually finishing.
            // If you want to conserve resources in background, you can pause here.
            if (::player.isInitialized && player.isPlaying) {
                player.pause()
            }
        }
    }

    private fun tryStartPlayback() {
        if (
            isWindowReady.get() &&
            isSurfaceReady.get() &&
            isStarted.compareAndSet(false, true)
        ) {
            startPlaybackSafely()
        }
    }

    private fun startPlaybackSafely() {
        val dataSourceFactory: DataSource.Factory = DefaultHttpDataSource.Factory()
        val hlsMediaSource: HlsMediaSource = HlsMediaSource.Factory(dataSourceFactory)
            .createMediaSource(MediaItem.fromUri(url.toUri()))
        player = ExoPlayer.Builder(this).build()
        playerView.player = player
        playerView.keepScreenOn = true
        playerView.useController = true
        player.setMediaSource(hlsMediaSource)
        player.seekTo(playerConfiguration.lastPosition * 1000)
        player.prepare()
        player.addListener(object : Player.Listener {
            override fun onPlayerError(error: PlaybackException) {
                // Handle error silently
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                if (isPlaying) {
                    mPlaybackState = PlaybackState.PLAYING
                    playPause.setImageResource(R.drawable.ic_pause)
                } else {
                    mPlaybackState = PlaybackState.PAUSED
                    playPause.setImageResource(R.drawable.ic_play)
                }
            }

            override fun onPlaybackStateChanged(playbackState: Int) {
                when (playbackState) {
                    Player.STATE_BUFFERING -> {
                        mPlaybackState = PlaybackState.BUFFERING
                        playPause.visibility = View.GONE
                        progressbar.visibility = View.VISIBLE
                        if (!playerView.isControllerFullyVisible) {
                            playerView.setShowBuffering(SHOW_BUFFERING_ALWAYS)
                        }
                    }

                    Player.STATE_READY -> {
                        playPause.visibility = View.VISIBLE
                        progressbar.visibility = View.GONE
                        if (!playerView.isControllerFullyVisible) {
                            playerView.setShowBuffering(SHOW_BUFFERING_NEVER)
                        }
                    }

                    Player.STATE_ENDED -> {
                        playPause.setImageResource(R.drawable.ic_play)
                        close.performClick()
                    }

                    Player.STATE_IDLE -> {
                        mPlaybackState = PlaybackState.IDLE
                    }
                }
            }

            override fun onTracksChanged(tracks: Tracks) {
                super.onTracksChanged(tracks)
                extractQualityOptionsFromTracks(tracks)
            }
        })
        player.playWhenReady = true
    }

    private fun extractQualityOptionsFromTracks(tracks: Tracks) {
        val videoTracks = mutableListOf<QualityOption>()

        tracks.groups.forEachIndexed { groupIndex, group ->
            if (group.type == C.TRACK_TYPE_VIDEO) {
                for (trackIndex in 0 until group.length) {
                    val format = group.getTrackFormat(trackIndex)
                    if (format.height > 0) {
                        videoTracks.add(
                            QualityOption(
                                displayName = "${format.height}p",
                                height = format.height,
                                width = format.width,
                                bitrate = format.bitrate,
                                groupIndex = groupIndex,
                                trackIndex = trackIndex
                            )
                        )
                    }
                }
            }
        }

        // Remove duplicates and sort
        availableQualities =
            videoTracks.distinctBy { it.height }.sortedByDescending { it.height }.toMutableList()
                .apply { add(0, QualityOption("Auto", -1, -1, -1, -1, -1)) }
    }

    private var lastClicked1: Long = -1L

    @SuppressLint("ClickableViewAccessibility")
    private fun initializeViews() {
        shareMovieLinkIv = findViewById(R.id.iv_share_movie)
        playerView = findViewById(R.id.exo_player_view)
        customPlayback = findViewById(R.id.custom_playback)
        layoutBrightness = findViewById(R.id.layout_brightness)
        brightnessSeekbar = findViewById(R.id.brightness_seek)
        brightnessSeekbar.isEnabled = false
        layoutVolume = findViewById(R.id.layout_volume)
        volumeSeekBar = findViewById(R.id.volume_seek)
        volumeSeekBar.isEnabled = false
        close = findViewById(R.id.video_close)
        pip = findViewById(R.id.video_pip)
        more = findViewById(R.id.video_more)
        title = findViewById(R.id.video_title)
        title1 = findViewById(R.id.video_title1)
        title.text = titleText
        title1.text = titleText

        rewind = findViewById(R.id.video_rewind)
        forward = findViewById(R.id.video_forward)
        playPause = findViewById(R.id.video_play_pause)
        progressbar = findViewById(R.id.video_progress_bar)
        timer = findViewById(R.id.timer)

        videoPosition = findViewById(R.id.video_position)
        exoPosition = findViewById(R.id.exo_position)

        zoom = findViewById(R.id.zoom)
        orientation = findViewById(R.id.orientation)
        exoProgress = findViewById(R.id.exo_progress)

        findViewById<PlayerView>(R.id.exo_player_view).setOnTouchListener { _, motionEvent ->
            if (motionEvent.pointerCount == 2) {
                scaleGestureDetector.onTouchEvent(motionEvent)
            } else if (!playerView.isControllerFullyVisible && motionEvent.pointerCount == 1) {
                gestureDetector.onTouchEvent(motionEvent)
                if (motionEvent.action == MotionEvent.ACTION_UP) {
                    layoutBrightness.visibility = View.GONE
                    layoutVolume.visibility = View.GONE
                }
            }
            return@setOnTouchListener true
        }
    }

    @SuppressLint("SetTextI18n", "ClickableViewAccessibility")
    private fun initializeClickListeners() {
        customPlayback.setOnTouchListener { _, motionEvent ->
            if (motionEvent.pointerCount == 1 && motionEvent.action == MotionEvent.ACTION_UP) {
                lastClicked1 = if (lastClicked1 == -1L) {
                    System.currentTimeMillis()
                } else {
                    if (isDoubleClicked(lastClicked1)) {
                        if (::player.isInitialized) {
                            if (motionEvent.x < sWidth / 2) {
                                player.seekTo(player.currentPosition - SEEK_INCREMENT_MS)
                            } else {
                                player.seekTo(player.currentPosition + SEEK_INCREMENT_MS)
                            }
                        }
                    } else {
                        playerView.hideController()
                    }
                    -1L
                }

                // ✅ FIXED: Store runnable for explicit removal
                hideControllerRunnable?.let { mainHandler.removeCallbacks(it) }
                hideControllerRunnable = Runnable {
                    if (lastClicked1 != -1L) {
                        playerView.hideController()
                        lastClicked1 = -1L
                    }
                }.also { mainHandler.postDelayed(it, DOUBLE_CLICK_TIMEOUT_MS) }
            }
            return@setOnTouchListener true
        }

        shareMovieLinkIv.setOnClickListener {
            shareMovieLink()
        }

        close.setOnClickListener {
            if (::player.isInitialized && player.isPlaying) {
                player.stop()
            }
            val intent = Intent()
            intent.putExtra(
                "position",
                if (::player.isInitialized) player.currentPosition / 1000 else 0
            )
            intent.putExtra("duration", if (::player.isInitialized) player.duration / 1000 else 0)
            setResult(playerActivityFinish, intent)
            finish()
        }
        pip.setOnClickListener {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // For Android S (API 31) and above
                val params = PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(PIP_ASPECT_RATIO_WIDTH, PIP_ASPECT_RATIO_HEIGHT))
                    .setAutoEnterEnabled(false).build()
                enterPipModeSafely(params)
            } else {
                // For Android O (API 26) to R (API 30)
                val params = PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(PIP_ASPECT_RATIO_WIDTH, PIP_ASPECT_RATIO_HEIGHT))
                    .build()
                enterPipModeSafely(params)
            }
        }
        more.setOnClickListener {
            showSettingsBottomSheet()
        }
        rewind.setOnClickListener {
            if (::player.isInitialized) {
                player.seekTo(player.currentPosition - SEEK_INCREMENT_MS)
            }
        }
        forward.setOnClickListener {
            if (::player.isInitialized) {
                player.seekTo(player.currentPosition + SEEK_INCREMENT_MS)
            }
        }
        playPause.setOnClickListener {
            if (::player.isInitialized) {
                if (player.isPlaying) {
                    player.pause()
                } else {
                    player.play()
                }
            }
        }

        zoom.setOnClickListener {
            when (playerView.resizeMode) {
                AspectRatioFrameLayout.RESIZE_MODE_ZOOM -> {
                    zoom.setImageResource(R.drawable.ic_fit)
                    playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
                }

                AspectRatioFrameLayout.RESIZE_MODE_FILL -> {
                    zoom.setImageResource(R.drawable.ic_crop_fit)
                    playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                }

                AspectRatioFrameLayout.RESIZE_MODE_FIT -> {
                    zoom.setImageResource(R.drawable.ic_stretch)
                    playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FILL
                }

                AspectRatioFrameLayout.RESIZE_MODE_FIXED_HEIGHT -> {}
                AspectRatioFrameLayout.RESIZE_MODE_FIXED_WIDTH -> {}
            }
        }
        orientation.setOnClickListener {
            requestedOrientation =
                if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
                    ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                } else {
                    ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
                }

            // ✅ FIXED: Store runnable for explicit removal
            orientationRestoreRunnable?.let { mainHandler.removeCallbacks(it) }
            orientationRestoreRunnable = Runnable {
                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR
            }.also { mainHandler.postDelayed(it, ORIENTATION_CHANGE_DELAY_MS) }
        }
    }


    /**
     * Safely enters Picture-in-Picture mode with error handling
     * @param params PictureInPictureParams for PiP configuration
     * @return true if PiP was entered successfully, false otherwise
     */
    private fun enterPipModeSafely(params: PictureInPictureParams): Boolean {
        return try {
            enterPictureInPictureMode(params)
            true
        } catch (e: Exception) {
            // Catch all exceptions including system bugs (NPE, RemoteException, etc.)
            e.printStackTrace()
            false
        }
    }

    override fun onUserLeaveHint() {
        val supportsPiP = packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
        if (supportsPiP && !isInPictureInPictureMode) {
            // Only enter PiP if not already in PiP mode
            val params = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PictureInPictureParams.Builder().setAspectRatio(
                    Rational(
                        PIP_ASPECT_RATIO_WIDTH_HINT, PIP_ASPECT_RATIO_HEIGHT_HINT
                    )
                ).setAutoEnterEnabled(false).build()
            } else {
                PictureInPictureParams.Builder().setAspectRatio(
                    Rational(
                        PIP_ASPECT_RATIO_WIDTH_HINT, PIP_ASPECT_RATIO_HEIGHT_HINT
                    )
                ).build()
            }
            enterPipModeSafely(params)
        }
    }

    private fun shareMovieLink() {
        val url = playerConfiguration.movieShareLink
        val intent = Intent(Intent.ACTION_SEND)
        intent.type = "text/html"
        intent.putExtra(Intent.EXTRA_TEXT, url)
        val chooser = Intent.createChooser(intent, "Share using...")
        startActivity(chooser)
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean, newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        if (isInPictureInPictureMode) {
            // Entering PiP mode
            playerView.hideController()
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            wasInPictureInPicture = true
        } else {
            // Exiting PiP mode - determine if user dismissed PiP or returned to app
            // Wait a bit for lifecycle to settle (orientation/fullscreen changes, etc.)

            // ✅ FIXED: Store runnable for explicit removal
            pipDismissCheckRunnable?.let { mainHandler.removeCallbacks(it) }
            pipDismissCheckRunnable = Runnable {
                val isVisible =
                    lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.STARTED)
                val isConfigChange = isChangingConfigurations
                if (!isVisible && !isConfigChange && wasInPictureInPicture) {
                    // PiP window was closed (user dismissed it) → finish with result
                    if (::player.isInitialized) {
                        player.stop()
                    }
                    val intent = Intent()
                    intent.putExtra(
                        "position", if (::player.isInitialized) player.currentPosition / 1000 else 0
                    )
                    intent.putExtra(
                        "duration", if (::player.isInitialized) player.duration / 1000 else 0
                    )
                    setResult(playerActivityFinish, intent)
                    finish()
                } else {
                    // Returned to the app or orientation/fullscreen change → restore UI
                    playerView.showController()
                }
                wasInPictureInPicture = false
            }.also { mainHandler.postDelayed(it, 300) }
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        currentOrientation = newConfig.orientation
        if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            setFullScreen()
            title.text = title1.text
            title.visibility = View.VISIBLE
            title1.text = ""
            title1.visibility = View.GONE
            zoom.visibility = View.VISIBLE
            when (currentBottomSheet) {
                BottomSheet.SETTINGS -> {
                    backButtonSettingsBottomSheet?.visibility = View.VISIBLE
                }

                BottomSheet.QUALITY_OR_SPEED -> backButtonQualitySpeedBottomSheet?.visibility =
                    View.VISIBLE

                BottomSheet.NONE -> {}
            }
        } else {
            cutFullScreen()
            title1.text = title.text
            title1.visibility = View.VISIBLE
            title.text = ""
            title.visibility = View.INVISIBLE
            zoom.visibility = View.GONE
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
            when (currentBottomSheet) {

                BottomSheet.SETTINGS -> {
                    backButtonSettingsBottomSheet?.visibility = View.GONE
                }

                BottomSheet.QUALITY_OR_SPEED -> backButtonSettingsBottomSheet?.visibility =
                    View.GONE

                BottomSheet.NONE -> {}
            }
        }
    }

    private fun setFullScreen() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, findViewById(R.id.player_activity)).let { controller ->
            controller.hide(WindowInsetsCompat.Type.systemBars())
            controller.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
    }

    private fun cutFullScreen() {
        WindowCompat.setDecorFitsSystemWindows(window, true)
        WindowInsetsControllerCompat(window, findViewById(R.id.player_activity)).show(
            WindowInsetsCompat.Type.systemBars()
        )
    }

    private var currentBottomSheet = BottomSheet.NONE

    private fun dismissAllBottomSheets() {
        // Create a copy of the list to avoid concurrent modification
        val bottomSheetsToClose = listOfAllOpenedBottomSheets.toList()
        listOfAllOpenedBottomSheets.clear()

        for (bottomSheet in bottomSheetsToClose) {
            try {
                if (bottomSheet.isShowing) {
                    bottomSheet.dismiss()
                }
            } catch (_: Exception) {
                // Error dismissing bottom sheet
            }
        }

        // Reset bottom sheet states
        isSettingsBottomSheetOpened = false
        isQualitySpeedBottomSheetOpened = false
        currentBottomSheet = BottomSheet.NONE
    }

    private var speeds = mutableListOf("0.5x", "1.0x", "1.5x", "2.0x")
    private var currentQuality = ""
    private var currentSpeed = "1.0x"
    private var qualityText: TextView? = null
    private var speedText: TextView? = null

    private var backButtonSettingsBottomSheet: ImageView? = null
    private fun showSettingsBottomSheet() {
        if (isSettingsBottomSheetOpened) {
            return
        }
        isSettingsBottomSheetOpened = true
        currentBottomSheet = BottomSheet.SETTINGS
        val bottomSheetDialog = BottomSheetDialog(this, R.style.BottomSheetDialog)
        listOfAllOpenedBottomSheets.add(bottomSheetDialog)
        bottomSheetDialog.behavior.state = BottomSheetBehavior.STATE_EXPANDED
        bottomSheetDialog.setContentView(R.layout.settings_bottom_sheet)
        backButtonSettingsBottomSheet = bottomSheetDialog.findViewById(R.id.settings_sheet_back)
        if (resources.configuration.orientation == Configuration.ORIENTATION_PORTRAIT) {
            backButtonSettingsBottomSheet?.visibility = View.GONE
        } else {
            backButtonSettingsBottomSheet?.visibility = View.VISIBLE
        }
        backButtonSettingsBottomSheet?.setOnClickListener {
            bottomSheetDialog.dismiss()
        }
        val quality = bottomSheetDialog.findViewById<LinearLayout>(R.id.quality)
        val speed = bottomSheetDialog.findViewById<LinearLayout>(R.id.speed)
        bottomSheetDialog.findViewById<TextView>(R.id.quality_settings_text)?.text =
            playerConfiguration.qualityText
        bottomSheetDialog.findViewById<TextView>(R.id.speed_settings_text)?.text =
            playerConfiguration.speedText
        qualityText = bottomSheetDialog.findViewById(R.id.quality_settings_value_text)
        speedText = bottomSheetDialog.findViewById(R.id.speed_settings_value_text)
        qualityText?.text = currentQuality
        speedText?.text = currentSpeed
        quality?.setOnClickListener {
            if (availableQualities.isNotEmpty()) {
                val qualitiesList = ArrayList(availableQualities.map { it.displayName })
                showQualitySpeedSheet(currentQuality, qualitiesList, true)
            }
        }
        speed?.setOnClickListener {
            showQualitySpeedSheet(currentSpeed, ArrayList(speeds), false)
        }
        bottomSheetDialog.show()
        bottomSheetDialog.setOnDismissListener {
            isSettingsBottomSheetOpened = false
            currentBottomSheet = BottomSheet.NONE
        }
    }

    private var backButtonQualitySpeedBottomSheet: ImageView? = null
    private fun showQualitySpeedSheet(
        initialValue: String, list: ArrayList<String>, fromQuality: Boolean
    ) {
        if (isQualitySpeedBottomSheetOpened) {
            return
        }
        isQualitySpeedBottomSheetOpened = true
        currentBottomSheet = BottomSheet.QUALITY_OR_SPEED
        val bottomSheetDialog = BottomSheetDialog(this, R.style.BottomSheetDialog)
        listOfAllOpenedBottomSheets.add(bottomSheetDialog)
        bottomSheetDialog.behavior.isDraggable = false
        bottomSheetDialog.behavior.state = BottomSheetBehavior.STATE_EXPANDED
        bottomSheetDialog.setContentView(R.layout.quality_speed_sheet)
        backButtonQualitySpeedBottomSheet =
            bottomSheetDialog.findViewById(R.id.quality_speed_sheet_back)
        if (resources.configuration.orientation == Configuration.ORIENTATION_PORTRAIT) {
            backButtonQualitySpeedBottomSheet?.visibility = View.GONE
        } else {
            backButtonQualitySpeedBottomSheet?.visibility = View.VISIBLE
        }
        backButtonQualitySpeedBottomSheet?.setOnClickListener {
            bottomSheetDialog.dismiss()
        }

        if (fromQuality) {
            bottomSheetDialog.findViewById<TextView>(R.id.quality_speed_text)?.text =
                playerConfiguration.qualityText
        } else {
            bottomSheetDialog.findViewById<TextView>(R.id.quality_speed_text)?.text =
                playerConfiguration.speedText
        }
        val listView = bottomSheetDialog.findViewById<View>(R.id.quality_speed_listview) as ListView
        //sorting
        val l = mutableListOf<String>()
        if (fromQuality) {
            var auto = ""
            list.forEach {
                if (it.substring(0, it.length - 1).toIntOrNull() != null) {
                    l.add(it)
                } else {
                    auto = it
                }
            }
            // Use efficient sorting instead of bubble sort
            l.sortByDescending { quality ->
                quality.substring(0, quality.length - 1).toIntOrNull() ?: 0
            }
            if (auto.isNotEmpty()) {
                l.add(0, auto)
            }
        } else {
            l.addAll(list)
        }
        val adapter = QualitySpeedAdapter(
            initialValue,
            this,
            l as ArrayList<String>,
            (object : QualitySpeedAdapter.OnClickListener {
                override fun onClick(position: Int) {
                    if (fromQuality) {
                        handleQualitySelection(position)
                    } else {
                        currentSpeed = l[position]
                        speedText?.text = currentSpeed
                        player.setPlaybackSpeed(currentSpeed.replace("x", "").toFloat())
                    }
                    bottomSheetDialog.dismiss()
                }
            })
        )
        listView.adapter = adapter
        bottomSheetDialog.show()
        bottomSheetDialog.setOnDismissListener {
            currentBottomSheet = BottomSheet.SETTINGS
            isQualitySpeedBottomSheetOpened = false
        }
    }

    private fun handleQualitySelection(position: Int) {
        val selectedQuality = availableQualities[position]
        currentQuality = selectedQuality.displayName
        qualityText?.text = currentQuality

        if (selectedQuality.displayName == "Auto") {
            // Auto - clear overrides for adaptive streaming
            player.trackSelectionParameters =
                player.trackSelectionParameters.buildUpon().clearOverridesOfType(C.TRACK_TYPE_VIDEO)
                    .build()
        } else {
            // Manual quality - set max/min video size
            player.trackSelectionParameters = player.trackSelectionParameters.buildUpon()
                .setMaxVideoSize(selectedQuality.width, selectedQuality.height)
                .setMinVideoSize(selectedQuality.width, selectedQuality.height).build()
        }
    }

    override fun onDown(p0: MotionEvent): Boolean = false

    override fun onShowPress(p0: MotionEvent) = Unit

    private var lastClicked: Long = -1L
    override fun onSingleTapUp(event: MotionEvent): Boolean {
        lastClicked = if (lastClicked == -1L) {
            System.currentTimeMillis()
        } else {
            if (isDoubleClicked(lastClicked)) {
                if (::player.isInitialized) {
                    if (event.x < sWidth / 2) {
                        player.seekTo(player.currentPosition - SEEK_INCREMENT_MS)
                    } else {
                        player.seekTo(player.currentPosition + SEEK_INCREMENT_MS)
                    }
                }
            } else {
                playerView.showController()
            }
            -1L
        }

        // ✅ FIXED: Store runnable for explicit removal
        showControllerRunnable?.let { mainHandler.removeCallbacks(it) }
        showControllerRunnable = Runnable {
            if (lastClicked != -1L) {
                playerView.showController()
                lastClicked = -1L
            }
        }.also { mainHandler.postDelayed(it, DOUBLE_CLICK_TIMEOUT_MS) }

        return false
    }

    private fun isDoubleClicked(lastClicked: Long): Boolean =
        System.currentTimeMillis() - lastClicked <= DOUBLE_CLICK_TIMEOUT_MS

    override fun onLongPress(p0: MotionEvent) = Unit

    override fun onFling(e1: MotionEvent?, p0: MotionEvent, p2: Float, p3: Float): Boolean = false

    override fun onScroll(
        e1: MotionEvent?, event: MotionEvent, distanceX: Float, distanceY: Float
    ): Boolean {
        if (abs(distanceX) < abs(distanceY)) {
            if (event.x < sWidth / 2) {
                layoutBrightness.visibility = View.VISIBLE
                layoutVolume.visibility = View.GONE
                val increase = distanceY > 0
                val newValue: Double =
                    if (increase) brightness + BRIGHTNESS_STEP else brightness - BRIGHTNESS_STEP
                if (newValue in 0.0..maxBrightness) {
                    brightness = newValue
                    brightnessSeekbar.progress = brightness.toInt()
                    setScreenBrightness(brightness.toInt())
                }
            } else {
                layoutBrightness.visibility = View.GONE
                layoutVolume.visibility = View.VISIBLE
                val increase = distanceY > 0
                val newValue = if (increase) volume + VOLUME_STEP else volume - VOLUME_STEP
                if (newValue in 0.0..maxVolume) {
                    volume = newValue
                    volumeSeekBar.progress = volume.toInt()
                    audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume.toInt(), 0)
                }
            }
        }
        return true
    }

    private fun setScreenBrightness(value: Int) {
        val lp = this.window.attributes
        lp.screenBrightness = SCREEN_BRIGHTNESS_SCALE * value
        this.window.attributes = lp
    }

    private var scaleFactor: Float = 0f
    override fun onScale(detector: ScaleGestureDetector): Boolean {
        scaleFactor = detector.scaleFactor
        return true
    }

    override fun onScaleBegin(p0: ScaleGestureDetector): Boolean {
        return true
    }

    override fun onScaleEnd(p0: ScaleGestureDetector) {
        if (scaleFactor > 1) {
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
        } else {
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
        }
    }

    override fun onAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS -> {
                if (::player.isInitialized) {
                    player.pause()
                }
                playerView.hideController()
            }
        }
    }

    private fun setAudioFocus() {
        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN).setAudioAttributes(
            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE).build()
        ).setAcceptsDelayedFocusGain(true).setOnAudioFocusChangeListener(this).build()
        audioFocusRequest = request
        audioManager.requestAudioFocus(request)
    }

    private fun abandonAudioFocus() {
        audioFocusRequest?.let {
            audioManager.abandonAudioFocusRequest(it)
        }
    }

    // ✅ FIXED: Helper to cancel all pending runnables
    private fun cancelAllPendingRunnables() {
        hideControllerRunnable?.let { mainHandler.removeCallbacks(it) }
        showControllerRunnable?.let { mainHandler.removeCallbacks(it) }
        orientationRestoreRunnable?.let { mainHandler.removeCallbacks(it) }
        pipDismissCheckRunnable?.let { mainHandler.removeCallbacks(it) }

        hideControllerRunnable = null
        showControllerRunnable = null
        orientationRestoreRunnable = null
        pipDismissCheckRunnable = null
    }

    override fun onDestroy() {
        super.onDestroy()

        // ✅ FIXED: Cancel all pending runnables explicitly
        cancelAllPendingRunnables()

        try {
            // Clean up player resources
            if (::player.isInitialized) {
                player.stop()
                player.clearVideoSurface()
                playerView.player = null
                player.release()
            }

            // Remove any remaining handler callbacks to prevent memory leaks
            mainHandler.removeCallbacksAndMessages(null)

            // Abandon audio focus
            abandonAudioFocus()

            // Unregister broadcast receiver safely
            if (isNetworkReceiverRegistered && ::networkChangeReceiver.isInitialized) {
                unregisterReceiver(networkChangeReceiver)
                isNetworkReceiverRegistered = false
            }
        } catch (_: IllegalArgumentException) {
            // Receiver was not registered, ignore
        }

        // Dismiss all bottom sheets
        dismissAllBottomSheets()
    }
}
