package uz.plugin.video_player.utils

import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class UrlPolicyTest {
    @Test
    fun acceptsHttps() {
        assertTrue(UrlPolicy.isHttps("https://example.com/video.m3u8"))
        assertTrue(UrlPolicy.isHttps("HTTPS://example.com/video.mp4"))
        UrlPolicy.requireHttps("https://example.com/video.mp4")
    }

    @Test
    fun rejectsPlainHttp() {
        assertFalse(UrlPolicy.isHttps("http://example.com/video.mp4"))
        assertTrue(UrlPolicy.isInsecureHttp("http://example.com/video.mp4"))
        assertTrue(UrlPolicy.isInsecureHttp("HTTP://example.com/video.mp4"))
        assertThrows(IllegalArgumentException::class.java) {
            UrlPolicy.requireHttps("http://example.com/video.mp4")
        }
    }

    @Test
    fun assetPathsAreNeitherHttpNorHttps() {
        assertFalse(UrlPolicy.isHttps("videos/intro.mp4"))
        assertFalse(UrlPolicy.isInsecureHttp("videos/intro.mp4"))
        assertThrows(IllegalArgumentException::class.java) { UrlPolicy.requireHttps("videos/intro.mp4") }
    }

    @Test
    fun rejectsOtherSchemesAndEmpty() {
        assertFalse(UrlPolicy.isHttps("file:///etc/passwd"))
        assertFalse(UrlPolicy.isHttps("ftp://example.com/video.mp4"))
        assertFalse(UrlPolicy.isHttps(""))
        assertFalse(UrlPolicy.isInsecureHttp(""))
    }

    @Test
    fun detectsHlsByPathOnly() {
        assertTrue(UrlPolicy.isHls("https://example.com/a/master.m3u8"))
        assertTrue(UrlPolicy.isHls("https://example.com/a/master.M3U8?token=1"))
        assertFalse(UrlPolicy.isHls("https://example.com/chls/clip.mp4"))
        assertFalse(UrlPolicy.isHls("https://example.com/clip.mp4?x=.m3u8"))
    }

    @Test
    fun keyUriMustBeHttpsOnPlaylistOrAllowedHost() {
        val playlist = "https://cdn.example.com/a/master.m3u8"
        assertTrue(UrlPolicy.isAllowedKeyUri("https://cdn.example.com/key", playlist, emptySet()))
        assertTrue(UrlPolicy.isAllowedKeyUri("https://CDN.example.com/key", playlist, emptySet()))
        assertTrue(UrlPolicy.isAllowedKeyUri("https://keys.example.com/key", playlist, setOf("Keys.Example.com")))
        assertFalse(UrlPolicy.isAllowedKeyUri("https://keys.example.com/key", playlist, emptySet()))
        assertFalse(UrlPolicy.isAllowedKeyUri("https://evil.example/key", playlist, setOf("keys.example.com")))
        assertFalse(UrlPolicy.isAllowedKeyUri("http://cdn.example.com/key", playlist, emptySet()))
    }
}
