#include "clipboard_html.h"

#include <cstring>

// Paste as Markdown (#531): GTK is asked for the clipboard's targets, then
// for text/html, then for the page it came from. GTK's clipboard is the
// same call on X11 and on Wayland; what differs is what the browser offers,
// so every target is looked for by name rather than assumed.
//
// The bytes go to Dart as they came: Firefox has written text/html and its
// URL targets as UTF-16, Chromium as UTF-8, and the decoding is Dart's
// (`decodeClipboardText`), where it is tested.

// The targets a browser names the page under: Chromium's own
// (`kMimeTypeSourceUrl`), then Firefox's.
static const char* const kSourceTargets[] = {
    "chromium/x-source-url",
    "text/x-moz-url-priv",
};

// One `readHtml` on its way through GTK's callbacks.
typedef struct {
  FlMethodCall* call;
  GdkAtom source;
  FlValue* result;
} HtmlRead;

// Answers the call with what was read, and lets the request go.
static void html_read_finish(HtmlRead* read, gboolean found) {
  if (found) {
    fl_method_call_respond_success(read->call, read->result, nullptr);
  } else {
    g_autoptr(FlValue) none = fl_value_new_null();
    fl_method_call_respond_success(read->call, none, nullptr);
  }
  g_object_unref(read->call);
  fl_value_unref(read->result);
  g_free(read);
}

// A target's bytes, or null when GTK could not get them.
static FlValue* selection_bytes(GtkSelectionData* data) {
  if (data == nullptr) {
    return nullptr;
  }
  const gint length = gtk_selection_data_get_length(data);
  const guchar* bytes = gtk_selection_data_get_data(data);
  if (length <= 0 || bytes == nullptr) {
    return nullptr;
  }
  return fl_value_new_uint8_list(bytes, length);
}

static void source_received(GtkClipboard* clipboard, GtkSelectionData* data,
                            gpointer user_data) {
  HtmlRead* read = static_cast<HtmlRead*>(user_data);
  FlValue* bytes = selection_bytes(data);
  if (bytes != nullptr) {
    fl_value_set_string_take(read->result, "source", bytes);
  }
  html_read_finish(read, TRUE);
}

static void html_received(GtkClipboard* clipboard, GtkSelectionData* data,
                          gpointer user_data) {
  HtmlRead* read = static_cast<HtmlRead*>(user_data);
  FlValue* bytes = selection_bytes(data);
  if (bytes == nullptr) {
    html_read_finish(read, FALSE);
    return;
  }
  fl_value_set_string_take(read->result, "html", bytes);
  if (read->source == GDK_NONE) {
    html_read_finish(read, TRUE);
    return;
  }
  gtk_clipboard_request_contents(clipboard, read->source, source_received,
                                 read);
}

static void targets_received(GtkClipboard* clipboard, GdkAtom* atoms,
                             gint n_atoms, gpointer user_data) {
  HtmlRead* read = static_cast<HtmlRead*>(user_data);
  GdkAtom html = GDK_NONE;
  guint source_rank = G_N_ELEMENTS(kSourceTargets);
  for (gint i = 0; atoms != nullptr && i < n_atoms; i++) {
    g_autofree gchar* name = gdk_atom_name(atoms[i]);
    if (g_strcmp0(name, "text/html") == 0) {
      html = atoms[i];
    }
    for (guint rank = 0; rank < source_rank; rank++) {
      if (g_strcmp0(name, kSourceTargets[rank]) == 0) {
        read->source = atoms[i];
        source_rank = rank;
        break;
      }
    }
  }
  if (html == GDK_NONE) {
    html_read_finish(read, FALSE);
    return;
  }
  gtk_clipboard_request_contents(clipboard, html, html_received, read);
}

static void clipboard_method_call(FlMethodChannel* channel,
                                  FlMethodCall* call, gpointer user_data) {
  if (strcmp(fl_method_call_get_name(call), "readHtml") != 0) {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  HtmlRead* read = g_new0(HtmlRead, 1);
  read->call = FL_METHOD_CALL(g_object_ref(call));
  read->source = GDK_NONE;
  read->result = fl_value_new_map();
  // Asynchronous all the way: a wait_for call would spin a main loop of
  // its own inside the engine's message handler.
  gtk_clipboard_request_targets(gtk_clipboard_get(GDK_SELECTION_CLIPBOARD),
                                targets_received, read);
}

FlMethodChannel* clipboard_html_channel_new(FlBinaryMessenger* messenger) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      messenger, "niman/clipboard", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, clipboard_method_call,
                                            nullptr, nullptr);
  return channel;
}
