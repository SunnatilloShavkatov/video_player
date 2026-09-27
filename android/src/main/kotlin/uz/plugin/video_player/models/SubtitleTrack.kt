package uz.plugin.video_player.models

import org.json.JSONObject
import java.io.Serializable

data class SubtitleTrack(
    val id: String = "",
    val label: String = "",
    val lang: String = "",
    val isDefault: Boolean = false,
    val url: String = "",
) : Serializable {
    companion object {
        fun fromJson(json: JSONObject): SubtitleTrack = SubtitleTrack(
            id = json.optString("id", ""),
            label = json.optString("label", ""),
            lang = json.optString("lang", ""),
            isDefault = json.optBoolean("is_default", false),
            url = json.optString("url", "")
        )
    }
}
