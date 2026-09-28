#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  // The window's drop target (#224): GDK reads the drop here, Dart opens
  // or imports what it names.
  FlMethodChannel* drop_channel;
  gboolean drag_over;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Tells Dart what the window's drop target sees.
static void drop_send(MyApplication* self, const gchar* method, FlValue* args) {
  if (self->drop_channel == nullptr) {
    return;
  }
  fl_method_channel_invoke_method(self->drop_channel, method, args, nullptr,
                                  nullptr, nullptr);
}

// Something is being dragged over the window: the frame Dart draws says a
// drop would be taken.
static gboolean drop_drag_motion(GtkWidget* widget, GdkDragContext* context,
                                 gint x, gint y, guint time,
                                 gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (!self->drag_over) {
    self->drag_over = TRUE;
    drop_send(self, "dragEntered", nullptr);
  }
  // The default handler answers the drag (GTK_DEST_DEFAULT_MOTION), which
  // is what keeps the window a drop destination at all.
  return FALSE;
}

// The drag left the window, or landed on it.
static void drop_drag_leave(GtkWidget* widget, GdkDragContext* context,
                            guint time, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (!self->drag_over) {
    return;
  }
  self->drag_over = FALSE;
  drop_send(self, "dragExited", nullptr);
}

// The drop's own data: the file URIs it carries, one path each.
//
// Only text/uri-list is asked for (see where the target is set up): the
// portal file-transfer target KDE offers beside it holds a one-time key
// instead of URIs, and a key nothing resolves is what made a drop on
// Wayland look like no drop at all (#224). A URI that is not a file this
// process can read — another host's, or a key that arrived anyway — is
// named in the log and left out of what Dart is handed.
static void drop_data_received(GtkWidget* widget, GdkDragContext* context,
                               gint x, gint y, GtkSelectionData* data,
                               guint info, guint time, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  self->drag_over = FALSE;

  g_autoptr(FlValue) paths = fl_value_new_list();
  g_auto(GStrv) uris = gtk_selection_data_get_uris(data);
  for (gint i = 0; uris != nullptr && uris[i] != nullptr; i++) {
    g_autoptr(GFile) file = g_file_new_for_uri(uris[i]);
    g_autofree gchar* path = g_file_get_path(file);
    if (path != nullptr) {
      fl_value_append_take(paths, fl_value_new_string(path));
    } else {
      g_warning("drop: %s is not a local file", uris[i]);
    }
  }
  if (fl_value_get_length(paths) == 0) {
    g_autofree gchar* text = reinterpret_cast<gchar*>(
        gtk_selection_data_get_text(data));
    g_warning("drop: nothing openable in the drop (%s)",
              text != nullptr ? text : "no data");
  }
  drop_send(self, "drop", paths);
  // No gtk_drag_finish() here: the destination's defaults
  // (GTK_DEST_DEFAULT_ALL, where the target is set up) include the drop, so
  // GTK answers the source itself once this handler has returned and the
  // data has been taken. A second finish would answer it twice.
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Niman");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Niman");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Files and folders dropped on the window (#224): the window is the
  // drop destination, and the paths it takes are handed to Dart over
  // niman/drop.
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->drop_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)), "niman/drop",
      FL_METHOD_CODEC(codec));
  // text/uri-list (and what GDK accepts beside it), never the portal
  // file-transfer target: that one carries a key this runner does not
  // resolve, and taking it is what left a drop on KDE/Wayland with
  // nothing to open (#224).
  gtk_drag_dest_set(GTK_WIDGET(view), GTK_DEST_DEFAULT_ALL, nullptr, 0,
                    GDK_ACTION_COPY);
  gtk_drag_dest_add_uri_targets(GTK_WIDGET(view));
  g_signal_connect(view, "drag-motion", G_CALLBACK(drop_drag_motion), self);
  g_signal_connect(view, "drag-leave", G_CALLBACK(drop_drag_leave), self);
  g_signal_connect(view, "drag-data-received", G_CALLBACK(drop_data_received),
                   self);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  if (self->drop_channel != nullptr) {
    g_object_unref(self->drop_channel);
    self->drop_channel = nullptr;
  }
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
