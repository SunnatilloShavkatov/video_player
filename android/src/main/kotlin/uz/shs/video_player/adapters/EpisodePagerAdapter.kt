package uz.shs.video_player.adapters

import android.annotation.SuppressLint
import android.content.Context
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.recyclerview.widget.RecyclerView.OnItemTouchListener
import androidx.viewpager2.widget.ViewPager2
import uz.shs.video_player.R
import uz.shs.video_player.models.Season


class EpisodePagerAdapter(
    var viewPager: ViewPager2,
    var context: Context,
    private var seasons: List<Season>,
    private var seasonIndex: Int,
    private var episodeIndex: Int,
    var onClickListener: OnClickListener
) :
    RecyclerView.Adapter<EpisodePagerAdapter.Vh>() {
    inner class Vh(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val rv: RecyclerView

        init {
            rv = itemView.findViewById(R.id.episodes_rv)
            rv.addOnItemTouchListener(object : OnItemTouchListener {
                var lastX = 0
                override fun onInterceptTouchEvent(rv: RecyclerView, e: MotionEvent): Boolean {
                    when (e.action) {
                        MotionEvent.ACTION_DOWN -> lastX = e.x.toInt()
                        MotionEvent.ACTION_MOVE -> {
                            val isScrollingRight = e.x < lastX
                            viewPager.isUserInputEnabled =
                                isScrollingRight && (rv.layoutManager as LinearLayoutManager).findLastCompletelyVisibleItemPosition() == rv.adapter!!.itemCount - 1 ||
                                        !isScrollingRight && (rv.layoutManager as LinearLayoutManager).findFirstCompletelyVisibleItemPosition() == 0
                        }

                        MotionEvent.ACTION_UP -> {
                            lastX = 0
                            viewPager.isUserInputEnabled = true
                        }
                    }
                    return false
                }

                override fun onTouchEvent(rv: RecyclerView, e: MotionEvent) {}
                override fun onRequestDisallowInterceptTouchEvent(disallowIntercept: Boolean) {}
            })
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Vh {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.episode_page, parent, false)
        return Vh(view)
    }

    override fun onBindViewHolder(holder: Vh, @SuppressLint("RecyclerView") position: Int) {
        val layoutManager =
            LinearLayoutManager(context, LinearLayoutManager.HORIZONTAL, false)
        holder.rv.layoutManager = layoutManager
        holder.rv.adapter = EpisodesRvAdapter(
            context,
            seasons[position].movies,
            position,
            seasonIndex,
            episodeIndex,
            object : EpisodesRvAdapter.OnClickListener {
                override fun onClick(episodeIndex: Int) {
                    onClickListener.onClick(episodeIndex, position)
                }
            },
        )
    }

    override fun getItemCount(): Int {
        return seasons.size
    }

    interface OnClickListener {
        fun onClick(epIndex: Int, seasIndex: Int)
    }
}