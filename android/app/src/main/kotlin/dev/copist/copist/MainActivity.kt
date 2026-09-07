package dev.copist.copist

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
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
                        result.success(Environment.isExternalStorageManager())
                    "requestManageStorageAccess" ->
                        requestAllFilesAccess(result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "copist/reminders")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" ->
                        result.success(isIgnoringBatteryOptimizations())
                    "openBatterySettings" ->
                        result.success(openBatterySettings())
                    "openNotificationSettings" ->
                        result.success(openNotificationSettings())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Whether the system exempts Copist from battery optimization.
     *
     * Task reminders are AlarmManager alarms, which the system keeps and
     * fires with the process dead. An optimized app can still be put to
     * sleep by an OEM battery manager, and several ROMs drop its pending
     * alarms outright when it is swiped away from recents -- so a
     * reminder set for tomorrow silently never arrives.
     */
    private fun isIgnoringBatteryOptimizations(): Boolean {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    /**
     * Opens the system list of battery-optimized apps.
     *
     * Deliberately not ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS: that
     * one-tap dialog needs the REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
     * permission, which app stores restrict to a narrow set of app
     * categories. The list needs no permission; the user picks Copist and
     * flips it. Returns false when no activity handles the intent.
     */
    private fun openBatterySettings(): Boolean {
        return open(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
    }

    /**
     * Opens Copist's page in the system notification settings.
     *
     * Once POST_NOTIFICATIONS has been denied twice, Android stops
     * showing the runtime dialog, so this screen is the only way back.
     */
    private fun openNotificationSettings(): Boolean {
        val appPage = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        val details = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null),
        )
        return open(appPage) || open(details)
    }

    /** Starts [intent]; false when no activity handles it. */
    private fun open(intent: Intent): Boolean {
        return try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    /**
     * Launches the system "All files access" screen and answers [result]
     * with the grant state once the user returns to the app.
     *
     * The permission cannot be requested inline like a runtime permission:
     * the user has to flip it in Settings, so this opens Copist's own page
     * there (falling back to the app list on devices that do not offer the
     * per-app screen).
     *
     * If this activity is destroyed while Settings is up, [result] is
     * dropped and the Dart future never resolves; a retry re-checks the
     * grant state first, so the app recovers on the next tap.
     *
     * minSdk is 35, so the permission always exists — no version gate.
     */
    private fun requestAllFilesAccess(result: MethodChannel.Result) {
        if (Environment.isExternalStorageManager()) {
            result.success(true)
            return
        }
        if (pendingResult != null) {
            // A request is already in flight; do not clobber its result.
            result.success(false)
            return
        }
        pendingResult = result
        val appPage = Intent(
            Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
            Uri.fromParts("package", packageName, null),
        )
        val appList = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
        if (!launchSettings(appPage) && !launchSettings(appList)) {
            pendingResult = null
            result.success(false)
        }
    }

    /** Starts [intent] for result; false when no activity handles it. */
    @Suppress("DEPRECATION")
    private fun launchSettings(intent: Intent): Boolean {
        return try {
            startActivityForResult(intent, manageStorageRequestCode)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    // startActivityForResult/onActivityResult rather than an AndroidX
    // result launcher: FlutterActivity extends the platform Activity, not
    // a ComponentActivity, so registerForActivityResult is unavailable.
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == manageStorageRequestCode) {
            val result = pendingResult
            pendingResult = null
            // The Settings screen reports no result of its own; the grant
            // state after the user comes back is the answer.
            result?.success(Environment.isExternalStorageManager())
        }
    }
}
