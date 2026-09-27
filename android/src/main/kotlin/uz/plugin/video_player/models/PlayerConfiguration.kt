package uz.plugin.video_player.models

import org.json.JSONObject
import java.io.Serializable

data class PlayerConfiguration(
    val title: String,
    val videoUrl: String,
    val autoText: String,
    val assetPath: String,
    val speedText: String,
    val qualityText: String,
    val lastPosition: Long,
    val movieShareLink: String,
    val playVideoFromAsset: Boolean,
    val isScreenshotEnabled: Boolean = false,
    val subtitles: List<SubtitleTrack> = emptyList(),
    val subtitleText: String = "Subtitles",
    val subtitleSizeText: String = "Subtitle Size",
    val subtitleOffText: String = "Off",
    val keyRequestHeaders: Map<String, String>? = emptyMap(),
) : Serializable {
    companion object {
        fun fromJson(jsonString: String): PlayerConfiguration {
            val json = JSONObject(jsonString)

            val subtitlesList = mutableListOf<SubtitleTrack>()
            val subtitlesArray = json.optJSONArray("subtitles")
            if (subtitlesArray != null) {
                for (i in 0 until subtitlesArray.length()) {
                    val subObj = subtitlesArray.optJSONObject(i) ?: continue
                    subtitlesList.add(SubtitleTrack.fromJson(subObj))
                }
            }

            val headersMap = mutableMapOf<String, String>()
            val headersObj = json.optJSONObject("keyRequestHeaders")
            if (headersObj != null) {
                val keys = headersObj.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    headersMap[key] = headersObj.optString(key)
                }
            }

            return PlayerConfiguration(
                title = json.optString("title", ""),
                videoUrl = json.optString("videoUrl", ""),
                autoText = json.optString("autoText", ""),
                assetPath = json.optString("assetPath", ""),
                speedText = json.optString("speedText", ""),
                qualityText = json.optString("qualityText", ""),
                lastPosition = json.optLong("lastPosition", 0L),
                movieShareLink = json.optString("movieShareLink", ""),
                playVideoFromAsset = json.optBoolean("playVideoFromAsset", false),
                isScreenshotEnabled = json.optBoolean("isScreenshotEnabled", false),
                subtitles = subtitlesList,
                subtitleText = json.optString("subtitleText", "Subtitles"),
                subtitleSizeText = json.optString("subtitleSizeText", "Subtitle Size"),
                subtitleOffText = json.optString("subtitleOffText", "Off"),
                keyRequestHeaders = headersMap
            )
        }
    }
}