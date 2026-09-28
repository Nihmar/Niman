package dev.niman.niman

import java.io.ByteArrayInputStream
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.util.Arrays
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * How much the endless stream below hands over before it gives up.
 *
 * A copy with nothing counting its bytes is a bug, and a test that fills
 * the disk to say so is a bug of its own: past this the stream reports
 * the runaway read and the copy fails cheaply.
 */
private const val RUNAWAY_BYTES = 8L * 1024 * 1024

/**
 * The cap on a shared file (#386).
 *
 * Moving the copy off the UI thread keeps the app responsive while a
 * share is copied; the cap is what bounds the copy itself, so one the
 * sender made huge is refused instead of written into the cache.
 * Refused means nothing is left behind: Dart imports what is in the
 * cache, and half a share is not a share.
 */
class ShareCopyTest {
    /**
     * The cap these tests copy against.
     *
     * Small on purpose: the counting is the same at 8 KiB as at the real
     * cap, and no test has to write half a gigabyte to make the point.
     */
    private val cap = 8L * 1024

    private val dir = File(
        System.getProperty("java.io.tmpdir"),
        "niman-share-copy-test",
    )

    @Before
    fun setUp() {
        dir.deleteRecursively()
        assertTrue("the test directory is created", dir.mkdirs())
    }

    @After
    fun tearDown() {
        dir.deleteRecursively()
    }

    @Test
    fun `a share under the cap is copied whole`() {
        val data = bytes(1000)
        val copy = File(dir, "under.bin")

        val outcome = ShareCopy.read(ByteArrayInputStream(data), copy, cap)

        assertEquals(ShareCopy.Result.Copied, outcome)
        assertEquals(1000L, copy.length())
        assertTrue("the copy is the share", copy.readBytes().contentEquals(data))
    }

    @Test
    fun `a share exactly the cap is copied whole`() {
        val copy = File(dir, "exact.bin")

        val outcome = ShareCopy.read(
            ByteArrayInputStream(bytes(cap.toInt())),
            copy,
            cap,
        )

        assertEquals(ShareCopy.Result.Copied, outcome)
        assertEquals(cap, copy.length())
    }

    @Test
    fun `a share one byte over the cap is refused and leaves no copy`() {
        val copy = File(dir, "over.bin")

        val outcome = ShareCopy.read(
            ByteArrayInputStream(bytes(cap.toInt() + 1)),
            copy,
            cap,
        )

        assertEquals(ShareCopy.Result.TooLarge, outcome)
        assertFalse("the half a copy is deleted", copy.exists())
    }

    /**
     * A provider that hands over a stream with no end: the cap stops the
     * read and the share is refused.
     *
     * The timeout is the point of this one. With nothing counting the
     * bytes there is no end to read to, so the copy never returns — and
     * it used to run on the thread that draws the app (#386).
     */
    @Test(timeout = 30_000)
    fun `a stream that never ends is refused`() {
        val endless = Endless()
        val copy = File(dir, "endless.bin")

        val outcome = ShareCopy.read(endless, copy, cap)

        assertEquals(ShareCopy.Result.TooLarge, outcome)
        assertFalse(copy.exists())
        // 64 KiB is the chunk the copy reads at a time (ShareCopy.CHUNK):
        // the read ends one chunk past the cap, not at the stream's end.
        assertTrue(
            "the read stops at the cap: ${endless.read} bytes",
            endless.read <= cap + 64 * 1024,
        )
    }

    /** The cap is the one place its number lives, and what a phone is
     *  willing to write into the cache is that number. */
    @Test
    fun `the cap is half a gigabyte`() {
        assertEquals(512L * 1024 * 1024, ShareCopy.MAX_BYTES)
    }

    private fun bytes(count: Int): ByteArray = ByteArray(count) { 7 }

    /** A stream that always hands over another buffer's worth, and never
     *  reports an end. */
    private class Endless : InputStream() {
        /** How much this stream has handed over. */
        var read = 0L
            private set

        override fun read(buffer: ByteArray, offset: Int, length: Int): Int {
            if (read > RUNAWAY_BYTES) {
                // Nothing is counting the bytes on the other side: say so
                // here, where it is cheap, rather than write a diskful.
                throw IOException("no end to this stream: $read bytes")
            }
            Arrays.fill(buffer, offset, offset + length, 0)
            read += length
            return length
        }

        override fun read(): Int {
            read++
            return 0
        }
    }
}
