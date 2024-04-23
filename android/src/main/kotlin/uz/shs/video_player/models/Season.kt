package uz.shs.video_player.models

import com.google.gson.annotations.SerializedName
import java.io.Serializable

data class Season(
    @SerializedName("title")
    val title: String,
    @SerializedName("movies")
    val movies: List<Movie>,
) : Serializable