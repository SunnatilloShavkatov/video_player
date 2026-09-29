package uz.plugin.video_player.player

/**
 * What the user (or the app) wants the player to be doing, independent of what ExoPlayer is
 * doing right now. Decides whether playback should be resumed automatically after a network
 * loss or an error. Pure Kotlin so the rules can be unit tested on the JVM.
 */
internal class PlaybackIntent {
    /** True when the current source is streamed over HTTPS (as opposed to a local asset). */
    var isRemote: Boolean = false
        private set

    /** True when the user last asked for playback to run. */
    var wantsPlayback: Boolean = true
        private set

    private var waitingForNetwork = false

    /** True when playback stopped because of the network and should restart once it is back. */
    val shouldAutoRecover: Boolean
        get() = isRemote && waitingForNetwork && wantsPlayback

    fun onInitialized(remote: Boolean) {
        isRemote = remote
        wantsPlayback = true
        waitingForNetwork = false
    }

    fun onPlay() {
        wantsPlayback = true
    }

    fun onPause() {
        wantsPlayback = false
        waitingForNetwork = false
    }

    fun onEnded() = onPause()

    fun onReleased() {
        waitingForNetwork = false
    }

    fun onNetworkLost() {
        if (!isRemote) return
        waitingForNetwork = wantsPlayback
    }

    fun onPlayerError() {
        if (isRemote && wantsPlayback) waitingForNetwork = true
    }

    fun onPlaying() {
        waitingForNetwork = false
    }

    fun onRetry(resume: Boolean) {
        wantsPlayback = resume
        waitingForNetwork = false
    }
}
