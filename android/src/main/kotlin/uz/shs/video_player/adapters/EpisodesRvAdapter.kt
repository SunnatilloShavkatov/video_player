package uz.shs.video_player.adapters

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import uz.shs.video_player.R
import uz.shs.video_player.models.Movie
import uz.shs.video_player.utils.MyHelper

class EpisodesRvAdapter(
    var context: Context,
    var list: List<Movie>,
    private var seasonIndex: Int,
    private var currentSeasonIndex: Int,
    private var episodeIndex: Int,
    private var onClickListener: OnClickListener
) :
    RecyclerView.Adapter<EpisodesRvAdapter.Vh>() {

    inner class Vh(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val title: TextView
        val description: TextView
        val duration: TextView
        val image: ImageView

        init {
            title = itemView.findViewById(R.id.episode_item_title)
            description = itemView.findViewById(R.id.episode_item_description)
            duration = itemView.findViewById(R.id.episode_item_duration)
            image = itemView.findViewById(R.id.episode_item_image)
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Vh {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.episode_item, parent, false)

        return Vh(view)
    }

    override fun onBindViewHolder(holder: Vh, position: Int) {
        holder.title.text = list[position].title
        if (position == episodeIndex && currentSeasonIndex == seasonIndex) {
            holder.title.setTextColor(ContextCompat.getColor(context, R.color.blue))
            holder.description.setTextColor(ContextCompat.getColor(context, R.color.blue))
        }
        holder.description.text = list[position].description
        holder.duration.text = MyHelper().formatDuration(list[position].duration)
        Glide.with(context)
            .load(list[position].image)
            .placeholder(R.drawable.ic_play)
            .into(holder.image)
        holder.image.setOnClickListener {
            onClickListener.onClick(position)
        }
    }

    override fun getItemCount(): Int {
        return list.size
    }

    interface OnClickListener {
        fun onClick(episodeIndex: Int)
    }

}