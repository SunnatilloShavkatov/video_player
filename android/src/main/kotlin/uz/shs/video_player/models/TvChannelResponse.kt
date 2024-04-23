package uz.shs.video_player.models

import com.google.gson.annotations.SerializedName
import java.io.Serializable

data class TvChannelResponse(
    @SerializedName("flusonic_id")
    val flusonicId: String,
    @SerializedName("id")
    val id: String,
    @SerializedName("title_ru")
    val titleRu: String,
    @SerializedName("title_en")
    val titleEn: String,
    @SerializedName("title_uz")
    val titleUz: String,
    @SerializedName("xml_title")
    val xmlTitle: String,
    @SerializedName("description_en")
    val descriptionEn: String,
    @SerializedName("description_ru")
    val descriptionRu: String,
    @SerializedName("description_uz")
    val descriptionUz: String,
    @SerializedName("status")
    val status: Boolean,
    @SerializedName("image")
    val image: String,
    @SerializedName("channel_stream_all")
    val channelStreamAll: String,
    @SerializedName("channel_stream_ios")
    val channelStreamIos: String,
    @SerializedName("payment_type")
    val paymentType: String,
    @SerializedName("region_type")
    val regionType: String,
    @SerializedName("category_id")
    val categoryId: String,
    @SerializedName("programs_info")
    val programsInfo: List<ProgramsInfo>,
    @SerializedName("background_image")
    val backgroundImage: String,
    @SerializedName("test_stream")
    val testStream: String,
    @SerializedName("secret_key")
    val secretKey: String,
) : Serializable