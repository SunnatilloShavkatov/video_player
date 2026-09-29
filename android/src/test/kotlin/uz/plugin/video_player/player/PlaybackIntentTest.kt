package uz.plugin.video_player.player

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PlaybackIntentTest {
    private fun remote() = PlaybackIntent().apply { onInitialized(remote = true) }

    @Test
    fun startsWantingPlaybackWithNothingToRecover() {
        val intent = remote()
        assertTrue(intent.wantsPlayback)
        assertFalse(intent.shouldAutoRecover)
    }

    @Test
    fun networkLossWhilePlayingIsRecoverable() {
        val intent = remote()
        intent.onNetworkLost()
        assertTrue(intent.shouldAutoRecover)
    }

    @Test
    fun networkLossWhilePausedIsNotRecovered() {
        val intent = remote()
        intent.onPause()
        intent.onNetworkLost()
        assertFalse(intent.shouldAutoRecover)
    }

    @Test
    fun localPlaybackNeverAutoRecovers() {
        val intent = PlaybackIntent().apply { onInitialized(remote = false) }
        intent.onNetworkLost()
        intent.onPlayerError()
        assertFalse(intent.shouldAutoRecover)
    }

    @Test
    fun playerErrorWhilePlayingIsRecoverable() {
        val intent = remote()
        intent.onPlayerError()
        assertTrue(intent.shouldAutoRecover)
    }

    @Test
    fun playerErrorWhilePausedIsNotRecovered() {
        val intent = remote()
        intent.onPause()
        intent.onPlayerError()
        assertFalse(intent.shouldAutoRecover)
    }

    @Test
    fun pauseCancelsPendingRecovery() {
        val intent = remote()
        intent.onNetworkLost()
        intent.onPause()
        assertFalse(intent.shouldAutoRecover)
        assertFalse(intent.wantsPlayback)
    }

    @Test
    fun resumingPlayCancelsNothingButRequiresANewLoss() {
        val intent = remote()
        intent.onPause()
        intent.onPlay()
        assertTrue(intent.wantsPlayback)
        assertFalse(intent.shouldAutoRecover)
    }

    @Test
    fun playingAgainClearsPendingRecovery() {
        val intent = remote()
        intent.onNetworkLost()
        intent.onPlaying()
        assertFalse(intent.shouldAutoRecover)
    }

    @Test
    fun endOfPlaybackStopsRecovery() {
        val intent = remote()
        intent.onPlayerError()
        intent.onEnded()
        assertFalse(intent.shouldAutoRecover)
        assertFalse(intent.wantsPlayback)
    }

    @Test
    fun retryAppliesRequestedIntentAndClearsRecovery() {
        val intent = remote()
        intent.onNetworkLost()
        intent.onRetry(resume = false)
        assertFalse(intent.wantsPlayback)
        assertFalse(intent.shouldAutoRecover)
        intent.onRetry(resume = true)
        assertTrue(intent.wantsPlayback)
    }

    @Test
    fun releaseClearsPendingRecovery() {
        val intent = remote()
        intent.onNetworkLost()
        intent.onReleased()
        assertFalse(intent.shouldAutoRecover)
    }

    @Test
    fun reinitializingResetsState() {
        val intent = remote()
        intent.onPause()
        intent.onNetworkLost()
        intent.onInitialized(remote = true)
        assertTrue(intent.wantsPlayback)
        assertFalse(intent.shouldAutoRecover)
    }
}
