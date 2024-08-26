package uz.shs.video_player.activities

import android.annotation.SuppressLint
import android.app.PictureInPictureParams
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.content.res.Resources
import android.graphics.Color
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
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
import androidx.viewpager2.widget.ViewPager2
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import uz.shs.video_player.EXTRA_ARGUMENT
import uz.shs.video_player.PLAYER_ACTIVITY_FINISH
import uz.shs.video_player.R
import uz.shs.video_player.adapters.EpisodePagerAdapter
import uz.shs.video_player.adapters.QualitySpeedAdapter
import uz.shs.video_player.adapters.TvCategoryPagerAdapter
import uz.shs.video_player.adapters.TvProgramsPagerAdapter
import uz.shs.video_player.models.BottomSheet
import uz.shs.video_player.models.MegogoStreamResponse
import uz.shs.video_player.models.PlayerConfiguration
import uz.shs.video_player.models.PremierStreamResponse
import uz.shs.video_player.models.TvChannelResponse
import uz.shs.video_player.retrofit.Common
import uz.shs.video_player.retrofit.RetrofitService
//import uz.shs.video_player.services.DownloadUtil
import uz.shs.video_player.services.NetworkChangeReceiver
import kotlin.math.abs

@Suppress("DEPRECATION")
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
    private lateinit var live: LinearLayout
    private lateinit var episodesButton: LinearLayout
    private lateinit var episodesText: TextView
    private lateinit var nextButton: LinearLayout
    private lateinit var nextText: TextView
    private lateinit var tvProgramsButton: ImageView
    private lateinit var tvChannels: ImageView
    private lateinit var tvChannelsButton: LinearLayout
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
    private var seasonIndex: Int = 0
    private var episodeIndex: Int = 0
    private var retrofitService: RetrofitService? = null
    private val tag = "TAG1"
    private var currentOrientation: Int = Configuration.ORIENTATION_PORTRAIT
    private var titleText = ""
    private var url: String? = null
    private var mPlaybackState: PlaybackState? = null
    private var channelIndex: Int = 0
    private var tvCategoryIndex: Int = 0

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

        playerConfiguration = intent.getSerializableExtra(EXTRA_ARGUMENT) as PlayerConfiguration
        seasonIndex = playerConfiguration.seasonIndex
        episodeIndex = playerConfiguration.episodeIndex
        channelIndex = playerConfiguration.selectChannelIndex
        tvCategoryIndex = playerConfiguration.selectTvCategoryIndex
        currentQuality =
            if (playerConfiguration.initialResolution.isNotEmpty()) playerConfiguration.initialResolution.keys.first() else ""
        titleText = playerConfiguration.title
        url = playerConfiguration.initialResolution.values.first().ifEmpty { "" }

        initializeViews()
        mPlaybackState = PlaybackState.PLAYING

        retrofitService =
            if (playerConfiguration.baseUrl.isNotEmpty()) Common.retrofitService(playerConfiguration.baseUrl) else null
        initializeClickListeners()

        sWidth = Resources.getSystem().displayMetrics.widthPixels
        gestureDetector = GestureDetector(this, this)
        scaleGestureDetector = ScaleGestureDetector(this, this)
        brightnessSeekbar.max = 30
        brightnessSeekbar.progress = 15
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
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
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
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
                setResult(PLAYER_ACTIVITY_FINISH, intent)
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
        player.playWhenReady = true
        if (brightness != 0.0) setScreenBrightness(brightness.toInt())
        super.onResume()
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
            .createMediaSource(MediaItem.fromUri(Uri.parse(url)))
        player = ExoPlayer.Builder(this).build()
        playerView.player = player
        playerView.keepScreenOn = true
        playerView.useController = playerConfiguration.showController
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
        playerConfiguration.resolutions.forEach {
            if (it.key == "480p") {
                currentQuality = "480p"
                val bitrate = it.value.toIntOrNull()
                if (bitrate != null) player.trackSelectionParameters =
                    player.trackSelectionParameters.buildUpon().setMaxVideoBitrate(bitrate).build()
            }
        }
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
        tvChannels = findViewById(R.id.tv_channels)
        if (playerConfiguration.isLive) {
            tvChannelsButton.visibility = View.VISIBLE
        }
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
        if (playerConfiguration.isLive) {
            timer.visibility = View.GONE
        }
        videoPosition = findViewById(R.id.video_position)
        exoPosition = findViewById(R.id.exo_position)
        live = findViewById(R.id.live)
        if (playerConfiguration.isLive) {
            shareMovieLinkIv.visibility = View.GONE
            live.visibility = View.VISIBLE
        }
        episodesButton = findViewById(R.id.button_episodes)
        episodesText = findViewById(R.id.text_episodes)
        if (playerConfiguration.seasons.isNotEmpty()) {
            episodesButton.visibility = View.VISIBLE
            episodesText.text = playerConfiguration.episodeButtonText
        }
        nextButton = findViewById(R.id.button_next)
        nextText = findViewById(R.id.text_next)

        if (playerConfiguration.seasons.isNotEmpty()) if (playerConfiguration.isSerial && !(seasonIndex == playerConfiguration.seasons.size - 1 && episodeIndex == playerConfiguration.seasons[seasonIndex].movies.size - 1)) {
            nextText.text = playerConfiguration.nextButtonText
        }
        tvProgramsButton = findViewById(R.id.button_tv_programs)
        if (playerConfiguration.isLive) {
            tvProgramsButton.visibility = View.VISIBLE
            tvChannels.visibility = View.VISIBLE
        }
        zoom = findViewById(R.id.zoom)
        orientation = findViewById(R.id.orientation)
        exoProgress = findViewById(R.id.exo_progress)
        if (playerConfiguration.isLive) {
            exoProgress.visibility = View.GONE
            rewind.visibility = View.GONE
            forward.visibility = View.GONE
        }
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
            setResult(PLAYER_ACTIVITY_FINISH, intent)
            finish()
        }
        pip.setOnClickListener {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val params = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9))
                        .setAutoEnterEnabled(false).build()
                } else {
                    PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9)).build()
                }
                enterPictureInPictureMode(params)
            } else {
                Toast.makeText(this, "This is my Toast message!", Toast.LENGTH_SHORT).show()
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

        tvChannels.setOnClickListener {
            showChannelsBottomSheet()
        }
        episodesButton.setOnClickListener {
            if (playerConfiguration.seasons.isNotEmpty()) showEpisodesBottomSheet()
        }
        nextButton.setOnClickListener {
            if (playerConfiguration.seasons.isEmpty()) {
                return@setOnClickListener
            }
            if (seasonIndex < playerConfiguration.seasons.size) {
                if (episodeIndex < playerConfiguration.seasons[seasonIndex].movies.size - 1) {
                    episodeIndex++
                } else {
                    seasonIndex++
                }
            }
            if (isLastEpisode()) {
                nextButton.visibility = View.GONE
            } else {
                nextButton.visibility = View.VISIBLE
            }
            title.text =
                "S${seasonIndex + 1} E${episodeIndex + 1} " + playerConfiguration.seasons[seasonIndex].movies[episodeIndex].title
            if (playerConfiguration.isMegogo && playerConfiguration.isSerial) {
                getMegogoStream()
            } else if (playerConfiguration.isPremier && playerConfiguration.isSerial) {
                getPremierStream()
            } else {
                url =
                    playerConfiguration.seasons[seasonIndex].movies[episodeIndex].resolutions[currentQuality]
                val dataSourceFactory: DataSource.Factory = DefaultHttpDataSource.Factory()
                val hlsMediaSource: HlsMediaSource = HlsMediaSource.Factory(dataSourceFactory)
                    .createMediaSource(MediaItem.fromUri(Uri.parse(url)))
                player.setMediaSource(hlsMediaSource)
                player.prepare()
                player.playWhenReady
            }
        }
        tvProgramsButton.setOnClickListener {
            if (playerConfiguration.programsInfoList.isNotEmpty()) showTvProgramsBottomSheet()
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
                    if (playerConfiguration.isLive) {
                        playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                    }
                    ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
                }
            it.postDelayed({
                requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR
            }, 3000)
        }
    }


    @RequiresApi(Build.VERSION_CODES.O)
    override fun onUserLeaveHint() {
        val params = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PictureInPictureParams.Builder().setAspectRatio(Rational(100, 50))
                .setAutoEnterEnabled(false).build()
        } else {
            PictureInPictureParams.Builder().setAspectRatio(Rational(100, 50)).build()
        }
        enterPictureInPictureMode(params)
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

    private fun getMegogoStream() {
        retrofitService?.getMegogoStream(
            playerConfiguration.authorization,
            playerConfiguration.sessionId,
            playerConfiguration.seasons[seasonIndex].movies[episodeIndex].id,
            playerConfiguration.megogoAccessToken
        )?.enqueue(object : Callback<MegogoStreamResponse> {
            override fun onResponse(
                call: Call<MegogoStreamResponse>, response: Response<MegogoStreamResponse>
            ) {
                val body = response.body()
                if (body != null) {
                    val map: HashMap<String, String> = hashMapOf()
                    map[playerConfiguration.autoText] = body.data!!.src!!
                    body.data.bitrates?.forEach {
                        map["${it!!.bitrate}p"] = it.src!!
                    }
                    playerConfiguration.seasons[seasonIndex].movies[episodeIndex].resolutions = map
                    val dataSourceFactory: DataSource.Factory = DefaultHttpDataSource.Factory()
                    val hlsMediaSource: HlsMediaSource = HlsMediaSource.Factory(dataSourceFactory)
                        .createMediaSource(MediaItem.fromUri(Uri.parse(playerConfiguration.seasons[seasonIndex].movies[episodeIndex].resolutions[currentQuality])))
                    player.setMediaSource(hlsMediaSource)
                    player.prepare()
                    player.playWhenReady
                }
            }

            override fun onFailure(call: Call<MegogoStreamResponse>, t: Throwable) {
                t.printStackTrace()
            }
        })
    }

    private fun getPremierStream() {
        retrofitService?.getPremierStream(
            playerConfiguration.authorization,
            playerConfiguration.sessionId,
            playerConfiguration.videoId,
            playerConfiguration.seasons[seasonIndex].movies[episodeIndex].id,
        )?.enqueue(object : Callback<PremierStreamResponse> {
            override fun onResponse(
                call: Call<PremierStreamResponse>, response: Response<PremierStreamResponse>
            ) {
                val body = response.body()
                if (body != null) {
                    val map: HashMap<String, String> = hashMapOf()
                    body.file_info?.forEach {
                        if (it!!.quality == "auto") {
                            map[playerConfiguration.autoText] = it.file_name!!
                        } else {
                            map[it.quality!!] = it.file_name!!
                        }
                    }
                    playerConfiguration.seasons[seasonIndex].movies[episodeIndex].resolutions = map
                    val dataSourceFactory: DataSource.Factory = DefaultHttpDataSource.Factory()
                    val hlsMediaSource: HlsMediaSource = HlsMediaSource.Factory(dataSourceFactory)
                        .createMediaSource(MediaItem.fromUri(Uri.parse(playerConfiguration.seasons[seasonIndex].movies[episodeIndex].resolutions[currentQuality])))
                    player.setMediaSource(hlsMediaSource)
                    player.prepare()
                    player.playWhenReady
                }
            }

            override fun onFailure(call: Call<PremierStreamResponse>, t: Throwable) {
                t.printStackTrace()
            }
        })
    }

    private fun getSingleTvChannel(tvCIndex: Int, cIndex: Int) {
        tvCategoryIndex = tvCIndex
        channelIndex = cIndex
        retrofitService?.getSingleTvChannel(
            playerConfiguration.authorization,
            playerConfiguration.tvCategories[tvCIndex].channels[cIndex].id,
            "playerConfiguration.ip",
        )?.enqueue(object : Callback<TvChannelResponse> {
            override fun onResponse(
                call: Call<TvChannelResponse>, response: Response<TvChannelResponse>
            ) {
//                val body = response.body()
//                if (body != null) {
//                    val map: HashMap<String, Int> = hashMapOf()
//                    map["Auto"] = body.channelStreamAll
//                    playerConfiguration.resolutions = map
//                    url = body.channelStreamAll
//                    title.text = playerConfiguration.tvCategories[tvCIndex].channels[cIndex].name
//                    title1.text = playerConfiguration.tvCategories[tvCIndex].channels[cIndex].name
//                    val dataSourceFactory: DataSource.Factory = DefaultHttpDataSource.Factory()
//                    val hlsMediaSource: HlsMediaSource = HlsMediaSource.Factory(dataSourceFactory)
//                        .createMediaSource(MediaItem.fromUri(Uri.parse(url)))
//                    player.setMediaSource(hlsMediaSource)
//                    player.prepare()
//                    player.playWhenReady
//                }
            }

            override fun onFailure(call: Call<TvChannelResponse>, t: Throwable) {
                t.printStackTrace()
            }
        })
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        currentOrientation = newConfig.orientation
        if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            setFullScreen()
            if (playerConfiguration.isLive) {
                playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            }
            title.text = title1.text
            title.visibility = View.VISIBLE
            title1.text = ""
            title1.visibility = View.GONE
            if (playerConfiguration.isSerial) if (isLastEpisode()) nextButton.visibility =
                View.VISIBLE
            else nextButton.visibility = View.GONE
            else nextButton.visibility = View.GONE
            zoom.visibility = View.VISIBLE
            orientation.setImageResource(R.drawable.ic_portrait)
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
            nextButton.visibility = View.GONE
            zoom.visibility = View.GONE
            orientation.setImageResource(R.drawable.ic_landscape)
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

    private fun isLastEpisode(): Boolean {
        return playerConfiguration.seasons.size == seasonIndex + 1 && playerConfiguration.seasons[playerConfiguration.seasons.size - 1].movies.size == episodeIndex + 1
    }

    private fun showTvProgramsBottomSheet() {
        currentBottomSheet = BottomSheet.TV_PROGRAMS
        val bottomSheetDialog = BottomSheetDialog(this, R.style.BottomSheetDialog)
        listOfAllOpenedBottomSheets.add(bottomSheetDialog)
        bottomSheetDialog.behavior.isDraggable = false
        bottomSheetDialog.behavior.state = BottomSheetBehavior.STATE_EXPANDED
        bottomSheetDialog.behavior.peekHeight = Resources.getSystem().displayMetrics.heightPixels
        bottomSheetDialog.setContentView(R.layout.tv_programs_sheet)
        val backButtonBottomSheet =
            bottomSheetDialog.findViewById<ImageView>(R.id.tv_program_sheet_back)
        backButtonBottomSheet?.setOnClickListener {
            bottomSheetDialog.dismiss()
        }
        val titleBottomSheet = bottomSheetDialog.findViewById<TextView>(R.id.tv_program_sheet_title)
        titleBottomSheet?.text = title.text
        val tabLayout = bottomSheetDialog.findViewById<TabLayout>(R.id.tv_programs_tabs)
        val viewPager = bottomSheetDialog.findViewById<ViewPager2>(R.id.tv_programs_view_pager)
        viewPager?.adapter = TvProgramsPagerAdapter(this, playerConfiguration.programsInfoList)
        viewPager?.currentItem = 1
        TabLayoutMediator(tabLayout!!, viewPager!!) { tab, position ->
            tab.text = playerConfiguration.programsInfoList[position].day
        }.attach()
        bottomSheetDialog.show()
        bottomSheetDialog.setOnDismissListener {
            currentBottomSheet = BottomSheet.NONE
        }
    }

    private var backButtonEpisodeBottomSheet: ImageView? = null
    private fun showEpisodesBottomSheet() {
        currentBottomSheet = BottomSheet.EPISODES
        val bottomSheetDialog = BottomSheetDialog(this, R.style.BottomSheetDialog)
        listOfAllOpenedBottomSheets.add(bottomSheetDialog)
        bottomSheetDialog.behavior.state = BottomSheetBehavior.STATE_EXPANDED
        bottomSheetDialog.setContentView(R.layout.episodes)
        backButtonEpisodeBottomSheet = bottomSheetDialog.findViewById(R.id.episode_sheet_back)
        if (resources.configuration.orientation == Configuration.ORIENTATION_PORTRAIT) {
            backButtonEpisodeBottomSheet?.visibility = View.GONE
        } else {
            backButtonEpisodeBottomSheet?.visibility = View.VISIBLE
        }
        backButtonEpisodeBottomSheet?.setOnClickListener {
            bottomSheetDialog.dismiss()
        }
        val titleBottomSheet = bottomSheetDialog.findViewById<TextView>(R.id.episodes_sheet_title)
        titleBottomSheet?.text = title.text
        val tabLayout = bottomSheetDialog.findViewById<TabLayout>(R.id.episode_tabs)
        val viewPager = bottomSheetDialog.findViewById<ViewPager2>(R.id.episode_view_pager)
        viewPager?.adapter = EpisodePagerAdapter(viewPager!!,
            this,
            playerConfiguration.seasons,
            seasonIndex,
            episodeIndex,
            object : EpisodePagerAdapter.OnClickListener {
                @SuppressLint("SetTextI18n")
                override fun onClick(epIndex: Int, seasIndex: Int) {
                    seasonIndex = seasIndex
                    episodeIndex = epIndex
                    if (currentOrientation == Configuration.ORIENTATION_PORTRAIT) {
                        titleText =
                            "S${seasonIndex + 1} E${episodeIndex + 1} " + playerConfiguration.seasons[seasonIndex].movies[episodeIndex].title
                        title.text = titleText
                        title1.text = title.text
                        title1.visibility = View.VISIBLE
                        title.text = ""
                        title.visibility = View.INVISIBLE
                    } else {
                        titleText =
                            "S${seasonIndex + 1} E${episodeIndex + 1} " + playerConfiguration.seasons[seasonIndex].movies[episodeIndex].title
                        title.text = titleText
                        title.visibility = View.VISIBLE
                        title1.text = ""
                        title1.visibility = View.GONE
                    }
                    if (playerConfiguration.isMegogo && playerConfiguration.isSerial) {
                        getMegogoStream()
                    } else if (playerConfiguration.isPremier && playerConfiguration.isSerial) {
                        getPremierStream()
                    } else {
                        url =
                            playerConfiguration.seasons[seasonIndex].movies[episodeIndex].resolutions[currentQuality]
                        val dataSourceFactory: DataSource.Factory = DefaultHttpDataSource.Factory()
                        val hlsMediaSource: HlsMediaSource =
                            HlsMediaSource.Factory(dataSourceFactory)
                                .createMediaSource(MediaItem.fromUri(Uri.parse(url)))
                        player.setMediaSource(hlsMediaSource)
                        player.prepare()
                        player.playWhenReady
                    }
                    bottomSheetDialog.dismiss()
                }
            })
        TabLayoutMediator(tabLayout!!, viewPager) { tab, position ->
            tab.text = playerConfiguration.seasons[position].title
        }.attach()
        bottomSheetDialog.show()
        bottomSheetDialog.setOnDismissListener {
            currentBottomSheet = BottomSheet.NONE
        }
    }

    private fun showChannelsBottomSheet() {
        currentBottomSheet = BottomSheet.CHANNELS
        val bottomSheetDialog = BottomSheetDialog(this, R.style.BottomSheetDialog)
        listOfAllOpenedBottomSheets.add(bottomSheetDialog)
        bottomSheetDialog.behavior.isDraggable = false
        bottomSheetDialog.behavior.state = BottomSheetBehavior.STATE_EXPANDED
        bottomSheetDialog.behavior.peekHeight = Resources.getSystem().displayMetrics.heightPixels
        bottomSheetDialog.setContentView(R.layout.channels_page)
        val tabLayout = bottomSheetDialog.findViewById<TabLayout>(R.id.tv_category_tabs)
        val viewPager = bottomSheetDialog.findViewById<ViewPager2>(R.id.tv_category_view_pager)
        viewPager?.adapter = TvCategoryPagerAdapter(
            this, playerConfiguration.tvCategories,
            object : TvCategoryPagerAdapter.OnClickListener {
                override fun onClick(tvCIndex: Int, cIndex: Int) {
                    getSingleTvChannel(tvCIndex, cIndex)
                    bottomSheetDialog.dismiss()
                }
            },
        )
        viewPager?.currentItem = tvCategoryIndex
        viewPager?.orientation = ViewPager2.ORIENTATION_HORIZONTAL
        viewPager?.isUserInputEnabled = false

        TabLayoutMediator(tabLayout!!, viewPager!!) { tab, position ->
            tab.text = playerConfiguration.tvCategories[position].title
        }.attach()
        bottomSheetDialog.show()
        bottomSheetDialog.setOnDismissListener {
            currentBottomSheet = BottomSheet.NONE
        }
    }

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
            if (playerConfiguration.isSerial) {
                if (playerConfiguration.seasons[seasonIndex].movies[episodeIndex].resolutions.isNotEmpty()) showQualitySpeedSheet(
                    currentQuality,
                    playerConfiguration.seasons[seasonIndex].movies[episodeIndex].resolutions.keys.toList() as ArrayList,
                    true,
                )
            } else {
                if (playerConfiguration.resolutions.isNotEmpty()) showQualitySpeedSheet(
                    currentQuality,
                    playerConfiguration.resolutions.keys.toList() as ArrayList,
                    true,
                )
            }
        }
        speed?.setOnClickListener {
            showQualitySpeedSheet(currentSpeed, speeds as ArrayList, false)
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
                        val url =
                            if (playerConfiguration.isSerial) playerConfiguration.seasons[seasonIndex].movies[episodeIndex].resolutions[currentQuality] else playerConfiguration.resolutions[currentQuality]
                        Log.d(tag, "onClick: $url")
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
