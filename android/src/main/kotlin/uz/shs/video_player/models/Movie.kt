package uz.shs.video_player.models

import com.google.gson.annotations.SerializedName
import java.io.Serializable

data class Movie(
    @SerializedName("id")
    val id: String,
    @SerializedName("title")
    val title: String,
    @SerializedName("description")
    val description: String,
    @SerializedName("image")
    val image: String,
    @SerializedName("duration")
    val duration: Long,
    @SerializedName("resolutions")
    var resolutions: HashMap<String, String>
) : Serializable