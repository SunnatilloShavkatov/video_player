package uz.plugin.video_player.player

import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager

/** Requests media audio focus for the full-screen player and reports permanent loss. */
class AudioFocusHandler(
    private val audioManager: AudioManager,
    private val onFocusLost: () -> Unit,
) : AudioManager.OnAudioFocusChangeListener {

    private var focusRequest: AudioFocusRequest? = null

    fun request() {
        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
                    .build()
            )
            .setAcceptsDelayedFocusGain(true)
            .setOnAudioFocusChangeListener(this)
            .build()
        focusRequest = request
        audioManager.requestAudioFocus(request)
    }

    fun abandon() {
        focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
    }

    override fun onAudioFocusChange(focusChange: Int) {
        if (focusChange == AudioManager.AUDIOFOCUS_LOSS) {
            onFocusLost()
        }
    }
}
