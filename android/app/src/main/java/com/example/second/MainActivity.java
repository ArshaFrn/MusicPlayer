package com.example.second;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;

import java.io.OutputStream;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterFragmentActivity {

    private static final String CHANNEL = "hertz/media_store";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((MethodCall call, MethodChannel.Result result) -> {
                    if ("saveAudioToPublic".equals(call.method)) {
                        try {
                            String fileName = call.argument("fileName");
                            String mimeType = call.argument("mimeType");
                            byte[] bytes = call.argument("bytes");

                            if (fileName == null || bytes == null || bytes.length == 0) {
                                result.error("invalid_args", "Missing fileName/bytes", null);
                                return;
                            }

                            ContentResolver resolver = getContentResolver();
                            ContentValues values = new ContentValues();
                            values.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
                            if (mimeType != null) {
                                values.put(MediaStore.MediaColumns.MIME_TYPE, mimeType);
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_MUSIC + "/Hertz");
                            }

                            Uri collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
                            Uri item = resolver.insert(collection, values);
                            if (item == null) {
                                result.error("insert_failed", "Resolver.insert returned null", null);
                                return;
                            }

                            try (OutputStream out = resolver.openOutputStream(item)) {
                                if (out == null) {
                                    result.error("stream_null", "openOutputStream returned null", null);
                                    return;
                                }
                                out.write(bytes);
                                out.flush();
                            }

                            result.success(item.toString());
                        } catch (Exception e) {
                            Log.e("MainActivity", "Error saving audio", e);
                            result.error("exception", e.getMessage(), null);
                        }
                    } else {
                        result.notImplemented();
                    }
                });
    }
}
