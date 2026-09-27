package uz.plugin.video_player.bottomsheet

import android.content.res.Resources
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable

/**
 * Subtitle size glyph: a small "A" next to a large "A", matching the
 * `textformat.size` symbol iOS uses for the same row.
 */
internal fun createTextSizeIcon(resources: Resources): Drawable {
    val density = resources.displayMetrics.density
    val sizePx = (24f * density).toInt()
    val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    val smallPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        typeface = Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD)
        textSize = 12f * density
    }
    val largePaint = Paint(smallPaint).apply { textSize = 19f * density }

    val gap = 1.5f * density
    val smallWidth = smallPaint.measureText("A")
    val largeWidth = largePaint.measureText("A")
    val startX = (sizePx - (smallWidth + largeWidth + gap)) / 2f
    val metrics = largePaint.fontMetrics
    val baseline = sizePx / 2f - (metrics.ascent + metrics.descent) / 2f

    canvas.drawText("A", startX, baseline, smallPaint)
    canvas.drawText("A", startX + smallWidth + gap, baseline, largePaint)

    return BitmapDrawable(resources, bitmap)
}
