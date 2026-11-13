package dev.niman.niman

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.media.session.MediaSession
import android.os.IBinder

/**
 * What keeps a book read aloud (#1276) going with the screen off and Niman
 * in the background: a foreground service of type `mediaPlayback`, as
 * Android asks of anything that plays, under a media notification — the
 * book's title, the chapter, previous / play or pause / next, stop — which
 * the lock screen shows as its controls too.
 *
 * It only shows: the speaking is [ReadAloudBridge]'s. Its buttons come back
 * here as intents and go to the bridge as commands. Niman swiped away ends
 * the reading with it.
 */
class ReadAloudService : Service() {
    companion object {
        private const val CHANNEL_ID = "read_aloud"
        private const val NOTIFICATION_ID = 0x7EAD
        private const val ACTION_SHOW = "dev.niman.niman.read_aloud.SHOW"
        private const val ACTION_COMMAND = "dev.niman.niman.read_aloud.COMMAND"
        private const val EXTRA_COMMAND = "command"

        /** The notification's content; the service reads it as it starts. */
        private var token: MediaSession.Token? = null
        private var title = ""
        private var chapter = ""
        private var playing = false
        private var channelName = ""
        private var labels: Map<String, String> = emptyMap()

        @Volatile
        private var running: ReadAloudService? = null

        /** Shows the reading, or updates what it shows. */
        fun show(
            context: Context,
            token: MediaSession.Token,
            title: String,
            chapter: String,
            playing: Boolean,
            channelName: String,
            labels: Map<String, String>,
        ) {
            this.labels = labels
            this.token = token
            this.title = title
            this.chapter = chapter
            this.playing = playing
            this.channelName = channelName
            val service = running
            if (service != null) {
                service.post()
            } else {
                context.startForegroundService(
                    Intent(context, ReadAloudService::class.java).setAction(ACTION_SHOW),
                )
            }
        }

        /** Takes the notification away and ends the service. */
        fun hide(context: Context) {
            token = null
            if (running != null) context.stopService(Intent(context, ReadAloudService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        running = this
        if (intent?.action == ACTION_COMMAND) {
            intent.getStringExtra(EXTRA_COMMAND)?.let { ReadAloudBridge.current?.command(it) }
        }
        if (token == null) {
            // Started for a reading that has ended since: nothing to show.
            startForeground(NOTIFICATION_ID, build(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            stopSelf()
            return START_NOT_STICKY
        }
        startForeground(NOTIFICATION_ID, build(), ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        return START_NOT_STICKY
    }

    /** Swiped away from Recents: the reading goes with Niman. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        ReadAloudBridge.current?.command("stop")
        stopSelf()
    }

    override fun onDestroy() {
        if (running === this) running = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    /** Puts the notification up again with what it shows now. */
    fun post() {
        getSystemService(NotificationManager::class.java)?.notify(NOTIFICATION_ID, build())
    }

    private fun build(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (manager?.getNotificationChannel(CHANNEL_ID) == null) {
            manager?.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    channelName.ifEmpty { "Reading aloud" },
                    NotificationManager.IMPORTANCE_LOW,
                ).apply { setShowBadge(false) },
            )
        }
        val open = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_IMMUTABLE)
        }
        val style = Notification.MediaStyle().setShowActionsInCompactView(0, 1, 2)
        token?.let(style::setMediaSession)
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_niman)
            .setContentTitle(chapter)
            .setContentText(title)
            .setContentIntent(open)
            .setOngoing(playing)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_TRANSPORT)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setStyle(style)
            .addAction(action("previous", android.R.drawable.ic_media_previous, "Previous"))
            .addAction(
                if (playing) {
                    action("pause", android.R.drawable.ic_media_pause, "Pause")
                } else {
                    action("play", android.R.drawable.ic_media_play, "Play")
                },
            )
            .addAction(action("next", android.R.drawable.ic_media_next, "Next"))
            .addAction(action("stop", android.R.drawable.ic_menu_close_clear_cancel, "Stop"))
            .build()
    }

    private fun action(command: String, icon: Int, fallback: String): Notification.Action {
        val label = labels[command] ?: fallback
        val intent = Intent(this, ReadAloudService::class.java)
            .setAction(ACTION_COMMAND)
            .putExtra(EXTRA_COMMAND, command)
        val pending = PendingIntent.getService(
            this,
            command.hashCode(),
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return Notification.Action.Builder(Icon.createWithResource(this, icon), label, pending).build()
    }
}
