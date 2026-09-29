package uz.plugin.video_player.utils

/** Remote playback is HTTPS-only; anything else that is not `http(s)://` is a local asset path. */
internal object UrlPolicy {
    fun isHttps(url: String): Boolean = url.startsWith("https://", ignoreCase = true)

    fun isInsecureHttp(url: String): Boolean = url.startsWith("http://", ignoreCase = true)

    /** Throws [IllegalArgumentException] unless [url] is an `https://` URL. */
    fun requireHttps(url: String) {
        require(isHttps(url)) { "Only HTTPS URLs are allowed" }
    }
}
