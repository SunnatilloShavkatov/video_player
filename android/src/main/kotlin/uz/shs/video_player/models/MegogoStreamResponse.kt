package uz.shs.video_player.models

data class MegogoStreamResponse(
    val result: String?,
    val code: Int?,
    val `data`: Data?
) {
    data class Data(
        val video_id: Int?,
        val title: String?,
        val hierarchy_titles: HierarchyTitles?,
        val src: String?,
        val drm_type: String?,
        val stream_type: String?,
        val content_type: String?,
        val audio_tracks: List<AudioTrack?>?,
        val subtitles: List<Subtitle?>?,
        val bitrates: List<Bitrate?>?,
        val cdn_id: Int?,
        val advert_url: String?,
        val allow_external_streaming: Boolean?,
        val start_session_url: String?,
        val parental_control_required: Boolean?,
        val play_start_time: Int?,
        val wvls: String?,
        val watermark: String?,
        val watermark_clickable_enabled: Boolean?,
        val show_best_quality_link: Boolean?,
        val share_link: String?,
        val credits_start: Int?,
        val external_source: Boolean?,
        val preview_images: PreviewImages?,
        val is_autoplay: Boolean?,
        val is_wvdrm: Boolean?,
        val is_embed: Boolean?,
        val is_hierarchy: Boolean?,
        val is_live: Boolean?,
        val is_tv: Boolean?,
        val is_3d: Boolean?,
        val is_uhd: Boolean?,
        val is_uhd_8k: Boolean?,
        val is_hdr: Boolean?,
        val is_favorite: Boolean?
    ) {
        data class HierarchyTitles(
            val VIDEO: String?
        )

        data class AudioTrack(
            val id: Int?,
            val lang: String?,
            val lang_tag: String?,
            val lang_original: String?,
            val display_name: String?,
            val index: Int?,
            val require_subtitles: Boolean?,
            val lang_iso_639_1: String?,
            val is_active: Boolean?
        )

        data class Subtitle(
            val display_name: String?,
            val index: Int?,
            val lang: String?,
            val lang_iso_639_1: String?,
            val lang_original: String?,
            val lang_tag: String?,
            val type: String?,
            val url: String?
        )

        data class Bitrate(
            val bitrate: Int?,
            val src: String?
        )

        data class PreviewImages(
            val thumbsline_xml: String?,
            val thumbsline_list: List<Thumbsline?>?,
            val thumbsline_list_full_hd: List<ThumbslineFullHd?>?,
            val thumbsline_list_uhd: List<ThumbslineUhd?>?
        ) {
            data class Thumbsline(
                val id: Int?,
                val url: String?
            )

            data class ThumbslineFullHd(
                val id: Int?,
                val url: String?
            )

            data class ThumbslineUhd(
                val id: Int?,
                val url: String?
            )
        }
    }
}