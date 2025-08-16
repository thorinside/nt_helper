#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#define USB_VIDEO_CAPTURE_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), usb_video_capture_plugin_get_type(), \
                               UsbVideoCapturePlugin))

struct _UsbVideoCapturePlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(UsbVideoCapturePlugin, usb_video_capture_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void usb_video_capture_plugin_handle_method_call(
    UsbVideoCapturePlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "isSupported") == 0) {
    // Linux USB video capture is not implemented in this stub
    g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "listUsbCameras") == 0) {
    // Return empty list for stub implementation
    g_autoptr(FlValue) result = fl_value_new_list();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void usb_video_capture_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(usb_video_capture_plugin_parent_class)->dispose(object);
}

static void usb_video_capture_plugin_class_init(UsbVideoCapturePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = usb_video_capture_plugin_dispose;
}

static void usb_video_capture_plugin_init(UsbVideoCapturePlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  UsbVideoCapturePlugin* plugin = USB_VIDEO_CAPTURE_PLUGIN(user_data);
  usb_video_capture_plugin_handle_method_call(plugin, method_call);
}

void usb_video_capture_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  UsbVideoCapturePlugin* plugin = USB_VIDEO_CAPTURE_PLUGIN(
      g_object_new(usb_video_capture_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "com.example.nt_helper/usb_video",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}