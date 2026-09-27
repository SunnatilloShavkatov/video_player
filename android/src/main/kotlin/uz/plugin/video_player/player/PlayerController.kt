package uz.plugin.video_player.player

import android.content.Context
import androidx.core.net.toUri
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.MergingMediaSource
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.extractor.ExtractorsFactory
import androidx.media3.extractor.text.DefaultSubtitleParserFactory
import androidx.media3.extractor.text.SubtitleExtractor
import uz.plugin.video_player.models.PlaybackState
import uz.plugin.video_player.models.QualityOption
import uz.plugin.video_player.models.SubtitleTrack

/**
 * PlayerController manages ExoPlayer lifecycle and playback operations.
 *
 * Extracted from VideoPlayerActivity to improve separation of concerns
 * and follow the iOS component-based architecture pattern.
 *
 * Responsibilities:
 * - ExoPlayer initialization and cleanup
 * - Media source creation (HLS)
 * - Play/pause/seek operations
 * - Playback state management
 * - Video quality track extraction
 *
 * @param context Android context for ExoPlayer creation
 * @param delegate Callback interface for communicating events back to host
 */
@UnstableApi
class PlayerController(
    private val context: Context,
    private val delegate: PlayerControllerDelegate?
) {
    private var player: ExoPlayer? = null
    private val playerListener = createPlayerListener()
    private var isRemotePlayback = false
    private var playWhenReadyIntent = true
    private var waitingForNetworkRecovery = false

    /**
     * Initialize the player with a video URL and optional starting position.
     *
     * @param url Video URL (HLS stream)
     * @param lastPositionSeconds Starting position in seconds
     * @param keyRequestHeaders Headers added only to HLS AES-128 key requests
     */
    fun initialize(
        url: String,
        lastPositionSeconds: Long,
        subtitles: List<SubtitleTrack> = emptyList(),
        keyRequestHeaders: Map<String, String> = emptyMap(),
    ) {
        isRemotePlayback = url.startsWith("http://") || url.startsWith("https://")
        playWhenReadyIntent = true
        waitingForNetworkRecovery = false

        val mediaSource = createMediaSource(url, subtitles, keyRequestHeaders)

        // CUSTOM LOAD CONTROL: More conservative buffer for low-end devices
        val loadControl = androidx.media3.exoplayer.DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                15000, // minBufferMs
                30000, // maxBufferMs
                1000,  // bufferForPlaybackMs
                2000   // bufferForPlaybackAfterRebufferMs
            )
            .build()

        // Initialize ExoPlayer
        val startPositionMs = (lastPositionSeconds * 1000).coerceAtLeast(0)
        player = ExoPlayer.Builder(context, createRenderersFactory(context))
            .setLoadControl(loadControl)
            .build().apply {
            setMediaSource(mediaSource, startPositionMs)
            prepare()
            addListener(playerListener)
            playWhenReady = true
        }

        delegate?.onPlayerReady()
    }

    /**
     * Attach player to a PlayerView for rendering.
     *
     * @param playerView The ExoPlayer PlayerView component
     */
    fun attachToView(playerView: androidx.media3.ui.PlayerView) {
        playerView.player = player
        playerView.keepScreenOn = true
        playerView.useController = true
    }

    /**
     * Start or resume playback.
     */
    fun play() {
        playWhenReadyIntent = true
        player?.play()
    }

    /**
     * Pause playback.
     */
    fun pause() {
        playWhenReadyIntent = false
        waitingForNetworkRecovery = false
        player?.pause()
    }

    fun pauseForTransientLoss() {
        player?.playWhenReady = false
        player?.pause()
    }

    fun resumeAfterTransientLoss() {
        if (!playWhenReadyIntent) {
            return
        }

        player?.playWhenReady = true
        player?.play()
    }

    fun shouldResumeOnHostResume(): Boolean = playWhenReadyIntent

    /**
     * Seek to a specific position.
     *
     * @param positionMs Position in milliseconds
     */
    fun seekTo(positionMs: Long) {
        player?.seekTo(positionMs)
    }

    fun setPlaybackSpeed(speed: Float) {
        player?.setPlaybackSpeed(speed)
    }

    fun applyAutomaticQuality() {
        player?.let { exoPlayer ->
            exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                .buildUpon()
                .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
                .clearVideoSizeConstraints()
                .build()
        }
    }

    fun applyManualQuality(option: QualityOption) {
        player?.let { exoPlayer ->
            exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                .buildUpon()
                .setMaxVideoSize(option.width, option.height)
                .setMinVideoSize(option.width, option.height)
                .build()
        }
    }

    fun setSubtitlesEnabled(enabled: Boolean) {
        player?.let { exoPlayer ->
            exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                .buildUpon()
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, !enabled)
                .build()
        }
    }

    fun selectSubtitleLanguage(language: String?) {
        player?.let { exoPlayer ->
            if (language.isNullOrEmpty()) {
                exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                    .buildUpon()
                    .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                    .build()
            } else {
                exoPlayer.trackSelectionParameters = exoPlayer.trackSelectionParameters
                    .buildUpon()
                    .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
                    .setPreferredTextLanguage(language)
                    .build()
            }
        }
    }

    fun onNetworkLost() {
        if (!isRemotePlayback) {
            return
        }
        waitingForNetworkRecovery = playWhenReadyIntent
    }

    fun shouldAutoRecoverAfterNetworkRestore(): Boolean {
        return isRemotePlayback && waitingForNetworkRecovery && playWhenReadyIntent
    }

    fun retryPlayback(shouldResumePlayback: Boolean = playWhenReadyIntent) {
        val exoPlayer = player ?: return

        playWhenReadyIntent = shouldResumePlayback
        waitingForNetworkRecovery = false

        exoPlayer.prepare()
        if (shouldResumePlayback) {
            exoPlayer.playWhenReady = true
            exoPlayer.play()
        } else {
            exoPlayer.playWhenReady = false
            exoPlayer.pause()
        }
    }

    /**
     * Seek forward by specified increment.
     *
     * @param incrementMs Milliseconds to seek forward (default 10 seconds)
     */
    fun seekForward(incrementMs: Long = 10000) {
        player?.let {
            val newPosition = it.currentPosition + incrementMs
            // Duration is C.TIME_UNSET until the media is prepared; clamping to it would seek negative.
            it.seekTo(if (it.duration == C.TIME_UNSET) newPosition else newPosition.coerceAtMost(it.duration))
        }
    }

    /**
     * Seek backward by specified increment.
     *
     * @param incrementMs Milliseconds to seek backward (default 10 seconds)
     */
    fun seekBackward(incrementMs: Long = 10000) {
        player?.let {
            val newPosition = it.currentPosition - incrementMs
            it.seekTo(newPosition.coerceAtLeast(0))
        }
    }

    /**
     * Get current playback position.
     *
     * @return Current position in milliseconds
     */
    fun getCurrentPosition(): Long = player?.currentPosition ?: 0

    /**
     * Get total duration of the video.
     *
     * @return Duration in milliseconds, or 0 while unknown (C.TIME_UNSET)
     */
    fun getDuration(): Long = player?.duration?.takeIf { it != C.TIME_UNSET && it > 0 } ?: 0

    /**
     * Check if video is currently playing.
     *
     * @return True if playing, false otherwise
     */
    fun isPlaying(): Boolean = player?.isPlaying ?: false

    /**
     * Get the underlying ExoPlayer instance.
     * Useful for advanced operations not exposed by this controller.
     *
     * @return ExoPlayer instance or null if not initialized
     */
    fun getPlayer(): ExoPlayer? = player

    /**
     * Release all player resources.
     * MUST be called when the player is no longer needed to prevent memory leaks.
     */
    fun release() {
        player?.let {
            try { it.removeListener(playerListener) } catch (_: Exception) {}
            try { it.stop() } catch (_: Exception) {}
            try { it.clearVideoSurface() } catch (_: Exception) {}
            try { it.release() } catch (_: Exception) {}
        }
        player = null
        waitingForNetworkRecovery = false
    }

    fun isRemotePlayback(): Boolean = isRemotePlayback

    /**
     * Create the player event listener for delegating callbacks.
     */
    private fun createPlayerListener() = object : Player.Listener {
        override fun onPlayerError(error: PlaybackException) {
            if (isRemotePlayback && playWhenReadyIntent) {
                waitingForNetworkRecovery = true
            }
            delegate?.onPlayerError(error)
            delegate?.onPlaybackStateChanged(PlaybackState.ERROR)
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            if (isPlaying) {
                waitingForNetworkRecovery = false
            }
            delegate?.onIsPlayingChanged(isPlaying)
        }

        override fun onPlaybackStateChanged(playbackState: Int) {
            val state = when (playbackState) {
                Player.STATE_BUFFERING -> PlaybackState.BUFFERING
                Player.STATE_READY -> if (player?.isPlaying == true) {
                    PlaybackState.PLAYING
                } else {
                    PlaybackState.PAUSED
                }

                Player.STATE_ENDED -> {
                    playWhenReadyIntent = false
                    waitingForNetworkRecovery = false
                    delegate?.onPlaybackEnded()
                    PlaybackState.IDLE
                }

                Player.STATE_IDLE -> PlaybackState.IDLE
                else -> PlaybackState.IDLE
            }

            delegate?.onPlaybackStateChanged(state)
        }

        override fun onTracksChanged(tracks: Tracks) {
            super.onTracksChanged(tracks)
            val qualities = extractQualityOptions(tracks)
            delegate?.onTracksChanged(qualities)
        }
    }

    /**
     * Extract available video quality options from ExoPlayer tracks.
     *
     * @param tracks ExoPlayer tracks information
     * @return List of quality options sorted by height (descending)
     */
    private fun extractQualityOptions(tracks: Tracks): List<QualityOption> {
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

        // Sort by height descending (highest quality first)
        return videoTracks.sortedByDescending { it.height }.distinctBy { it.height }
    }

    private fun createMediaSource(
        url: String,
        subtitles: List<SubtitleTrack> = emptyList(),
        keyRequestHeaders: Map<String, String> = emptyMap(),
    ): MediaSource {
        val dataSourceFactory: DataSource.Factory = DefaultHttpDataSource.Factory()

        val uri = if (url.startsWith("http://") || url.startsWith("https://")) {
            url.toUri()
        } else {
            "asset:///flutter_assets/$url".toUri()
        }

        val subtitleConfigs = subtitles.map { sub ->
            MediaItem.SubtitleConfiguration.Builder(sub.url.toUri())
                .setMimeType(MimeTypes.TEXT_VTT)
                .setLanguage(sub.lang)
                .setLabel(sub.label)
                .setSelectionFlags(if (sub.isDefault) C.SELECTION_FLAG_DEFAULT else 0)
                .build()
        }

        val isHls = url.contains(".m3u8") || url.contains("hls", ignoreCase = true)

        if (isHls && keyRequestHeaders.isNotEmpty()) {
            return createKeyAuthorizedHlsSource(uri, dataSourceFactory, subtitleConfigs, keyRequestHeaders)
        }

        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .apply {
                if (isHls) {
                    setMimeType(MimeTypes.APPLICATION_M3U8)
                }
                if (subtitleConfigs.isNotEmpty()) {
                    setSubtitleConfigurations(subtitleConfigs)
                }
            }
            .build()

        // Sidecar subtitles must go through DefaultMediaSourceFactory: it merges the
        // subtitle sources with the video source AND parses the WebVTT into
        // application/x-media3-cues samples. HlsMediaSource.Factory ignores
        // MediaItem.subtitleConfigurations, and a hand-rolled SingleSampleMediaSource
        // feeds the TextRenderer raw text/vtt, which fails with
        // "Legacy decoding is disabled" on Media3 1.11.
        if (subtitleConfigs.isNotEmpty()) {
            return DefaultMediaSourceFactory(context)
                .createMediaSource(mediaItem)
        }

        return if (isHls) {
            HlsMediaSource.Factory(dataSourceFactory)
                .createMediaSource(mediaItem)
        } else {
            ProgressiveMediaSource.Factory(dataSourceFactory)
                .createMediaSource(mediaItem)
        }
    }

    /**
     * HLS source whose AES-128 key requests carry [keyRequestHeaders]
     * (see [hlsMediaSourceFactory]).
     *
     * DefaultMediaSourceFactory cannot take an HlsDataSourceFactory, so sidecar
     * subtitles are merged here the same way it does internally: a
     * ProgressiveMediaSource with a [SubtitleExtractor], which emits
     * application/x-media3-cues samples.
     */
    private fun createKeyAuthorizedHlsSource(
        uri: android.net.Uri,
        dataSourceFactory: DataSource.Factory,
        subtitleConfigs: List<MediaItem.SubtitleConfiguration>,
        keyRequestHeaders: Map<String, String>,
    ): MediaSource {
        val hlsSource = hlsMediaSourceFactory(dataSourceFactory, keyRequestHeaders)
            .createMediaSource(
                MediaItem.Builder()
                    .setUri(uri)
                    .setMimeType(MimeTypes.APPLICATION_M3U8)
                    .build()
            )
        if (subtitleConfigs.isEmpty()) {
            return hlsSource
        }

        val subtitleParserFactory = DefaultSubtitleParserFactory()
        val subtitleSources = subtitleConfigs.map { config ->
            val format = Format.Builder()
                .setSampleMimeType(config.mimeType)
                .setLanguage(config.language)
                .setSelectionFlags(config.selectionFlags)
                .setRoleFlags(config.roleFlags)
                .setLabel(config.label)
                .setId(config.id)
                .build()
            val extractorsFactory = ExtractorsFactory {
                arrayOf(SubtitleExtractor(subtitleParserFactory.create(format), format))
            }
            ProgressiveMediaSource.Factory(dataSourceFactory, extractorsFactory)
                .createMediaSource(MediaItem.fromUri(config.uri.toString()))
        }
        return MergingMediaSource(hlsSource, *subtitleSources.toTypedArray())
    }
}
