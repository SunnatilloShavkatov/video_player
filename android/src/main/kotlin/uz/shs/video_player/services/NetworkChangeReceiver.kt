package uz.shs.video_player.services

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper

class NetworkChangeReceiver(
    context: Context,
    private val onConnected: () -> Unit,
    private val onDisconnected: () -> Unit,
) {
    private val appContext = context.applicationContext
    private val connectivityManager =
        appContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val mainHandler = Handler(Looper.getMainLooper())

    private var isRegistered = false
    private var isConnected = hasValidatedConnection()

    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            notifyIfConnectionChanged()
        }

        override fun onCapabilitiesChanged(network: Network, networkCapabilities: NetworkCapabilities) {
            notifyIfConnectionChanged()
        }

        override fun onLost(network: Network) {
            notifyIfConnectionChanged()
        }

        override fun onUnavailable() {
            notifyIfConnectionChanged()
        }
    }

    fun start() {
        if (isRegistered) {
            return
        }

        isConnected = hasValidatedConnection()
        try {
            connectivityManager.registerDefaultNetworkCallback(networkCallback)
            isRegistered = true
        } catch (_: Exception) {
            isRegistered = false
        }
    }

    fun stop() {
        if (!isRegistered) {
            return
        }

        try {
            connectivityManager.unregisterNetworkCallback(networkCallback)
        } catch (_: Exception) {
            // Ignore unregister failures during shutdown races.
        }

        isRegistered = false
    }

    fun hasConnection(): Boolean = hasValidatedConnection()

    private fun notifyIfConnectionChanged() {
        val nowConnected = hasValidatedConnection()
        if (nowConnected == isConnected) {
            return
        }

        isConnected = nowConnected
        mainHandler.post {
            if (nowConnected) {
                onConnected()
            } else {
                onDisconnected()
            }
        }
    }

    private fun hasValidatedConnection(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
            capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    }
}