package uz.shs.video_player.activities

import android.provider.Settings
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
import android.util.Log
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
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
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
import uz.shs.video_player.extraArgument
import uz.shs.video_player.playerActivityFinish
import uz.shs.video_player.R
import uz.shs.video_player.adapters.QualitySpeedAdapter
import uz.shs.video_player.models.BottomSheet
import uz.shs.video_player.models.PlayerConfiguration
import uz.shs.video_player.services.NetworkChangeReceiver
import kotlin.math.abs
import androidx.core.net.toUri
import androidx.core.view.ViewCompat
import androidx.core.view.updatePadding

@Suppress("DEPRECATION", "UNNECESSARY_NOT_NULL_ASSERTION")
@UnstableApi
class VideoPlayerActivity : AppCompatActivity(), GestureDetector.OnGestureListener,
    ScaleGestureDetector.OnScaleGestureListener, AudioManager.OnAudioFocusChangeListener {

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
    private var brightness: Double = 15.0
    private var maxBrightness: Double = 31.0
    private var volume: Double = 0.0
    private var maxVolume: Double = 0.0
    private var sWidth: Int = 0
    private val tag = "TAG1"
    private var currentOrientation: Int = Configuration.ORIENTATION_PORTRAIT
    private var titleText = ""
    private lateinit var url: String
    private var mPlaybackState: PlaybackState? = null

    enum class PlaybackState {
        PLAYING, PAUSED, BUFFERING, IDLE
    }

    @SuppressLint("AppCompatMethod")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        onBackPressedDispatcher.addCallback(this, onBackPressedCallback)
        setContentView(R.layout.activity_player)
        actionBar?.hide()
        val window = window
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
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
        if (config == null) {
            Log.e(tag, "PlayerConfiguration is null")
            finish()
            return
        }
        playerConfiguration = config
        currentQuality =
            if (playerConfiguration.initialResolution.isNotEmpty()) playerConfiguration.initialResolution.keys.first() else ""
        titleText = playerConfiguration.title
        url = playerConfiguration.initialResolution.values.first().ifEmpty { "" }

        initializeViews()
        mPlaybackState = PlaybackState.PLAYING

        initializeClickListeners()

        sWidth = Resources.getSystem().displayMetrics.widthPixels
        gestureDetector = GestureDetector(this, this)
        scaleGestureDetector = ScaleGestureDetector(this, this)
        brightnessSeekbar.max = 30
        brightnessSeekbar.progress = 15
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        setAudioFocus()
        maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).toDouble()
        volume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble()
        volumeSeekBar.max = maxVolume.toInt()
        maxVolume += 1.0
        volumeSeekBar.progress = volume.toInt()
        playVideo()
        listenConnection()
    }

    private fun listenConnection() {
        // IntentFilter create
        intentFilter = IntentFilter("android.net.conn.CONNECTIVITY_CHANGE")

        // NetworkChangeReceiver create
        networkChangeReceiver = object : NetworkChangeReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                super.onReceive(context, intent)
                if (isNetworkAvailable(context!!)) {
                    Log.d(tag, "Reconnect player: Internet bor")
                    rePlayVideo()
                }
            }
        }

        // BroadcastReceiver active
        registerReceiver(networkChangeReceiver, intentFilter)
    }

    fun isNetworkAvailable(context: Context?): Boolean {
        if (context == null) return false

        val connectivityManager =
            context.getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
        val capabilities =
            connectivityManager.getNetworkCapabilities(connectivityManager.activeNetwork)
                ?: return false

        // Flexible connectivity check: Any of the specified transports indicates usable connection
        if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) || capabilities.hasTransport(
                NetworkCapabilities.TRANSPORT_WIFI
            ) || capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
        ) {
            return true
        }

        // Optional: Check for validated internet connectivity
        if (capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)) {
            return true
        }

        return false
    }

    private fun rePlayVideo() {
        player.prepare()
        player.play()
    }

    private val onBackPressedCallback: OnBackPressedCallback =
        object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (player.isPlaying) {
                    player.stop()
                }
                val intent = Intent()
                intent.putExtra("position", player.currentPosition / 1000)
                intent.putExtra("duration", player.duration / 1000)
                setResult(playerActivityFinish, intent)
                finish()
            }
        }

    override fun onPause() {
        super.onPause()
        val isPlaying = player.isPlaying
        player.playWhenReady = false
        if (isInPictureInPictureMode) {
            player.playWhenReady = isPlaying
            dismissAllBottomSheets()
        }
    }

    override fun onResume() {
        setAudioFocus()
        super.onResume()
        player.playWhenReady = true
        try {
            // Retrieve and set brightness
            val oldBrightness: Int = Settings.System.getInt(
                this.contentResolver, Settings.System.SCREEN_BRIGHTNESS
            )
            brightness = oldBrightness.toDouble() // Keep conversion if necessary
            brightnessSeekbar.progress = oldBrightness
        } catch (e: Settings.SettingNotFoundException) {
            e.printStackTrace()  // Handle error, maybe notify the user or log appropriately
        }
    }

    override fun onRestart() {
        super.onRestart()
        player.playWhenReady = true
    }

    override fun onStop() {
        super.onStop()
        if (isInPictureInPictureMode) {
            player.release()
            finish()
        }
    }

    private fun playVideo() {
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
                Log.d(tag, "onPlayerError: ${error.errorCode}")
            }

            override fun onMediaMetadataChanged(mediaMetadata: MediaMetadata) {
                Log.d(tag, "onMediaMetadataChanged: ${mediaMetadata.title}")
                super.onMediaMetadataChanged(mediaMetadata)
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
        })
        player.playWhenReady = true
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

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            pip.visibility = View.GONE
        }

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
                        if (motionEvent!!.x < sWidth / 2) {
                            player.seekTo(player.currentPosition - 10000)
                        } else {
                            player.seekTo(player.currentPosition + 10000)
                        }
                    } else {
                        playerView.hideController()
                    }
                    -1L
                }
                Handler(Looper.getMainLooper()).postDelayed({
                    if (lastClicked1 != -1L) {
                        playerView.hideController()
                        lastClicked1 = -1L
                    }
                }, 300)
            }
            return@setOnTouchListener true
        }

        shareMovieLinkIv.setOnClickListener {
            shareMovieLink()
        }

        close.setOnClickListener {
            if (player.isPlaying) {
                player.stop()
            }
            val intent = Intent()
            intent.putExtra("position", player.currentPosition / 1000)
            intent.putExtra("duration", player.duration / 1000)
            setResult(playerActivityFinish, intent)
            finish()
        }
        pip.setOnClickListener {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // For Android S (API 31) and above
                val params = PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9))
                    .setAutoEnterEnabled(false).build()
                enterPictureInPictureMode(params)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // For Android O (API 26) to R (API 30)
                val params =
                    PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9)).build()
                enterPictureInPictureMode(params)
            } else {
                // For devices below API 26
                Toast.makeText(this, "Picture-in-Picture not supported!", Toast.LENGTH_SHORT).show()
            }

        }
        more.setOnClickListener {
            showSettingsBottomSheet()
        }
        rewind.setOnClickListener {
            player.seekTo(player.currentPosition - 10000)
        }
        forward.setOnClickListener {
            player.seekTo(player.currentPosition + 10000)

        }
        playPause.setOnClickListener {
            if (player.isPlaying) {
                player.pause()
            } else {
                player.play()
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
            it.postDelayed({
                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR
            }, 3000)
        }
    }


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onUserLeaveHint() {
        val supportsPiP = packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
        if (supportsPiP) {
            val params = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PictureInPictureParams.Builder().setAspectRatio(Rational(100, 50))
                    .setAutoEnterEnabled(false).build()
            } else {
                PictureInPictureParams.Builder().setAspectRatio(Rational(100, 50)).build()
            }
            enterPictureInPictureMode(params)
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
            if (isInPictureInPictureMode) {
                playerView.hideController()
                playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            } else {
                playerView.showController()
                playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FILL
            }
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
                BottomSheet.EPISODES -> {
                    backButtonEpisodeBottomSheet?.visibility = View.VISIBLE
                }

                BottomSheet.SETTINGS -> {
                    backButtonSettingsBottomSheet?.visibility = View.VISIBLE
                }

                BottomSheet.TV_PROGRAMS -> {}
                BottomSheet.QUALITY_OR_SPEED -> backButtonQualitySpeedBottomSheet?.visibility =
                    View.VISIBLE

                BottomSheet.CHANNELS -> {}
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
                BottomSheet.EPISODES -> {
                    backButtonEpisodeBottomSheet?.visibility = View.GONE
                }

                BottomSheet.SETTINGS -> {
                    backButtonSettingsBottomSheet?.visibility = View.GONE
                }

                BottomSheet.TV_PROGRAMS -> {}
                BottomSheet.QUALITY_OR_SPEED -> backButtonSettingsBottomSheet?.visibility =
                    View.GONE

                BottomSheet.CHANNELS -> {}
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

    private var backButtonEpisodeBottomSheet: ImageView? = null
    private fun dismissAllBottomSheets() {
        for (bottomSheet in listOfAllOpenedBottomSheets) {
            bottomSheet.dismiss()
        }
        listOfAllOpenedBottomSheets.clear()
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
            if (playerConfiguration.resolutions.isNotEmpty()) {
                val resolutionsList = ArrayList(playerConfiguration.resolutions.keys)
                showQualitySpeedSheet(
                    currentQuality, resolutionsList, true
                )
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
            for (i in 0 until l.size) {
                for (j in i until l.size) {
                    val first = l[i]
                    val second = l[j]
                    if (first.substring(0, first.length - 1).toInt() < second.substring(
                            0, second.length - 1
                        ).toInt()
                    ) {
                        val a = l[i]
                        l[i] = l[j]
                        l[j] = a
                    }
                }
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
                        currentQuality = l[position]
                        qualityText?.text = currentQuality
                        if (player.isPlaying) {
                            player.pause()
                        }
                        val url = playerConfiguration.resolutions[currentQuality]
                        val bitrate: Int? = url?.toIntOrNull()
                        if (bitrate != null) {
                            player.trackSelectionParameters =
                                player.trackSelectionParameters.buildUpon()
                                    .setMaxVideoBitrate(bitrate).build()
                            player.playWhenReady = true
                        } else {
                            player.trackSelectionParameters =
                                player.trackSelectionParameters.buildUpon()
                                    .setMaxVideoBitrate(Integer.MAX_VALUE).build()
                            player.playWhenReady = true
                        }
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

    override fun onDown(p0: MotionEvent): Boolean = false

    override fun onShowPress(p0: MotionEvent) = Unit

    private var lastClicked: Long = -1L
    override fun onSingleTapUp(event: MotionEvent): Boolean {
        lastClicked = if (lastClicked == -1L) {
            System.currentTimeMillis()
        } else {
            if (isDoubleClicked(lastClicked)) {
                if (event.x < sWidth / 2) {
                    player.seekTo(player.currentPosition - 10000)
                } else {
                    player.seekTo(player.currentPosition + 10000)
                }
            } else {
                playerView.showController()
            }
            -1L
        }
        Handler(Looper.getMainLooper()).postDelayed({
            if (lastClicked != -1L) {
                playerView.showController()
                lastClicked = -1L
            }
        }, 300)
        return false
    }

    private fun isDoubleClicked(lastClicked: Long): Boolean =
        lastClicked - System.currentTimeMillis() <= 300

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
                val newValue: Double = if (increase) brightness + 0.2 else brightness - 0.2
                if (newValue in 0.0..maxBrightness) brightness = newValue
                brightnessSeekbar.progress = brightness.toInt()
                setScreenBrightness(brightness.toInt())
            } else {
                layoutBrightness.visibility = View.GONE
                layoutVolume.visibility = View.VISIBLE
                val increase = distanceY > 0
                val newValue = if (increase) volume + 0.2 else volume - 0.2
                if (newValue in 0.0..maxVolume) volume = newValue
                volumeSeekBar.progress = volume.toInt()
                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume.toInt(), 0)
            }
        }
        return true
    }

    private fun setScreenBrightness(value: Int) {
        val d = 1.0f / 30
        val lp = this.window.attributes
        lp.screenBrightness = d * value
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
                player.pause()
                playerView.hideController()
            }
        }
    }

    private fun setAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioManager.requestAudioFocus(
                AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN).setAudioAttributes(
                    AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
                ).setAcceptsDelayedFocusGain(true).setOnAudioFocusChangeListener(this).build()
            )
        } else {
            @Suppress("DEPRECATION") audioManager.requestAudioFocus(
                this, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN
            )
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // BroadcastReceiver on destroy
        unregisterReceiver(networkChangeReceiver)
    }
}
