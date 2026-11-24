package uz.plugin.video_player.utils

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class HostRegistryTest {
    private class Host(val name: String, var canServe: Boolean)

    private val registry = HostRegistry<Host> { it.canServe }

    @Test
    fun emptyRegistryHasNoHost() {
        assertNull(registry.current())
    }

    @Test
    fun backgroundEngineDoesNotReplaceTheEngineWithAnActivity() {
        val main = Host("main", canServe = true)
        val background = Host("background", canServe = false)
        registry.add(main)
        registry.add(background)

        assertEquals(main, registry.current())
    }

    @Test
    fun detachingTheBackgroundEngineKeepsTheMainOne() {
        val main = Host("main", canServe = true)
        val background = Host("background", canServe = false)
        registry.add(main)
        registry.add(background)
        registry.remove(background)

        assertEquals(main, registry.current())
    }

    @Test
    fun newestServingHostWins() {
        val first = Host("first", canServe = true)
        val second = Host("second", canServe = true)
        registry.add(first)
        registry.add(second)

        assertEquals(second, registry.current())
    }

    @Test
    fun fallsBackToNewestHostWhenNoneCanServe() {
        val first = Host("first", canServe = false)
        val second = Host("second", canServe = false)
        registry.add(first)
        registry.add(second)

        assertEquals(second, registry.current())
    }

    @Test
    fun reAddingMovesHostToNewest() {
        val first = Host("first", canServe = true)
        val second = Host("second", canServe = true)
        registry.add(first)
        registry.add(second)
        registry.add(first)

        assertEquals(first, registry.current())
        assertEquals(listOf(second, first), registry.all())
    }
}
