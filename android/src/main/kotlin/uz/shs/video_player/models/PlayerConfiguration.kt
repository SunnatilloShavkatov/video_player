package uz.shs.video_player.models

import com.google.gson.annotations.SerializedName
import java.io.Serializable

data class PlayerConfiguration(
    @SerializedName("title") val title: String,
    @SerializedName("videoUrl") val videoUrl: String,
    @SerializedName("autoText") val autoText: String,
    @SerializedName("assetPath") val assetPath: String,
    @SerializedName("speedText") val speedText: String,
    @SerializedName("qualityText") val qualityText: String,
    @SerializedName("lastPosition") val lastPosition: Long,
    @SerializedName("movieShareLink") val movieShareLink: String,
    @SerializedName("playVideoFromAsset") val playVideoFromAsset: Boolean,
    @SerializedName("isScreenshotEnabled") val isScreenshotEnabled: Boolean = false,
    @SerializedName("subtitles") val subtitles: List<SubtitleTrack> = emptyList(),
    @SerializedName("subtitleText") val subtitleText: String = "Subtitles",
    @SerializedName("subtitleSizeText") val subtitleSizeText: String = "Subtitle Size",
    @SerializedName("subtitleOffText") val subtitleOffText: String = "Off",
) : Serializable