package dev.flutterquill.quill_native_bridge.util

import android.content.ContentResolver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.net.Uri
import android.os.Build
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream

/**
 * Similar to [ImageDecoder] but compatible with older Android versions by fallback to use
 * older APIs. Always downsamples with [BitmapFactory.Options.inSampleSize].
 */
object ImageDecoderCompat {
    private const val MAX_EDGE = 2048

    @Throws(IOException::class)
    fun decodeBitmapFromBytes(imageBytes: ByteArray): Bitmap =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val source = ImageDecoder.createSource(imageBytes)
            decodeWithImageDecoder(source)
        } else {
            decodeByteArray(imageBytes)
                ?: throw IOException("Image could not be decoded using the `BitmapFactory.decodeByteArray`.")
        }

    @Throws(IOException::class)
    fun decodeBitmapFromUri(
        contentResolver: ContentResolver,
        imageUri: Uri,
    ): Bitmap =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val source = ImageDecoder.createSource(contentResolver, imageUri)
            decodeWithImageDecoder(source)
        } else {
            checkNotNull(contentResolver.openInputStream(imageUri)) {
                "Input stream is null, the provider might have recently crashed."
            }.use { inputStream ->
                decodeStream(inputStream)
                    ?: throw IOException("The image could not be decoded using the `BitmapFactory.decodeStream`.")
            }
        }

    fun isValidImage(imageBytes: ByteArray): Boolean {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size, bounds)
        return bounds.outWidth > 0 && bounds.outHeight > 0
    }

    private fun decodeByteArray(imageBytes: ByteArray): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size, bounds)
        return BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size, optionsFor(bounds))
    }

    private fun decodeStream(inputStream: InputStream): Bitmap? {
        val bytes = inputStream.readBytesOrEmpty()
        if (bytes.isEmpty()) return null
        return decodeByteArray(bytes)
    }

    private fun decodeWithImageDecoder(source: ImageDecoder.Source): Bitmap =
        ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
            val width = info.size.width
            val height = info.size.height
            val sample = sampleSize(width, height)
            if (sample > 1) {
                decoder.setTargetSize(width / sample, height / sample)
            }
        }

    private fun optionsFor(bounds: BitmapFactory.Options): BitmapFactory.Options =
        BitmapFactory.Options().apply {
            inJustDecodeBounds = false
            inSampleSize = sampleSize(bounds.outWidth, bounds.outHeight)
        }

    private fun sampleSize(width: Int, height: Int): Int {
        var sample = 1
        val largest = maxOf(width, height)
        if (largest <= 0) return 1
        while ((largest / sample) > MAX_EDGE) {
            sample *= 2
        }
        return sample
    }

    private fun InputStream.readBytesOrEmpty(): ByteArray {
        return try {
            val out = ByteArrayOutputStream()
            val buffer = ByteArray(16 * 1024)
            var read: Int
            while (read(buffer).also { read = it } != -1) {
                out.write(buffer, 0, read)
            }
            out.toByteArray()
        } catch (_: IOException) {
            ByteArray(0)
        }
    }
}
