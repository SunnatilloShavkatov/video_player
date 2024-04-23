package uz.shs.video_player.adapters

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import uz.shs.video_player.R
import uz.shs.video_player.models.TvChannel

class ChannelsRvAdapter(
    var context: Context,
    var list: List<TvChannel>,
    private var onClickListener: OnClickListener
) :
    RecyclerView.Adapter<ChannelsRvAdapter.Vh>() {

    inner class Vh(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val image: ImageView

        init {
            image = itemView.findViewById(R.id.channel_image)
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Vh {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_channel, parent, false)
        return Vh(view)
    }

    override fun onBindViewHolder(holder: Vh, position: Int) {
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
        fun onClick(index: Int)
    }

}