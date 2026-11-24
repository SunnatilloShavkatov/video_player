package uz.plugin.video_player.utils

/**
 * The plugin instances of every attached engine. An app can run several engines at once (a background
 * `FlutterEngine` for push messages, add-to-app, engine groups), so one static field would be overwritten by the
 * newest engine and cleared when that engine goes away. [current] prefers the newest host that [canServe], then the
 * newest host at all.
 */
internal class HostRegistry<T : Any>(private val canServe: (T) -> Boolean) {
    private val hosts = mutableListOf<T>()

    @Synchronized
    fun add(host: T) {
        hosts.remove(host)
        hosts.add(host)
    }

    @Synchronized
    fun remove(host: T) {
        hosts.remove(host)
    }

    @Synchronized
    fun current(): T? = hosts.lastOrNull(canServe) ?: hosts.lastOrNull()

    @Synchronized
    fun all(): List<T> = hosts.toList()
}
