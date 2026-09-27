package uz.plugin.video_player.player

import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.hls.HlsDataSourceFactory
import androidx.media3.exoplayer.hls.HlsMediaSource

/**
 * HLS source factory whose AES-128 key requests carry [keyRequestHeaders].
 *
 * HlsChunkSource loads keys through a data source created with [C.DATA_TYPE_DRM],
 * so the headers reach the key endpoint only — playlists and segments are fetched
 * through [dataSourceFactory] without them. With no headers this is a plain
 * `HlsMediaSource.Factory(dataSourceFactory)`.
 */
@UnstableApi
internal fun hlsMediaSourceFactory(
    dataSourceFactory: DataSource.Factory,
    keyRequestHeaders: Map<String, String>,
): HlsMediaSource.Factory {
    if (keyRequestHeaders.isEmpty()) {
        return HlsMediaSource.Factory(dataSourceFactory)
    }
    val keyDataSourceFactory = DefaultHttpDataSource.Factory()
        .setDefaultRequestProperties(keyRequestHeaders)
    return HlsMediaSource.Factory(HlsDataSourceFactory { dataType ->
        if (dataType == C.DATA_TYPE_DRM) {
            keyDataSourceFactory.createDataSource()
        } else {
            dataSourceFactory.createDataSource()
        }
    })
}
