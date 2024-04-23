package uz.shs.video_player.models

import com.google.gson.annotations.SerializedName
import java.io.Serializable

data class DownloadConfiguration(
    @SerializedName("title")
    val title: String,
    @SerializedName("url")
    val url: String,
) : Serializable