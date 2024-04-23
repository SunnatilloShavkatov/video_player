package uz.shs.video_player.models

import com.google.gson.annotations.SerializedName
import java.io.Serializable

data class ProgramsInfo(
    @SerializedName("day")
    val day: String,
    @SerializedName("tvPrograms")
    val tvPrograms: List<TvProgram>,
) : Serializable