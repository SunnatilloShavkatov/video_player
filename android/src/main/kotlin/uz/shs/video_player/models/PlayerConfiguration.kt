package uz.shs.video_player.models

import com.google.gson.annotations.SerializedName
import java.io.Serializable

data class PlayerConfiguration(
    @SerializedName("initialResolution")
    val initialResolution: HashMap<String, String>,
    @SerializedName("resolutions")
    var resolutions: HashMap<String, String>,
    @SerializedName("qualityText")
    val qualityText: String,
    @SerializedName("speedText")
    val speedText: String,
    @SerializedName("lastPosition")
    val lastPosition: Long,
    @SerializedName("title")
    val title: String,
    @SerializedName("isSerial")
    val isSerial: Boolean,
    @SerializedName("episodeButtonText")
    val episodeButtonText: String,
    @SerializedName("nextButtonText")
    val nextButtonText: String,
    @SerializedName("seasons")
    val seasons: List<Season>,
    @SerializedName("isLive")
    val isLive: Boolean,
    @SerializedName("tvProgramsText")
    val tvProgramsText: String,
    @SerializedName("showController")
    val showController: Boolean,
    @SerializedName("playVideoFromAsset")
    val playVideoFromAsset: Boolean,
    @SerializedName("assetPath")
    val assetPath: String,
    @SerializedName("seasonIndex")
    val seasonIndex: Int,
    @SerializedName("episodeIndex")
    val episodeIndex: Int,
    @SerializedName("isMegogo")
    val isMegogo: Boolean,
    @SerializedName("isPremier")
    val isPremier: Boolean,
    @SerializedName("videoId")
    val videoId: String,
    @SerializedName("sessionId")
    val sessionId: String,
    @SerializedName("megogoAccessToken")
    val megogoAccessToken: String,
    @SerializedName("authorization")
    val authorization: String,
    @SerializedName("autoText")
    val autoText: String,
    @SerializedName("baseUrl")
    val baseUrl: String,
    @SerializedName("fromCache")
    val fromCache: Boolean,
    @SerializedName("movieShareLink")
    val movieShareLink: String,
    @SerializedName("selectChannelIndex")
    val selectChannelIndex: Int,
    @SerializedName("selectTvCategoryIndex")
    val selectTvCategoryIndex: Int,
) : Serializable