package uz.plugin.video_player.player

import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.ResolvingDataSource
import androidx.media3.exoplayer.hls.HlsDataSourceFactory
import androidx.media3.exoplayer.hls.HlsMediaSource
import uz.plugin.video_player.utils.UrlPolicy
import java.io.IOException

/**
 * HLS source factory whose AES-128 key requests carry [keyRequestHeaders].
 *
 * HlsChunkSource loads keys through a data source created with [C.DATA_TYPE_DRM],
 * so the headers reach the key endpoint only — playlists and segments are fetched
 * through [dataSourceFactory] without them. Key hosts are limited to the playlist host plus
 * [keyRequestHosts]. With no headers this is a plain
 * `HlsMediaSource.Factory(dataSourceFactory)`.
 */
@UnstableApi
internal fun hlsMediaSourceFactory(
    dataSourceFactory: DataSource.Factory,
    keyRequestHeaders: Map<String, String>,
    playlistUrl: String,
    keyRequestHosts: Set<String>,
): HlsMediaSource.Factory {
    if (keyRequestHeaders.isEmpty()) {
        return HlsMediaSource.Factory(dataSourceFactory)
    }
    // The key URI comes from the playlist: send the headers (bearer tokens) only over https
    // to the playlist host or an explicitly allowed host.
    val keyDataSourceFactory = ResolvingDataSource.Factory(DefaultHttpDataSource.Factory()) { dataSpec ->
        if (!UrlPolicy.isAllowedKeyUri(dataSpec.uri.toString(), playlistUrl, keyRequestHosts)) {
            throw IOException("HLS key request blocked: key URI must be https on the playlist host or a keyRequestHosts entry")
        }
        dataSpec.withAdditionalHeaders(keyRequestHeaders)
    }
    return HlsMediaSource.Factory(HlsDataSourceFactory { dataType ->
        if (dataType == C.DATA_TYPE_DRM) {
            keyDataSourceFactory.createDataSource()
        } else {
            dataSourceFactory.createDataSource()
        }
    })
}
