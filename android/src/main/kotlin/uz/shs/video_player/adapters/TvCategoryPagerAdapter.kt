package uz.shs.video_player.adapters

import android.annotation.SuppressLint
import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import uz.shs.video_player.R
import uz.shs.video_player.models.TvCategories

class TvCategoryPagerAdapter(
    var context: Context,
    private var tvCategories: List<TvCategories>,
    private var onClickListener: OnClickListener
) :
    RecyclerView.Adapter<TvCategoryPagerAdapter.Vh>() {
    inner class Vh(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val rv: RecyclerView

        init {
            rv = itemView.findViewById(R.id.bottom_sheet_channels_rv)
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Vh {
        val view =
            LayoutInflater.from(parent.context)
                .inflate(R.layout.bottom_sheet_channels, parent, false)
        return Vh(view)
    }

    override fun onBindViewHolder(holder: Vh, @SuppressLint("RecyclerView") position: Int) {
        val layoutManager =
            LinearLayoutManager(context, LinearLayoutManager.HORIZONTAL, false)
        holder.rv.layoutManager = layoutManager
        holder.rv.adapter = TvChannelsRvAdapter(
            context,
            tvCategories[position].channels,
            object : TvChannelsRvAdapter.OnClickListener {
                override fun onClick(index: Int) {
                    onClickListener.onClick(position, index)
                }
            }
        )
    }

    override fun getItemCount(): Int {
        return tvCategories.size
    }

    interface OnClickListener {
        fun onClick(tvCIndex: Int, cIndex: Int)
    }

}