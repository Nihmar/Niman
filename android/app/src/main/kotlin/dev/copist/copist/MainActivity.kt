package dev.copist.copist

import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private val manageStorageRequestCode = 1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "copist/storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasManageStorageAccess" ->
                        result.success(hasAllFilesAccess())
                    "requestManageStorageAccess" ->
                        requestAllFilesAccess(result)
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Whether the app may read every file on shared storage.
     *
     * On Android 11+ (R) that is the "All files access" permission
     * (MANAGE_EXTERNAL_STORAGE); on older releases there is no such
     * restriction.
     */
    private fun hasAllFilesAccess(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.R ||
            Environment.isExternalStorageManager()
    }

    /**
     * Launches the system "All files access" screen and answers [result]
     * when the user returns to the app.
     *
     * If this activity is destroyed while the settings screen is up (for
     * example process death), [result] is dropped and the Dart future
     * never resolves; a retry re-checks the grant state before launching,
     * so the app recovers on the next tap.
     */
    private fun requestAllFilesAccess(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            result.success(true)
            return
        }
        pendingResult = result
        @Suppress("DEPRECATION")
        startActivityForResult(
            Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION),
            manageStorageRequestCode,
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == manageStorageRequestCode) {
            val result = pendingResult
            pendingResult = null
            result?.success(hasAllFilesAccess())
        }
    }
}
