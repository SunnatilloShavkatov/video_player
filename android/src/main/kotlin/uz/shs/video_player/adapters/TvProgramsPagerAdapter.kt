package uz.shs.video_player.adapters

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import uz.shs.video_player.R
import uz.shs.video_player.models.ProgramsInfo

class TvProgramsPagerAdapter(
    var context: Context,
    private var programsInfoList: List<ProgramsInfo>,
) :
    RecyclerView.Adapter<TvProgramsPagerAdapter.Vh>() {
    inner class Vh(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val rv: RecyclerView

        init {
            rv = itemView.findViewById(R.id.tv_programs_rv)
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Vh {
        val view =
            LayoutInflater.from(parent.context).inflate(R.layout.tv_program_page, parent, false)
        return Vh(view)
    }

    override fun onBindViewHolder(holder: Vh, position: Int) {
        val layoutManager =
            LinearLayoutManager(context, LinearLayoutManager.VERTICAL, false)
        holder.rv.layoutManager = layoutManager
        holder.rv.adapter = TvProgramsRvAdapter(programsInfoList[position].tvPrograms)
    }

    override fun getItemCount(): Int {
        return programsInfoList.size
    }

}