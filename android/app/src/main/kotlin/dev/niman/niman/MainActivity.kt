package dev.niman.niman

import android.app.ActivityManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.view.WindowManager
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private companion object {
        /** The saved-state key that says the launching intent is done. */
        const val STATE_LAUNCH_HANDLED = "niman.launchHandled"
    }

    private var pendingResult: MethodChannel.Result? = null
    private val manageStorageRequestCode = 1
    private val shortcuts = ShortcutsBridge(this)
    private val widgets = WidgetBridge(this)
    private val pdf = PdfBridge(this)
    private val pageReader = PageReaderBridge(this)
    private val shares = ShareBridge(this)
    private val clipboard = ClipboardBridge(this)
    private val openFile = OpenFileBridge(this)

    /** The launching intent, handled once (#721). */
    private val launch = LaunchIntent()

    override fun onCreate(savedInstanceState: Bundle?) {
        // Before super.onCreate: that is what brings the engine up, and
        // with it configureFlutterEngine (#721).
        launch.restore(savedInstanceState?.getBoolean(STATE_LAUNCH_HANDLED) == true)
        super.onCreate(savedInstanceState)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean(STATE_LAUNCH_HANDLED, launch.handled())
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shortcuts.attach(flutterEngine.dartExecutor.binaryMessenger)
        widgets.attach(flutterEngine.dartExecutor.binaryMessenger)
        pdf.attach(flutterEngine.dartExecutor.binaryMessenger)
        pageReader.attach(flutterEngine.dartExecutor.binaryMessenger)
        shares.attach(flutterEngine.dartExecutor.binaryMessenger)
        clipboard.attach(flutterEngine.dartExecutor.binaryMessenger)
        openFile.attach(flutterEngine.dartExecutor.binaryMessenger)
        // Cold start: this runs while Dart is still booting, so the
        // launching intent's action waits until Dart asks for it.
        //
        // Handled once (#721): Android hands the same intent back when it
        // rebuilds the activity or relaunches it from Recents, and the
        // share or widget tap that started the app must not run again.
        // The intent is cleared where it is consumed, so nothing that
        // reads it later sees it either. A delivery to a live activity
        // arrives through onNewIntent.
        //
        // Only Niman's own launch is cleared (#756). A launch that is not
        // a share, shortcut or widget tap belongs to another component:
        // a reminder's tap is flutter_local_notifications' intent, and
        // the plugin reads it from the activity only when Dart asks for
        // the launch details, well after this runs — so clearing it here
        // lost the reminder's note on a cold start. A launch already
        // handled is cleared whoever it belongs to, so a rebuilt activity
        // does not reopen the reminder's note either.
        val history = Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY
        val fromHistory = ((intent?.flags ?: 0) and history) != 0
        if (launch.take(fromHistory)) {
            val shortcut = shortcuts.handleIntent(intent, running = false)
            val widget = widgets.handleIntent(intent, running = false)
            val share = shares.handleIntent(intent, running = false)
            if (shortcut || widget || share) setIntent(Intent())
        } else {
            setIntent(Intent())
        }
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
                    "openAppSettings" ->
                        result.success(openAppSettings())
                    else -> result.notImplemented()
                }
            }
        // Web capture (#531): Save on a page shared from the browser sends
        // the user back to it, the activity kept (and with it the engine
        // the capture runs in) rather than finished.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "niman/task")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "moveToBack" -> result.success(moveTaskToBack(true))
                    // The `shortService` foreground type is Android 14's.
                    "supportsShortService" ->
                        result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
                    else -> result.notImplemented()
                }
            }
        // Presenting slides (#534): the screen stays on until the talk ends.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "niman/screen")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "keepOn" -> {
                        val flag = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                        if (call.arguments == true) window.addFlags(flag)
                        else window.clearFlags(flag)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "niman/update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" ->
                        result.success(installApk(call.argument("path")))
                    // Whether Android lets Niman install a package (#900):
                    // "Install unknown apps", per app since Android 8.
                    "canInstallPackages" ->
                        result.success(packageManager.canRequestPackageInstalls())
                    "openInstallPermission" -> result.success(
                        open(
                            Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName"),
                            ),
                        ),
                    )
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
        shares.handleIntent(intent, running = true)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        shortcuts.detach()
        widgets.detach()
        pdf.detach()
        pageReader.detach()
        shares.detach()
        clipboard.detach()
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
     * Opens Niman's page in the system app settings.
     *
     * The general App info screen, not a sub-page. It holds the
     * notification switch, the battery usage row and the permissions in one
     * place, and it is the same screen on every ROM. The battery and
     * notification sub-pages resolve differently -- and on some ROMs both to
     * this very screen -- which is what made "Open settings" land somewhere
     * the warning was not about. Returns false when no activity handles it.
     */
    private fun openAppSettings(): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", packageName, null),
        )
        return open(intent)
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
     * minSdk is 30 (the permission is API 30), so it always exists — no version gate.
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
