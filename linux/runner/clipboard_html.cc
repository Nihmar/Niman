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

// The files a file manager copied (#1249): GNOME's file managers write
// x-special/gnome-copied-files (`copy` or `cut`, then a URI a line), KDE's
// and most others text/uri-list. The bytes go to Dart as they came, where
// the list is read (`pathsOfUriList`) and tested.
static const char* const kFileTargets[] = {
    "x-special/gnome-copied-files",
    "text/uri-list",
};

static void files_received(GtkClipboard* clipboard, GtkSelectionData* data,
                           gpointer user_data) {
  FlMethodCall* call = FL_METHOD_CALL(user_data);
  FlValue* bytes = selection_bytes(data);
  if (bytes == nullptr) {
    bytes = fl_value_new_null();
  }
  fl_method_call_respond_success(call, bytes, nullptr);
  fl_value_unref(bytes);
  g_object_unref(call);
}

static void file_targets_received(GtkClipboard* clipboard, GdkAtom* atoms,
                                  gint n_atoms, gpointer user_data) {
  FlMethodCall* call = FL_METHOD_CALL(user_data);
  GdkAtom target = GDK_NONE;
  guint target_rank = G_N_ELEMENTS(kFileTargets);
  for (gint i = 0; atoms != nullptr && i < n_atoms; i++) {
    g_autofree gchar* name = gdk_atom_name(atoms[i]);
    for (guint rank = 0; rank < target_rank; rank++) {
      if (g_strcmp0(name, kFileTargets[rank]) == 0) {
        target = atoms[i];
        target_rank = rank;
        break;
      }
    }
  }
  if (target == GDK_NONE) {
    g_autoptr(FlValue) none = fl_value_new_null();
    fl_method_call_respond_success(call, none, nullptr);
    g_object_unref(call);
    return;
  }
  gtk_clipboard_request_contents(clipboard, target, files_received, call);
}

// A picture on the clipboard with no text beside it (a screenshot, an image
// a browser copied): its PNG, which Dart keeps as a file to attach
// (lib/src/capture/paste/clipboard_picture.dart). With text, the paste is
// the text's: a spreadsheet's cells come with a picture of themselves.
static void image_received(GtkClipboard* clipboard, GdkPixbuf* pixbuf,
                           gpointer user_data) {
  FlMethodCall* call = FL_METHOD_CALL(user_data);
  gchar* buffer = nullptr;
  gsize size = 0;
  g_autoptr(GError) error = nullptr;
  if (pixbuf != nullptr &&
      gdk_pixbuf_save_to_buffer(pixbuf, &buffer, &size, "png", &error,
                                nullptr) &&
      size > 0) {
    g_autoptr(FlValue) png = fl_value_new_uint8_list(
        reinterpret_cast<const uint8_t*>(buffer), size);
    fl_method_call_respond_success(call, png, nullptr);
  } else {
    g_autoptr(FlValue) none = fl_value_new_null();
    fl_method_call_respond_success(call, none, nullptr);
  }
  g_free(buffer);
  g_object_unref(call);
}

static void image_targets_received(GtkClipboard* clipboard, GdkAtom* atoms,
                                   gint n_atoms, gpointer user_data) {
  FlMethodCall* call = FL_METHOD_CALL(user_data);
  // The targets are a list of names: asking them reads no picture, so a
  // text paste is not held up by this.
  if (atoms == nullptr || gtk_targets_include_text(atoms, n_atoms) ||
      !gtk_targets_include_image(atoms, n_atoms, FALSE)) {
    g_autoptr(FlValue) none = fl_value_new_null();
    fl_method_call_respond_success(call, none, nullptr);
    g_object_unref(call);
    return;
  }
  gtk_clipboard_request_image(clipboard, image_received, call);
}

static void clipboard_method_call(FlMethodChannel* channel,
                                  FlMethodCall* call, gpointer user_data) {
  if (strcmp(fl_method_call_get_name(call), "readImage") == 0) {
    gtk_clipboard_request_targets(gtk_clipboard_get(GDK_SELECTION_CLIPBOARD),
                                  image_targets_received,
                                  g_object_ref(call));
    return;
  }
  if (strcmp(fl_method_call_get_name(call), "readFiles") == 0) {
    // Asynchronous, as readHtml is: the call is kept until GTK answers.
    gtk_clipboard_request_targets(gtk_clipboard_get(GDK_SELECTION_CLIPBOARD),
                                  file_targets_received,
                                  g_object_ref(call));
    return;
  }
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
