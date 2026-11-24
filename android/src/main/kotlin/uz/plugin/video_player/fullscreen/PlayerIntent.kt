package uz.plugin.video_player.fullscreen

import android.content.Intent
import uz.plugin.video_player.extraArgument
import uz.plugin.video_player.extraKeyHeadersSession
import uz.plugin.video_player.models.PlayerConfiguration
import uz.plugin.video_player.utils.KeyHeaderSessions

/**
 * The player's configuration with its key headers restored from [KeyHeaderSessions]; they are never read from the
 * Intent. Null when the headers' session is gone (process death).
 */
@Suppress("DEPRECATION")
internal fun Intent.readPlayerConfiguration(): PlayerConfiguration? {
    val configuration = getSerializableExtra(extraArgument) as PlayerConfiguration
    val session = getStringExtra(extraKeyHeadersSession) ?: return configuration
    val headers = KeyHeaderSessions.get(session) ?: return null
    return configuration.copy(keyRequestHeaders = headers)
}

/** Drops the key headers of a player that is finishing for good. */
internal fun Intent.releaseKeyHeadersSession() {
    getStringExtra(extraKeyHeadersSession)?.let(KeyHeaderSessions::remove)
}
