package uz.shs.video_player.retrofit

object Common {
    fun retrofitService(baseUrl: String): RetrofitService {
        return RetrofitClient.getRetrofit(baseUrl).create(RetrofitService::class.java)
    }
}