package uz.shs.video_player.adapters

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import uz.shs.video_player.R
import uz.shs.video_player.models.TvProgram

class TvProgramsRvAdapter(var list: List<TvProgram>) :
    RecyclerView.Adapter<TvProgramsRvAdapter.Vh>() {

    inner class Vh(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val title: TextView
        val time: TextView

        init {
            title = itemView.findViewById(R.id.tv_program_item_title)
            time = itemView.findViewById(R.id.tv_program_item_time)
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Vh {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.tv_program_item, parent, false)

        return Vh(view)
    }

    override fun onBindViewHolder(holder: Vh, position: Int) {
        holder.title.text = list[position].programTitle
        holder.time.text = list[position].scheduledTime
    }

    override fun getItemCount(): Int {
        return list.size
    }

}