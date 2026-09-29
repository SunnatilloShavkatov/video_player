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
}
