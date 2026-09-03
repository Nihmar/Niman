package dev.copist.copist

import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "copist/storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeTreeGrant" ->
                        result.success(takeTreeGrant(call.argument<String>("uri")))
                    else -> result.notImplemented()
                }
            }
    }

    // Takes the persistent read+write SAF grant on a tree URI right
    // after the pick, while the transient grant from the picker result
    // is still held by this activity. Returns false on failure.
    private fun takeTreeGrant(uri: String?): Boolean {
        if (uri == null) return false
        return try {
            contentResolver.takePersistableUriPermission(
                Uri.parse(uri),
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            true
        } catch (e: SecurityException) {
            Log.w("copist/storage", "takeTreeGrant failed for $uri", e)
            false
        }
    }
}
