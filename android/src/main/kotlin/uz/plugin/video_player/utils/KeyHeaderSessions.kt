package uz.plugin.video_player.utils

import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * Key-request headers (tokens) of fullscreen sessions, held in process memory so they never travel in an Intent;
 * the Intent carries only the session id. After process death the entry is gone, and the player must not start.
 */
internal object KeyHeaderSessions {
    private val sessions = ConcurrentHashMap<String, Map<String, String>>()

    fun put(headers: Map<String, String>): String {
        val id = UUID.randomUUID().toString()
        sessions[id] = headers.toMap()
        return id
    }

    fun get(id: String): Map<String, String>? = sessions[id]

    fun remove(id: String) {
        sessions.remove(id)
    }
}
