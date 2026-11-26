package uz.plugin.video_player.utils

/** Remote playback is HTTPS-only; anything else that is not `http(s)://` is a local asset path. */
internal object UrlPolicy {
    fun isHttps(url: String): Boolean = url.startsWith("https://", ignoreCase = true)

    fun isInsecureHttp(url: String): Boolean = url.startsWith("http://", ignoreCase = true)

    /** True when the URL path (query and fragment ignored) names an `.m3u8` playlist. */
    fun isHls(url: String): Boolean =
        url.substringBefore('#').substringBefore('?').contains(".m3u8", ignoreCase = true)

    /** Throws [IllegalArgumentException] unless [url] is an `https://` URL. */
    fun requireHttps(url: String) {
        require(isHttps(url)) { "Only HTTPS URLs are allowed" }
    }
}
