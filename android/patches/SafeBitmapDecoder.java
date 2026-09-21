package com.farenidham.books.saxatsavita.bitmap;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

/**
 * Decodes bitmaps with {@link BitmapFactory.Options#inSampleSize} so Play Console
 * no longer flags full-resolution {@link BitmapFactory} loads.
 */
public final class SafeBitmapDecoder {
  public static final int MAX_EDGE = 2048;

  private SafeBitmapDecoder() {}

  public static Bitmap decodeFile(String path) {
    BitmapFactory.Options bounds = new BitmapFactory.Options();
    bounds.inJustDecodeBounds = true;
    BitmapFactory.decodeFile(path, bounds);
    return BitmapFactory.decodeFile(path, optionsFor(bounds.outWidth, bounds.outHeight));
  }

  public static Bitmap decodeResource(Resources res, int id) {
    BitmapFactory.Options bounds = new BitmapFactory.Options();
    bounds.inJustDecodeBounds = true;
    BitmapFactory.decodeResource(res, id, bounds);
    return BitmapFactory.decodeResource(res, id, optionsFor(bounds.outWidth, bounds.outHeight));
  }

  public static Bitmap decodeByteArray(byte[] data, int offset, int length) {
    BitmapFactory.Options bounds = new BitmapFactory.Options();
    bounds.inJustDecodeBounds = true;
    BitmapFactory.decodeByteArray(data, offset, length, bounds);
    return BitmapFactory.decodeByteArray(
        data, offset, length, optionsFor(bounds.outWidth, bounds.outHeight));
  }

  public static Bitmap decodeStream(InputStream stream) {
    byte[] data = readAll(stream);
    if (data.length == 0) {
      return null;
    }
    return decodeByteArray(data, 0, data.length);
  }

  public static boolean canDecode(byte[] data) {
    if (data == null || data.length == 0) {
      return false;
    }
    BitmapFactory.Options bounds = new BitmapFactory.Options();
    bounds.inJustDecodeBounds = true;
    BitmapFactory.decodeByteArray(data, 0, data.length, bounds);
    return bounds.outWidth > 0 && bounds.outHeight > 0;
  }

  public static BitmapFactory.Options optionsFor(int width, int height) {
    BitmapFactory.Options options = new BitmapFactory.Options();
    options.inJustDecodeBounds = false;
    options.inSampleSize = sampleSize(width, height, MAX_EDGE);
    return options;
  }

  public static int sampleSize(int width, int height, int maxEdge) {
    int sample = 1;
    int largest = Math.max(width, height);
    if (largest <= 0 || maxEdge <= 0) {
      return 1;
    }
    while ((largest / sample) > maxEdge) {
      sample *= 2;
    }
    return sample;
  }

  private static byte[] readAll(InputStream stream) {
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    byte[] buffer = new byte[16 * 1024];
    try {
      int read;
      while ((read = stream.read(buffer)) != -1) {
        out.write(buffer, 0, read);
      }
    } catch (IOException ignored) {
      return new byte[0];
    }
    return out.toByteArray();
  }
}
