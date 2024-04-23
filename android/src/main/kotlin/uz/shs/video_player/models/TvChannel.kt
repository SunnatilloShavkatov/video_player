package uz.shs.video_player.models

import com.google.gson.annotations.SerializedName
import java.io.Serializable

data class TvChannel(
    @SerializedName("id")
    val id: String,
    @SerializedName("image")
    val image: String,
    @SerializedName("name")
    val name: String,
    @SerializedName("resolutions")
    var resolutions: HashMap<String, String>
) : Serializable