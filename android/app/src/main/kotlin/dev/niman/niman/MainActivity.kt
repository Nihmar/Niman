package dev.niman.niman

import android.app.ActivityManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private val manageStorageRequestCode = 1
    private val shortcuts = ShortcutsBridge(this)
    private val widgets = WidgetBridge(this)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shortcuts.attach(flutterEngine.dartExecutor.binaryMessenger)
        widgets.attach(flutterEngine.dartExecutor.binaryMessenger)
        // Cold start: this runs while Dart is still booting, so the
        // launching intent's action waits until Dart asks for it.
        shortcuts.handleIntent(intent, running = false)
        widgets.handleIntent(intent, running = false)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "niman/storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasManageStorageAccess" ->
                        result.success(Environment.isExternalStorageManager())
                    "requestManageStorageAccess" ->
                        requestAllFilesAccess(result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "niman/reminders")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" ->
                        result.success(isIgnoringBatteryOptimizations())
                    "isBackgroundRestricted" ->
                        result.success(isBackgroundRestricted())
                    "openBatterySettings" ->
                        result.success(openBatterySettings())
                    "openNotificationSettings" ->
                        result.success(openNotificationSettings())
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "niman/update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" ->
                        result.success(installApk(call.argument("path")))
                    else -> result.notImplemented()
                }
            }
    }

    // A shortcut tapped while the app is alive: singleTop delivers it
    // here instead of recreating the activity.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        shortcuts.handleIntent(intent, running = true)
        widgets.handleIntent(intent, running = true)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        shortcuts.detach()
        widgets.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /**
     * Whether the system exempts Niman from battery optimization.
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
     * Whether the system restricts Niman's background activity.
     *
     * Android's "Restricted" battery mode -- shown on several ROMs as an
     * "Allow background activity" switch, off -- stops the app being
     * started in the background at all, a stronger hold than Doze and one
     * an exact alarm cannot override. It is a separate switch from
     * [isIgnoringBatteryOptimizations]: an app can be unrestricted for
     * Doze and still restricted here, which is why both are asked.
     */
    private fun isBackgroundRestricted(): Boolean {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return manager.isBackgroundRestricted
    }

    /**
     * Opens Niman's own battery page, where "Unrestricted" is one tap.
     *
     * Not ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS: that list opens
     * filtered to the apps already exempt, so Niman -- the one app that
     * is not -- is nowhere on it until the user finds the filter. The
     * per-app page is Settings' own VIEW_ADVANCED_POWER_USAGE_DETAIL
     * (exported, not in the SDK constants); a ROM without it falls back
     * to the app's info page, one "Battery" tap away, then to the list.
     *
     * Deliberately not ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS: that
     * one-tap dialog needs the REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
     * permission, which app stores restrict to a narrow set of app
     * categories. Returns false when no activity handles any of them.
     */
    private fun openBatterySettings(): Boolean {
        val pkg = Uri.fromParts("package", packageName, null)
        val batteryPage = Intent("android.settings.VIEW_ADVANCED_POWER_USAGE_DETAIL", pkg)
        val details = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkg)
        return open(batteryPage) || open(details) ||
            open(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
    }

    /**
     * Opens Niman's page in the system notification settings.
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
     * Hands the downloaded update [path] to the system package installer
     * (issue #81).
     *
     * The APK lives in the app support directory, which no other app can
     * read, so it is shared read-only through FileProvider (see
     * file_provider_paths.xml). False when the file is gone, outside the
     * shared folder, or no installer handles the intent — the user still
     * has to confirm the install (and the "unknown apps" allowlist) on
     * the system screen.
     */
    private fun installApk(path: String?): Boolean {
        if (path.isNullOrEmpty()) return false
        val file = File(path)
        if (!file.isFile) return false
        val uri = try {
            FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        } catch (e: IllegalArgumentException) {
            return false
        }
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return open(intent)
    }

    /**
     * Launches the system "All files access" screen and answers [result]
     * with the grant state once the user returns to the app.
     *
     * The permission cannot be requested inline like a runtime permission:
     * the user has to flip it in Settings, so this opens Niman's own page
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
