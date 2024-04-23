package uz.shs.video_player.models

import com.google.gson.annotations.SerializedName
import java.io.Serializable

data class TvProgram(
    @SerializedName("scheduledTime")
    val scheduledTime: String,
    @SerializedName("programTitle")
    val programTitle: String,
) : Serializable