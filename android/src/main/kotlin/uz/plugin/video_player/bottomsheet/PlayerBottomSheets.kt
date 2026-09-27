package uz.plugin.video_player.bottomsheet

import android.annotation.SuppressLint
import android.app.Activity
import android.content.res.Configuration
import android.view.View
import android.widget.ImageView
import android.widget.ListView
import android.widget.TextView
import androidx.core.view.isVisible
import androidx.media3.common.util.UnstableApi
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.google.android.material.bottomsheet.BottomSheetDialog
import uz.plugin.video_player.R
import uz.plugin.video_player.models.PlayerConfiguration
import uz.plugin.video_player.models.QualityOption
import uz.plugin.video_player.player.PlayerController
import uz.plugin.video_player.subtitles.SubtitleController

/**
 * Full-screen player settings: the settings sheet and the quality / speed /
 * subtitle / subtitle-size pickers opened from it. At most one settings sheet
 * and one picker are open at a time.
 */
@UnstableApi
class PlayerBottomSheets(
    private val activity: Activity,
    private val config: PlayerConfiguration,
    private val subtitles: SubtitleController,
    private val controller: () -> PlayerController?,
) {
    private companion object {
        const val AUTO_QUALITY = "Auto"
        val SPEEDS = listOf("0.5x", "1.0x", "1.5x", "2.0x")
    }

    /** Quality options reported by the player; the first entry is "Auto". */
    var availableQualities: List<QualityOption> = emptyList()

    private val openDialogs = mutableListOf<BottomSheetDialog>()
    private var isSettingsOpen = false
    private var isPickerOpen = false
    private var settingsBackButton: ImageView? = null
    private var pickerBackButton: ImageView? = null

    private var currentQuality = AUTO_QUALITY
    private var currentSpeed = "1.0x"
    private var qualityValue: TextView? = null
    private var speedValue: TextView? = null
    private var subtitleValue: TextView? = null
    private var subtitleSizeValue: TextView? = null

    private val showsBackButton: Boolean
        get() = activity.resources.configuration.orientation != Configuration.ORIENTATION_PORTRAIT

    // MARK: - Settings

    fun showSettings() {
        if (isSettingsOpen) return
        isSettingsOpen = true
        val dialog = createDialog(R.layout.settings_bottom_sheet, draggable = true)
        settingsBackButton = dialog.bindBackButton(R.id.settings_sheet_back)

        dialog.findViewById<TextView>(R.id.quality_settings_text)?.text = config.qualityText
        dialog.findViewById<TextView>(R.id.speed_settings_text)?.text = config.speedText
        qualityValue = dialog.findViewById<TextView>(R.id.quality_settings_value_text)?.apply { text = currentQuality }
        speedValue = dialog.findViewById<TextView>(R.id.speed_settings_value_text)?.apply { text = currentSpeed }
        dialog.findViewById<View>(R.id.quality)?.setOnClickListener { showQualityPicker() }
        dialog.findViewById<View>(R.id.speed)?.setOnClickListener { showSpeedPicker() }
        bindSubtitleRows(dialog)

        dialog.onDismiss { isSettingsOpen = false }
        dialog.show()
    }

    @SuppressLint("SetTextI18n")
    private fun bindSubtitleRows(dialog: BottomSheetDialog) {
        val trackRow = dialog.findViewById<View>(R.id.subtitle)
        val sizeRow = dialog.findViewById<View>(R.id.subtitle_size)
        trackRow?.isVisible = subtitles.hasTracks
        sizeRow?.isVisible = subtitles.hasTracks
        if (!subtitles.hasTracks) return

        dialog.findViewById<ImageView>(R.id.subtitle_size_icon)?.setImageDrawable(createTextSizeIcon(activity.resources))
        dialog.findViewById<TextView>(R.id.subtitle_settings_text)?.text = config.subtitleText
        dialog.findViewById<TextView>(R.id.subtitle_size_settings_text)?.text = config.subtitleSizeText
        subtitleValue = dialog.findViewById<TextView>(R.id.subtitle_settings_value_text)
            ?.apply { text = subtitles.selectionLabel }
        subtitleSizeValue = dialog.findViewById<TextView>(R.id.subtitle_size_settings_value_text)
            ?.apply { text = "${subtitles.sizePercent}%" }
        trackRow?.setOnClickListener { showSubtitleTrackPicker() }
        sizeRow?.setOnClickListener { showSubtitleSizePicker() }
    }

    // MARK: - Pickers

    private fun showQualityPicker() {
        if (availableQualities.isEmpty()) return
        // "Auto" first, then numeric qualities ("1080p") from highest to lowest.
        val (numeric, other) = availableQualities.map { it.displayName }
            .partition { it.dropLast(1).toIntOrNull() != null }
        val options = other.takeLast(1) + numeric.sortedByDescending { it.dropLast(1).toInt() }

        showPicker(config.qualityText, options, currentQuality) { position ->
            val option = availableQualities.firstOrNull { it.displayName == options[position] }
                ?: return@showPicker
            currentQuality = option.displayName
            qualityValue?.text = currentQuality
            if (option.displayName == AUTO_QUALITY) {
                controller()?.applyAutomaticQuality()
            } else {
                controller()?.applyManualQuality(option)
            }
        }
    }

    private fun showSpeedPicker() {
        showPicker(config.speedText, SPEEDS, currentSpeed) { position ->
            currentSpeed = SPEEDS[position]
            speedValue?.text = currentSpeed
            controller()?.setPlaybackSpeed(currentSpeed.removeSuffix("x").toFloat())
        }
    }

    private fun showSubtitleTrackPicker() {
        showPicker(config.subtitleText, subtitles.trackOptions, subtitles.selectionLabel) { position ->
            subtitles.selectTrack(position)
            subtitleValue?.text = subtitles.selectionLabel
        }
    }

    @SuppressLint("SetTextI18n")
    private fun showSubtitleSizePicker() {
        val options = SubtitleController.SIZE_OPTIONS
        showPicker(config.subtitleSizeText, options, "${subtitles.sizePercent}%") { position ->
            subtitles.setSizePercent(options[position].removeSuffix("%").toIntOrNull() ?: 100)
            subtitleSizeValue?.text = "${subtitles.sizePercent}%"
        }
    }

    /** Single-choice list sheet; [onSelect] gets the tapped index, then the sheet closes. */
    private fun showPicker(title: String, options: List<String>, selected: String, onSelect: (Int) -> Unit) {
        if (isPickerOpen) return
        isPickerOpen = true
        val dialog = createDialog(R.layout.quality_speed_sheet, draggable = false)
        pickerBackButton = dialog.bindBackButton(R.id.quality_speed_sheet_back)
        dialog.findViewById<TextView>(R.id.quality_speed_text)?.text = title
        dialog.findViewById<ListView>(R.id.quality_speed_listview)?.adapter =
            QualitySpeedAdapter(selected, activity, ArrayList(options)) { position ->
                onSelect(position)
                dialog.dismiss()
            }
        dialog.onDismiss { isPickerOpen = false }
        dialog.show()
    }

    // MARK: - Lifecycle

    /** Back buttons are shown only in landscape, where the sheet covers the close control. */
    fun onOrientationChanged() {
        settingsBackButton?.isVisible = showsBackButton
        pickerBackButton?.isVisible = showsBackButton
    }

    fun dismissAll() {
        val dialogs = openDialogs.toList()
        openDialogs.clear()
        dialogs.forEach { dialog ->
            runCatching { if (dialog.isShowing) dialog.dismiss() }
        }
        isSettingsOpen = false
        isPickerOpen = false
    }

    private fun createDialog(layout: Int, draggable: Boolean): BottomSheetDialog =
        BottomSheetDialog(activity, R.style.BottomSheetDialog).apply {
            openDialogs.add(this)
            behavior.isDraggable = draggable
            behavior.state = BottomSheetBehavior.STATE_EXPANDED
            setContentView(layout)
        }

    private fun BottomSheetDialog.bindBackButton(id: Int): ImageView? =
        findViewById<ImageView>(id)?.apply {
            isVisible = showsBackButton
            setOnClickListener { dismiss() }
        }

    private fun BottomSheetDialog.onDismiss(action: () -> Unit) {
        setOnDismissListener {
            openDialogs.remove(this)
            action()
        }
    }
}
