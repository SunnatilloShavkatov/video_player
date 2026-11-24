package uz.plugin.video_player.utils

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Test

class KeyHeaderSessionsTest {
    @Test
    fun storedHeadersAreReadBackById() {
        val id = KeyHeaderSessions.put(mapOf("Authorization" to "Bearer test"))

        assertEquals(mapOf("Authorization" to "Bearer test"), KeyHeaderSessions.get(id))
        KeyHeaderSessions.remove(id)
    }

    @Test
    fun removedSessionIsGone() {
        val id = KeyHeaderSessions.put(mapOf("X-Key" to "value"))
        KeyHeaderSessions.remove(id)

        assertNull(KeyHeaderSessions.get(id))
    }

    @Test
    fun unknownIdHasNoHeaders() {
        assertNull(KeyHeaderSessions.get("missing"))
    }

    @Test
    fun eachSessionGetsItsOwnId() {
        val first = KeyHeaderSessions.put(mapOf("X-Key" to "a"))
        val second = KeyHeaderSessions.put(mapOf("X-Key" to "b"))

        assertNotEquals(first, second)
        assertEquals(mapOf("X-Key" to "a"), KeyHeaderSessions.get(first))
        KeyHeaderSessions.remove(first)
        KeyHeaderSessions.remove(second)
    }

    @Test
    fun laterChangesToTheCallerMapAreNotSeen() {
        val headers = mutableMapOf("X-Key" to "a")
        val id = KeyHeaderSessions.put(headers)
        headers["X-Key"] = "b"

        assertEquals(mapOf("X-Key" to "a"), KeyHeaderSessions.get(id))
        KeyHeaderSessions.remove(id)
    }
}
