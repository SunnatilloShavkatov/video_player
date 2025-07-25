package uz.shs.video_player.models

import com.google.gson.annotations.SerializedName
import java.io.Serializable

data class PlayerConfiguration(
    @SerializedName("title") val title: String,
    @SerializedName("autoText") val autoText: String,
    @SerializedName("assetPath") val assetPath: String,
    @SerializedName("speedText") val speedText: String,
    @SerializedName("qualityText") val qualityText: String,
    @SerializedName("lastPosition") val lastPosition: Long,
    @SerializedName("movieShareLink") val movieShareLink: String,
    @SerializedName("playVideoFromAsset") val playVideoFromAsset: Boolean,
    @SerializedName("resolutions") var resolutions: HashMap<String, String>,
    @SerializedName("initialResolution") val initialResolution: HashMap<String, String>,
) : Serializable