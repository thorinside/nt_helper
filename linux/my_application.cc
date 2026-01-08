#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

// Declare the USB video capture plugin registration function
extern "C" {
  void usb_video_capture_plugin_register_with_registrar(FlPluginRegistrar* registrar);
}

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlView* view;
  GtkWindow* window;
  FlMethodChannel* window_events_channel;
  gboolean shutdown_in_progress;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Forward declaration
static void on_window_events_response(GObject* object, GAsyncResult* result, gpointer user_data);

// Handle window close request (delete-event)
static gboolean on_window_delete_event(GtkWidget* widget, GdkEvent* event, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);

  // Prevent re-entrancy during shutdown
  if (self->shutdown_in_progress) {
    return FALSE;  // Allow close to proceed
  }

  self->shutdown_in_progress = TRUE;

  // Notify Dart side about imminent close
  if (self->window_events_channel != nullptr) {
    fl_method_channel_invoke_method(
        self->window_events_channel,
        "windowWillClose",
        nullptr,
        nullptr,
        on_window_events_response,
        self);
  }

  return FALSE;  // Allow close to proceed
}

// Handle window destroy - runs when widget is being destroyed
static void on_window_destroy(GtkWidget* widget, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);

  // Clear the method channel immediately to prevent use after engine shutdown
  g_clear_object(&self->window_events_channel);

  // Clear view reference
  self->view = nullptr;
  self->window = nullptr;
}

// Suppress known harmless shutdown warnings from Flutter embedder
static GLogWriterOutput shutdown_log_writer(GLogLevelFlags log_level,
                                            const GLogField* fields,
                                            gsize n_fields,
                                            gpointer user_data) {
  // Check if this is a warning/critical we want to suppress during shutdown
  for (gsize i = 0; i < n_fields; i++) {
    if (g_strcmp0(fields[i].key, "MESSAGE") == 0) {
      const gchar* message = (const gchar*)fields[i].value;
      // Suppress known harmless Flutter shutdown warnings
      if (g_strstr_len(message, -1, "FlBinaryMessenger without an engine") != nullptr ||
          g_strstr_len(message, -1, "invalid unclassed pointer in cast to 'FlView'") != nullptr ||
          g_strstr_len(message, -1, "gtk_widget_queue_draw: assertion") != nullptr ||
          g_strstr_len(message, -1, "invalid unclassed pointer in cast to 'GtkWidget'") != nullptr ||
          g_strstr_len(message, -1, "Failed to cleanup compositor shaders") != nullptr) {
        return G_LOG_WRITER_HANDLED;  // Suppress this message
      }
    }
  }
  // Use default writer for everything else
  return g_log_writer_default(log_level, fields, n_fields, user_data);
}

// Response callback (can be used for cleanup confirmation if needed)
static void on_window_events_response(GObject* object, GAsyncResult* result, gpointer user_data) {
  g_autoptr(GError) error = nullptr;
  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(
      FL_METHOD_CHANNEL(object), result, &error);

  // Ignore errors during shutdown - they're expected
  (void)response;
  (void)error;
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  self->shutdown_in_progress = FALSE;

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  self->window = window;

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
    gtk_header_bar_set_title(header_bar, "nt_helper");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "nt_helper");
  }

  // Use gtk_widget_realize instead of gtk_widget_show to hide window on startup.
  // window_manager will show the window when Flutter is ready.
  gtk_widget_realize(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  self->view = view;
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Set up window events channel to notify Dart of window close
  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->window_events_channel = fl_method_channel_new(
      messenger,
      "com.nt_helper.app/window_events",
      FL_METHOD_CODEC(codec));

  // Connect to window close event
  g_signal_connect(window, "delete-event", G_CALLBACK(on_window_delete_event), self);
  // Connect to destroy signal to clean up before Flutter engine shuts down
  g_signal_connect(window, "destroy", G_CALLBACK(on_window_destroy), self);

  // Register the USB video capture plugin
  g_autoptr(FlPluginRegistrar) usb_video_registrar =
      fl_plugin_registry_get_registrar_for_plugin(FL_PLUGIN_REGISTRY(view), "UsbVideoCapturePlugin");
  usb_video_capture_plugin_register_with_registrar(usb_video_registrar);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
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

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);

  // Clear the method channel before engine shutdown
  g_clear_object(&self->window_events_channel);

  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {
  self->view = nullptr;
  self->window = nullptr;
  self->window_events_channel = nullptr;
  self->shutdown_in_progress = FALSE;

  // Install custom log writer to suppress harmless Flutter shutdown warnings
  g_log_set_writer_func(shutdown_log_writer, nullptr, nullptr);
}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
