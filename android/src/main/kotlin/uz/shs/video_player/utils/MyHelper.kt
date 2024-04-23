package uz.shs.video_player.utils

class MyHelper {
    fun formatDuration(duration: Long): String {
        var seconds = duration
        val hours: Int = (seconds / 3600).toInt()
        seconds %= 3600
        val minutes: Int = (seconds / 60).toInt()
        seconds %= 60

        val hoursString = if (hours >= 10)
            "$hours" else
            if (hours == 0)
                "00"
            else "0$hours"

        val minutesString = if (minutes >= 10)
            "$minutes" else
            if (minutes == 0)
                "00"
            else "0$minutes"

        val secondsString = if (seconds >= 10)
            "$seconds"
        else if (seconds.toInt() == 0)
            "00"
        else "0$seconds"

        return "${if (hoursString == "00") "" else "$hoursString:"}$minutesString:$secondsString"
    }
}