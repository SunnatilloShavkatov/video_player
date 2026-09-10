package uz.shs.video_player.models

import com.google.gson.annotations.SerializedName
import java.io.Serializable

data class SubtitleTrack(
    @SerializedName("id") val id: Long = 0,
    @SerializedName("label") val label: String = "",
    @SerializedName("lang") val lang: String = "",
    @SerializedName("is_default") val isDefault: Boolean = false,
    @SerializedName("url") val url: String = "",
) : Serializable
