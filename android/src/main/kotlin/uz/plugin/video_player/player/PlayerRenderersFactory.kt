package uz.plugin.video_player.player

import android.content.Context
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.RenderersFactory
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector

/**
 * Creates a [RenderersFactory] configured for high reliability across physical devices and emulators.
 *
 * Configures:
 * 1. [DefaultRenderersFactory.setEnableDecoderFallback] enabled.
 * 2. [MediaCodecSelector] that deprioritizes emulator-specific "c2.goldfish.*" decoders.
 *    On Android 15/16 emulators (especially 16 KB page-size images like sdk_gphone16k_arm64),
 *    the goldfish Codec2 HAL fails during BufferPool message queue creation due to SELinux
 *    denials on untrusted_app memfd files. Deprioritizing goldfish allows stable fallback to
 *    standard software decoders ("c2.android.*") on emulators, while physical devices
 *    (Qualcomm, Samsung Exynos, MediaTek, Tensor) remain unaffected and use their native hardware decoders.
 */
@UnstableApi
internal fun createRenderersFactory(context: Context): RenderersFactory {
    return DefaultRenderersFactory(context)
        .setEnableDecoderFallback(true)
        .setMediaCodecSelector { mimeType, requiresSecureDecoder, requiresTunnelingDecoder ->
            val decoders = MediaCodecSelector.DEFAULT.getDecoderInfos(
                mimeType,
                requiresSecureDecoder,
                requiresTunnelingDecoder,
            )
            decoders.sortedWith { a, b ->
                val aIsGoldfish = a.name.contains("goldfish", ignoreCase = true)
                val bIsGoldfish = b.name.contains("goldfish", ignoreCase = true)
                when {
                    aIsGoldfish && !bIsGoldfish -> 1
                    !aIsGoldfish && bIsGoldfish -> -1
                    else -> 0
                }
            }
        }
}
