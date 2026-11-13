package dev.niman.niman

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * A book read aloud (#1276) with the system's text-to-speech engine, the one
 * TalkBack speaks with: `android.speech.tts.TextToSpeech`. Not TalkBack
 * itself, which stays the user's own, on or off.
 *
 * Dart hands over one sentence at a time, the next queued behind it, and
 * hears back when each starts and ends (`started`, `done`, `failed`, by the
 * utterance id it gave). The reading's controls outside the app — the media
 * notification ([ReadAloudService]), the lock screen, a headset — go through
 * a [MediaSession], and come back to Dart as `command`s; so do the system's
 * pauses: audio focus lost to a call or another player (never resumed by
 * itself), and headphones unplugged (`ACTION_AUDIO_BECOMING_NOISY`).
 */
class ReadAloudBridge(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        /** The Dart-facing channel. */
        const val CHANNEL = "niman/read_aloud"

        /** The bridge attached to the running engine, for the service's buttons. */
        @Volatile
        var current: ReadAloudBridge? = null
            private set
    }

    private val main = Handler(Looper.getMainLooper())
    private val audio = context.getSystemService(AudioManager::class.java)
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()
    private var channel: MethodChannel? = null
    private var tts: TextToSpeech? = null
    private var ready = false
    private val waiting = mutableListOf<(TextToSpeech?) -> Unit>()
    private var focus: AudioFocusRequest? = null
    private var session: MediaSession? = null
    private var noisy: BroadcastReceiver? = null

    /** Wires the channel to the Flutter engine. */
    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler(this@ReadAloudBridge)
        }
        current = this
    }

    /** Stops reading and lets the engine go: the activity is going away. */
    fun detach() {
        hide()
        tts?.shutdown()
        tts = null
        ready = false
        channel?.setMethodCallHandler(null)
        channel = null
        if (current === this) current = null
    }

    /** A control outside the app asked for [name]: play, pause, next, previous, stop. */
    fun command(name: String) {
        main.post { channel?.invokeMethod("command", mapOf("name" to name)) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "speak" -> engine { tts ->
                if (tts == null) {
                    result.error("unavailable", "no text-to-speech engine", null)
                    return@engine
                }
                tts.setSpeechRate(ReadAloudVoices.clampRate(call.argument<Double>("rate")))
                choose(tts, call.argument<String>("voice"), call.argument<String>("language"))
                val queue = if (call.argument<Boolean>("flush") == true) {
                    TextToSpeech.QUEUE_FLUSH
                } else {
                    TextToSpeech.QUEUE_ADD
                }
                // Asked again on every start, not only the first: a call
                // took it away, and play after it asks it back.
                if (queue == TextToSpeech.QUEUE_FLUSH) takeFocus()
                val id = call.argument<Int>("id") ?: 0
                tts.speak(call.argument<String>("text") ?: "", queue, null, id.toString())
                result.success(null)
            }
            "stop" -> {
                tts?.stop()
                result.success(null)
            }
            "voices" -> engine { tts -> result.success(voices(tts, call.argument("language"))) }
            "sample" -> engine { tts ->
                if (tts != null) {
                    tts.setSpeechRate(ReadAloudVoices.clampRate(call.argument<Double>("rate")))
                    choose(tts, call.argument<String>("voice"), null)
                    tts.speak(call.argument<String>("text") ?: "", TextToSpeech.QUEUE_FLUSH, null, "sample")
                }
                result.success(null)
            }
            "openSettings" -> {
                openSettings()
                result.success(null)
            }
            "show" -> {
                show(
                    title = call.argument<String>("title") ?: "",
                    chapter = call.argument<String>("chapter") ?: "",
                    playing = call.argument<Boolean>("playing") == true,
                    channelName = call.argument<String>("channel") ?: "",
                    labels = call.argument<Map<String, String>>("labels") ?: emptyMap(),
                )
                result.success(null)
            }
            "hide" -> {
                hide()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Runs [then] with the engine once it is up; with null if it cannot be. */
    private fun engine(then: (TextToSpeech?) -> Unit) {
        val ready = tts
        if (ready != null && this.ready) {
            then(ready)
            return
        }
        waiting.add(then)
        if (tts != null) return
        tts = TextToSpeech(context.applicationContext) { status ->
            main.post {
                val ok = status == TextToSpeech.SUCCESS
                this.ready = ok
                val engine = if (ok) tts else null
                engine?.setAudioAttributes(attributes)
                engine?.setOnUtteranceProgressListener(listener)
                if (!ok) tts = null
                val run = waiting.toList()
                waiting.clear()
                run.forEach { it(engine) }
            }
        }
    }

    private val listener = object : UtteranceProgressListener() {
        override fun onStart(utteranceId: String?) = tell("started", utteranceId)

        override fun onDone(utteranceId: String?) = tell("done", utteranceId)

        @Deprecated("Deprecated in Java")
        override fun onError(utteranceId: String?) = tell("failed", utteranceId)

        override fun onError(utteranceId: String?, errorCode: Int) = tell("failed", utteranceId)
    }

    /** An utterance's news, on the main thread: a sample's is nobody's. */
    private fun tell(method: String, utteranceId: String?) {
        val id = utteranceId?.toIntOrNull() ?: return
        main.post { channel?.invokeMethod(method, mapOf("id" to id)) }
    }

    /** Speaks in [voice] when it is one of the engine's, else in [language]'s default. */
    private fun choose(tts: TextToSpeech, voice: String?, language: String?) {
        val named: Voice? = voice?.let { name -> tts.voices?.firstOrNull { it.name == name } }
        if (named != null) {
            tts.voice = named
        } else {
            tts.language = ReadAloudVoices.localeOf(language)
        }
    }

    private fun voices(tts: TextToSpeech?, language: String?): Map<String, Any> {
        val locale = ReadAloudVoices.localeOf(language)
        val name = locale.getDisplayLanguage(java.util.Locale.getDefault())
        if (tts == null) return mapOf("languageName" to name, "available" to false, "voices" to emptyList<Any>())
        val available = tts.isLanguageAvailable(locale) >= TextToSpeech.LANG_AVAILABLE
        val candidates = (tts.voices ?: emptySet()).map {
            ReadAloudVoices.Candidate(
                name = it.name,
                locale = it.locale,
                network = it.isNetworkConnectionRequired,
                installed = !it.features.contains(TextToSpeech.Engine.KEY_FEATURE_NOT_INSTALLED),
            )
        }
        return mapOf(
            "languageName" to name,
            "available" to available,
            "voices" to ReadAloudVoices.of(candidates, locale).map {
                mapOf("name" to it.name, "network" to it.network)
            },
        )
    }

    private fun openSettings() {
        val settings = Intent("com.android.settings.TTS_SETTINGS")
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(settings)
        } catch (_: android.content.ActivityNotFoundException) {
            context.startActivity(
                Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }

    /** Takes the audio, so another player or a call pauses the reading. */
    private fun takeFocus() {
        val request = focus ?: AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
            .setAudioAttributes(attributes)
            .setWillPauseWhenDucked(true)
            .setOnAudioFocusChangeListener { change ->
                // Lost for good or for a while — a call, another app's
                // audio: pause, and stay paused when it comes back.
                if (change < 0) command("pause")
            }
            .build()
        focus = request
        audio?.requestAudioFocus(request)
        if (noisy == null) {
            val receiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    if (intent.action == AudioManager.ACTION_AUDIO_BECOMING_NOISY) command("pause")
                }
            }
            val filter = IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
            // A system broadcast reaches an unexported receiver too; the flag
            // is Android 13's, and below it a receiver takes no flag.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                context.registerReceiver(receiver, filter)
            }
            noisy = receiver
        }
    }

    private fun show(
        title: String,
        chapter: String,
        playing: Boolean,
        channelName: String,
        labels: Map<String, String>,
    ) {
        val media = session ?: MediaSession(context, "niman-read-aloud").also {
            it.setCallback(object : MediaSession.Callback() {
                override fun onPlay() = command("play")
                override fun onPause() = command("pause")
                override fun onSkipToNext() = command("next")
                override fun onSkipToPrevious() = command("previous")
                override fun onStop() = command("stop")
            })
            session = it
        }
        media.setMetadata(
            MediaMetadata.Builder()
                .putString(MediaMetadata.METADATA_KEY_TITLE, chapter)
                .putString(MediaMetadata.METADATA_KEY_ARTIST, title)
                .putString(MediaMetadata.METADATA_KEY_ALBUM, title)
                .build(),
        )
        media.setPlaybackState(
            PlaybackState.Builder()
                .setActions(
                    PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE or
                        PlaybackState.ACTION_PLAY_PAUSE or PlaybackState.ACTION_SKIP_TO_NEXT or
                        PlaybackState.ACTION_SKIP_TO_PREVIOUS or PlaybackState.ACTION_STOP,
                )
                .setState(
                    if (playing) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED,
                    PlaybackState.PLAYBACK_POSITION_UNKNOWN,
                    1f,
                )
                .build(),
        )
        media.isActive = true
        ReadAloudService.show(context, media.sessionToken, title, chapter, playing, channelName, labels)
    }

    /** Ends the reading outside the app: the notification, the controls, the audio. */
    private fun hide() {
        tts?.stop()
        ReadAloudService.hide(context)
        session?.isActive = false
        session?.release()
        session = null
        focus?.let { audio?.abandonAudioFocusRequest(it) }
        focus = null
        noisy?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
            }
        }
        noisy = null
    }
}
