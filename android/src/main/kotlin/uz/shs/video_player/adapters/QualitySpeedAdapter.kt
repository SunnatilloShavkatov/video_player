package uz.shs.video_player.adapters

import android.annotation.SuppressLint
import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.BaseAdapter
import android.widget.ImageView
import android.widget.TextView
import uz.shs.video_player.R


class QualitySpeedAdapter(
    private val currentValue: String,
    private val context: Context,
    private val items: ArrayList<String>,
    private var onClickListener: OnClickListener,
) : BaseAdapter() {

    override fun getCount(): Int {
        return items.size
    }

    override fun getItem(position: Int): String {
        return items[position]
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    @SuppressLint("ViewHolder")
    override fun getView(position: Int, convertView: View?, parent: ViewGroup?): View {
        val view: View =
            LayoutInflater.from(context).inflate(R.layout.quality_speed_item, parent, false)
        view.setOnClickListener {
            onClickListener.onClick(position)
        }
        val currentItem = getItem(position)
        val text = view.findViewById<TextView>(R.id.quality_speed_item_text)
        val icon = view.findViewById<ImageView>(R.id.quality_speed_item_icon)
        text?.text = currentItem
        if (currentItem == currentValue) {
            icon?.visibility = View.VISIBLE
        }
        return view
    }

    interface OnClickListener {
        fun onClick(position: Int)
    }
}