package uz.plugin.video_player.player

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class BrightnessLevelTest {
    private val max = 30

    @Test
    fun systemValueIsScaledFrom255() {
        assertEquals(0.0, BrightnessLevel.fromSystem(0, max), 0.0001)
        assertEquals(15.0, BrightnessLevel.fromSystem(127, max), 0.1)
        assertEquals(30.0, BrightnessLevel.fromSystem(255, max), 0.0001)
    }

    @Test
    fun midSystemBrightnessDoesNotStartNearMax() {
        assertEquals(true, BrightnessLevel.fromSystem(40, max) < 5.0)
    }

    @Test
    fun systemValueOutOfRangeIsClamped() {
        assertEquals(30.0, BrightnessLevel.fromSystem(1023, max), 0.0001)
        assertEquals(0.0, BrightnessLevel.fromSystem(-1, max), 0.0001)
    }

    @Test
    fun windowOverrideIsUsedWhenSet() {
        assertEquals(15.0, BrightnessLevel.fromWindow(0.5f, max)!!, 0.0001)
        assertEquals(30.0, BrightnessLevel.fromWindow(1.5f, max)!!, 0.0001)
    }

    @Test
    fun windowFollowingSystemHasNoOverride() {
        assertNull(BrightnessLevel.fromWindow(-1f, max))
    }

    @Test
    fun stepIsClampedToMax() {
        assertEquals(30, BrightnessLevel.step(30.9, max))
        assertEquals(0, BrightnessLevel.step(-0.1, max))
        assertEquals(12, BrightnessLevel.step(12.8, max))
    }
}
