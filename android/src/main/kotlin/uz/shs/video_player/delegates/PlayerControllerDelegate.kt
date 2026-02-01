package uz.shs.video_player.delegates

import androidx.media3.common.PlaybackException
import uz.shs.video_player.models.PlaybackState
import uz.shs.video_player.models.QualityOption

/**
 * Delegate interface for PlayerController to communicate playback events
 * back to the host Activity or component.
 * 
 * Follows the iOS delegate pattern for clean separation of concerns.
 */
interface PlayerControllerDelegate {
    
    /**
     * Called when the player is ready to start playback.
     * This is triggered after successful media source loading.
     */
    fun onPlayerReady()
    
    /**
     * Called when the playback state changes.
     * 
     * @param state The new playback state (PLAYING, PAUSED, BUFFERING, IDLE)
     */
    fun onPlaybackStateChanged(state: PlaybackState)
    
    /**
     * Called when a playback error occurs.
     * 
     * @param error The ExoPlayer exception containing error details
     */
    fun onPlayerError(error: PlaybackException)
    
    /**
     * Called when available video quality tracks change.
     * 
     * @param qualities List of available quality options
     */
    fun onTracksChanged(qualities: List<QualityOption>)
    
    /**
     * Called when the playing state toggles (play/pause).
     * 
     * @param isPlaying True if video is actively playing, false if paused
     */
    fun onIsPlayingChanged(isPlaying: Boolean)
    
    /**
     * Called when the video finishes playing to the end.
     */
    fun onPlaybackEnded()
}
