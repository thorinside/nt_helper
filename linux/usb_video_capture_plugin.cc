#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <linux/videodev2.h>
#include <dirent.h>
#include <string.h>
#include <errno.h>
#include <thread>
#include <atomic>
#include <vector>
#include <string>
#include <mutex>
#include <queue>

#define USB_VIDEO_CAPTURE_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), usb_video_capture_plugin_get_type(), \
                               UsbVideoCapturePlugin))

struct Buffer {
  void* start;
  size_t length;
};

typedef struct _UsbVideoCapturePlugin UsbVideoCapturePlugin;
typedef struct _UsbVideoCapturePluginClass UsbVideoCapturePluginClass;

struct _UsbVideoCapturePlugin {
  GObject parent_instance;

  FlEventChannel* event_channel;
  FlEventChannel* debug_channel;
  std::atomic<bool> stream_active;

  int fd;
  struct Buffer* buffers;
  unsigned int n_buffers;
  std::thread* capture_thread;
  std::atomic<bool> capturing;

  std::mutex* frame_queue_mutex;
  std::queue<std::vector<uint8_t>>* pending_frames;
  guint idle_source_id;
};

struct _UsbVideoCapturePluginClass {
  GObjectClass parent_class;
};

G_DEFINE_TYPE(UsbVideoCapturePlugin, usb_video_capture_plugin, G_TYPE_OBJECT)

// Forward declaration
static void stop_capture(UsbVideoCapturePlugin* self);

// Callback to send frames from the main GTK thread
static gboolean send_pending_frames(gpointer user_data) {
  UsbVideoCapturePlugin* self = USB_VIDEO_CAPTURE_PLUGIN(user_data);

  if (!self->event_channel || !self->stream_active) {
    return G_SOURCE_CONTINUE;  // Keep the idle source active
  }

  std::vector<uint8_t> frame;
  {
    std::lock_guard<std::mutex> lock(*self->frame_queue_mutex);
    if (self->pending_frames->empty()) {
      return G_SOURCE_CONTINUE;
    }
    frame = std::move(self->pending_frames->front());
    self->pending_frames->pop();
    // Clear any backlog to prevent memory buildup - keep only latest frame
    while (!self->pending_frames->empty()) {
      self->pending_frames->pop();
    }
  }

  if (!frame.empty()) {
    g_autoptr(FlValue) frame_data = fl_value_new_uint8_list(frame.data(), frame.size());
    GError* error = nullptr;
    if (!fl_event_channel_send(self->event_channel, frame_data, nullptr, &error)) {
      if (error) {
        g_warning("[USB Video] Failed to send frame: %s", error->message);
        g_error_free(error);
      }
    }
  }

  return G_SOURCE_CONTINUE;  // Keep the idle source active
}

static FlMethodErrorResponse* event_channel_listen(FlEventChannel* channel,
                                                   FlValue* args,
                                                   gpointer user_data) {
  UsbVideoCapturePlugin* self = USB_VIDEO_CAPTURE_PLUGIN(user_data);
  g_print("[USB Video] Event channel listen called\n");
  self->stream_active = true;  // Mark stream as active
  return nullptr;
}

static FlMethodErrorResponse* event_channel_cancel(FlEventChannel* channel,
                                                   FlValue* args,
                                                   gpointer user_data) {
  UsbVideoCapturePlugin* self = USB_VIDEO_CAPTURE_PLUGIN(user_data);
  g_print("[USB Video] Event channel cancel called\n");
  self->stream_active = false;  // Mark stream as inactive
  stop_capture(self);
  return nullptr;
}

static void stop_capture(UsbVideoCapturePlugin* self) {
  if (self->capturing) {
    self->capturing = false;
    if (self->capture_thread) {
      self->capture_thread->join();
      delete self->capture_thread;
      self->capture_thread = nullptr;
    }
  }
  
  if (self->fd >= 0) {
    // Stop streaming
    enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    ioctl(self->fd, VIDIOC_STREAMOFF, &type);
    
    // Unmap buffers
    if (self->buffers) {
      for (unsigned int i = 0; i < self->n_buffers; ++i) {
        munmap(self->buffers[i].start, self->buffers[i].length);
      }
      free(self->buffers);
      self->buffers = nullptr;
    }
    
    close(self->fd);
    self->fd = -1;
  }
}

// Simple BMP encoder for 256x64 RGB images
static std::vector<uint8_t> encode_bmp(const uint8_t* rgb_data, int width, int height) {
  // BMP header size
  const int header_size = 54;
  const int row_size = ((width * 3 + 3) / 4) * 4;  // Rows are padded to 4 bytes
  const int data_size = row_size * height;
  const int file_size = header_size + data_size;
  
  std::vector<uint8_t> bmp(file_size);
  
  // BMP Header
  bmp[0] = 'B'; bmp[1] = 'M';
  // File size
  bmp[2] = file_size & 0xFF;
  bmp[3] = (file_size >> 8) & 0xFF;
  bmp[4] = (file_size >> 16) & 0xFF;
  bmp[5] = (file_size >> 24) & 0xFF;
  // Reserved
  bmp[6] = 0; bmp[7] = 0; bmp[8] = 0; bmp[9] = 0;
  // Offset to pixel data
  bmp[10] = header_size; bmp[11] = 0; bmp[12] = 0; bmp[13] = 0;
  
  // DIB Header
  bmp[14] = 40; bmp[15] = 0; bmp[16] = 0; bmp[17] = 0;  // Header size
  // Width
  bmp[18] = width & 0xFF;
  bmp[19] = (width >> 8) & 0xFF;
  bmp[20] = (width >> 16) & 0xFF;
  bmp[21] = (width >> 24) & 0xFF;
  // Height (negative for top-down)
  int neg_height = -height;
  bmp[22] = neg_height & 0xFF;
  bmp[23] = (neg_height >> 8) & 0xFF;
  bmp[24] = (neg_height >> 16) & 0xFF;
  bmp[25] = (neg_height >> 24) & 0xFF;
  // Planes
  bmp[26] = 1; bmp[27] = 0;
  // Bits per pixel
  bmp[28] = 24; bmp[29] = 0;
  // Compression (none)
  for (int i = 30; i < 54; i++) bmp[i] = 0;
  
  // Copy pixel data (BMP uses BGR order)
  int bmp_idx = header_size;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int rgb_idx = (y * width + x) * 3;
      bmp[bmp_idx++] = rgb_data[rgb_idx + 2];  // B
      bmp[bmp_idx++] = rgb_data[rgb_idx + 1];  // G
      bmp[bmp_idx++] = rgb_data[rgb_idx];      // R
    }
    // Padding
    while (bmp_idx % 4 != header_size % 4) {
      bmp[bmp_idx++] = 0;
    }
  }
  
  return bmp;
}

static void capture_frames(UsbVideoCapturePlugin* self) {
  struct v4l2_buffer buf;
  int frame_count = 0;
  
  g_print("[USB Video] Capture thread running\n");
  
  while (self->capturing) {
    memset(&buf, 0, sizeof(buf));
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    
    // Dequeue buffer
    if (ioctl(self->fd, VIDIOC_DQBUF, &buf) == -1) {
      if (errno == EAGAIN) {
        usleep(10000); // 10ms
        continue;
      }
      g_warning("Failed to dequeue buffer: %s", strerror(errno));
      break;
    }
    
    // Convert YUYV to RGB
    unsigned char* yuyv = (unsigned char*)self->buffers[buf.index].start;
    size_t yuyv_size = buf.bytesused;
    size_t rgb_size = (yuyv_size / 2) * 3; // YUYV is 2 bytes per pixel, RGB is 3
    
    std::vector<uint8_t> rgb_data(rgb_size);
    
    // Simple YUYV to RGB conversion
    for (size_t i = 0, j = 0; i < yuyv_size; i += 4, j += 6) {
      int y0 = yuyv[i];
      int u = yuyv[i + 1];
      int y1 = yuyv[i + 2];
      int v = yuyv[i + 3];
      
      int c = y0 - 16;
      int d = u - 128;
      int e = v - 128;
      
      rgb_data[j] = std::min(255, std::max(0, (298 * c + 409 * e + 128) >> 8));
      rgb_data[j + 1] = std::min(255, std::max(0, (298 * c - 100 * d - 208 * e + 128) >> 8));
      rgb_data[j + 2] = std::min(255, std::max(0, (298 * c + 516 * d + 128) >> 8));
      
      c = y1 - 16;
      rgb_data[j + 3] = std::min(255, std::max(0, (298 * c + 409 * e + 128) >> 8));
      rgb_data[j + 4] = std::min(255, std::max(0, (298 * c - 100 * d - 208 * e + 128) >> 8));
      rgb_data[j + 5] = std::min(255, std::max(0, (298 * c + 516 * d + 128) >> 8));
    }
    
    // Encode as BMP and queue for sending on main thread
    if (self->event_channel && self->stream_active) {
      frame_count++;

      // Encode RGB to BMP
      std::vector<uint8_t> bmp_data = encode_bmp(rgb_data.data(), 256, 64);

      if (frame_count % 30 == 1) {  // Log every 30th frame to avoid spam
        g_print("[USB Video] Queueing frame %d, BMP size=%zu bytes\n", frame_count, bmp_data.size());
      }

      // Queue frame for main thread to send (thread-safe)
      {
        std::lock_guard<std::mutex> lock(*self->frame_queue_mutex);
        self->pending_frames->push(std::move(bmp_data));
      }
    } else {
      if (frame_count % 30 == 0) {  // Log periodically
        g_print("[USB Video] Warning: event_channel or stream not active, frames not being sent\n");
      }
    }
    
    // Queue buffer again
    if (ioctl(self->fd, VIDIOC_QBUF, &buf) == -1) {
      g_warning("Failed to queue buffer: %s", strerror(errno));
      break;
    }
  }
}

static bool start_video_stream(UsbVideoCapturePlugin* self, const char* device_path) {
  g_print("[USB Video] Starting video stream for device: %s\n", device_path);
  
  // Open device
  self->fd = open(device_path, O_RDWR);
  if (self->fd == -1) {
    g_warning("Cannot open device %s: %s", device_path, strerror(errno));
    return false;
  }
  g_print("[USB Video] Device opened successfully, fd=%d\n", self->fd);
  
  // Get current format
  struct v4l2_format fmt;
  memset(&fmt, 0, sizeof(fmt));
  fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  
  if (ioctl(self->fd, VIDIOC_G_FMT, &fmt) == -1) {
    g_warning("[USB Video] Failed to get format: %s", strerror(errno));
    close(self->fd);
    self->fd = -1;
    return false;
  }
  
  g_print("[USB Video] Current format: %dx%d, pixelformat=0x%08X\n", 
          fmt.fmt.pix.width, fmt.fmt.pix.height, fmt.fmt.pix.pixelformat);
  
  // Check if format is already correct
  if (fmt.fmt.pix.width == 256 && fmt.fmt.pix.height == 64 && 
      fmt.fmt.pix.pixelformat == V4L2_PIX_FMT_YUYV) {
    g_print("[USB Video] Format already correct, skipping format set\n");
  } else {
    // Try to set format
    fmt.fmt.pix.width = 256;
    fmt.fmt.pix.height = 64;
    fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
    fmt.fmt.pix.field = V4L2_FIELD_ANY;
    
    g_print("[USB Video] Setting format to 256x64 YUYV...\n");
    if (ioctl(self->fd, VIDIOC_S_FMT, &fmt) == -1) {
      g_warning("[USB Video] Failed to set format: %s (errno=%d)", strerror(errno), errno);
      // Don't fail here, try to continue with current format
      g_print("[USB Video] Continuing with current format\n");
    } else {
      g_print("[USB Video] Format set successfully: actual %dx%d\n", 
              fmt.fmt.pix.width, fmt.fmt.pix.height);
    }
  }
  
  // Request buffers
  struct v4l2_requestbuffers req;
  memset(&req, 0, sizeof(req));
  req.count = 4;
  req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  req.memory = V4L2_MEMORY_MMAP;
  
  g_print("[USB Video] Requesting 4 buffers...\n");
  if (ioctl(self->fd, VIDIOC_REQBUFS, &req) == -1) {
    g_warning("[USB Video] Failed to request buffers: %s", strerror(errno));
    close(self->fd);
    self->fd = -1;
    return false;
  }
  g_print("[USB Video] Got %d buffers\n", req.count);
  
  // Allocate buffer info
  g_print("[USB Video] Allocating and mapping %d buffers...\n", req.count);
  self->buffers = (struct Buffer*)calloc(req.count, sizeof(struct Buffer));
  self->n_buffers = req.count;
  
  // Map buffers
  for (unsigned int i = 0; i < req.count; ++i) {
    struct v4l2_buffer buf;
    memset(&buf, 0, sizeof(buf));
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;
    
    if (ioctl(self->fd, VIDIOC_QUERYBUF, &buf) == -1) {
      g_warning("Failed to query buffer: %s", strerror(errno));
      stop_capture(self);
      return false;
    }
    
    self->buffers[i].length = buf.length;
    self->buffers[i].start = mmap(NULL, buf.length,
                                  PROT_READ | PROT_WRITE,
                                  MAP_SHARED,
                                  self->fd, buf.m.offset);
    
    if (self->buffers[i].start == MAP_FAILED) {
      g_warning("Failed to map buffer: %s", strerror(errno));
      stop_capture(self);
      return false;
    }
  }
  
  // Queue buffers
  for (unsigned int i = 0; i < self->n_buffers; ++i) {
    struct v4l2_buffer buf;
    memset(&buf, 0, sizeof(buf));
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;
    
    if (ioctl(self->fd, VIDIOC_QBUF, &buf) == -1) {
      g_warning("Failed to queue buffer: %s", strerror(errno));
      stop_capture(self);
      return false;
    }
  }
  
  // Start streaming
  enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (ioctl(self->fd, VIDIOC_STREAMON, &type) == -1) {
    g_warning("Failed to start streaming: %s", strerror(errno));
    stop_capture(self);
    return false;
  }
  
  // Start capture thread
  self->capturing = true;
  self->capture_thread = new std::thread(capture_frames, self);
  g_print("[USB Video] Capture thread started\n");
  
  return true;
}

// Called when a method call is received from Flutter.
static void usb_video_capture_plugin_handle_method_call(
    UsbVideoCapturePlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "isSupported") == 0) {
    // Linux USB video capture is now supported
    g_print("[USB Video] isSupported called - returning TRUE\n");
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "listUsbCameras") == 0) {
    g_print("[USB Video] listUsbCameras called\n");
    g_autoptr(FlValue) cameras = fl_value_new_list();
    
    // Check for Disting NT video device
    DIR* dir = opendir("/sys/class/video4linux");
    if (dir) {
      struct dirent* entry;
      while ((entry = readdir(dir)) != NULL) {
        if (strncmp(entry->d_name, "video", 5) == 0) {
          char path[256];
          char name[256];
          snprintf(path, sizeof(path), "/sys/class/video4linux/%s/name", entry->d_name);
          
          FILE* f = fopen(path, "r");
          if (f) {
            if (fgets(name, sizeof(name), f)) {
              // Remove newline
              size_t len = strlen(name);
              if (len > 0 && name[len-1] == '\n') {
                name[len-1] = '\0';
              }
              
              // Check if it's the Disting NT
              if (strstr(name, "disting") || strstr(name, "NT")) {
                g_print("[USB Video] Found Disting NT device: %s at /dev/%s\n", name, entry->d_name);
                
                // Only add video0 as it's the actual capture device
                // video1 doesn't support any formats
                if (strcmp(entry->d_name, "video0") == 0) {
                  FlValue* camera = fl_value_new_map();
                  char device_path[32];
                  snprintf(device_path, sizeof(device_path), "/dev/%s", entry->d_name);
                  
                  fl_value_set_string(camera, "deviceId", fl_value_new_string(device_path));
                  fl_value_set_string(camera, "productName", fl_value_new_string(name));
                  fl_value_set_string(camera, "vendorId", fl_value_new_int(0x3773));
                  fl_value_set_string(camera, "productId", fl_value_new_int(0x0001));
                  fl_value_set_string(camera, "isDistingNT", fl_value_new_bool(TRUE));
                  
                  fl_value_append_take(cameras, camera);
                }
              }
            }
            fclose(f);
          }
        }
      }
      closedir(dir);
    }
    
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(cameras));
  } else if (strcmp(method, "requestUsbPermission") == 0) {
    // Linux doesn't need special USB permissions if user is in video group
    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "startVideoStream") == 0) {
    g_print("[USB Video] startVideoStream method called\n");
    FlValue* args = fl_method_call_get_args(method_call);
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* device_id = fl_value_lookup_string(args, "deviceId");
      if (device_id && fl_value_get_type(device_id) == FL_VALUE_TYPE_STRING) {
        const char* device_path = fl_value_get_string(device_id);
        g_print("[USB Video] Starting stream for device: %s\n", device_path);
        
        stop_capture(self); // Stop any existing capture
        
        if (start_video_stream(self, device_path)) {
          g_print("[USB Video] start_video_stream returned true\n");
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
        } else {
          g_print("[USB Video] start_video_stream returned false\n");
          response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "STREAM_ERROR", "Failed to start video stream", nullptr));
        }
      } else {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENTS", "deviceId is required", nullptr));
      }
    } else {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGUMENTS", "Arguments must be a map", nullptr));
    }
  } else if (strcmp(method, "stopVideoStream") == 0) {
    stop_capture(self);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void usb_video_capture_plugin_dispose(GObject* object) {
  UsbVideoCapturePlugin* self = USB_VIDEO_CAPTURE_PLUGIN(object);

  // Remove idle handler
  if (self->idle_source_id != 0) {
    g_source_remove(self->idle_source_id);
    self->idle_source_id = 0;
  }

  stop_capture(self);

  // Clean up frame queue
  if (self->pending_frames) {
    delete self->pending_frames;
    self->pending_frames = nullptr;
  }
  if (self->frame_queue_mutex) {
    delete self->frame_queue_mutex;
    self->frame_queue_mutex = nullptr;
  }

  G_OBJECT_CLASS(usb_video_capture_plugin_parent_class)->dispose(object);
}

static void usb_video_capture_plugin_class_init(UsbVideoCapturePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = usb_video_capture_plugin_dispose;
}

static void usb_video_capture_plugin_init(UsbVideoCapturePlugin* self) {
  self->fd = -1;
  self->buffers = nullptr;
  self->n_buffers = 0;
  self->capture_thread = nullptr;
  self->capturing = false;
  self->event_channel = nullptr;
  self->debug_channel = nullptr;
  self->stream_active = false;

  self->frame_queue_mutex = new std::mutex();
  self->pending_frames = new std::queue<std::vector<uint8_t>>();

  self->idle_source_id = g_timeout_add(16, send_pending_frames, self);
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  UsbVideoCapturePlugin* plugin = USB_VIDEO_CAPTURE_PLUGIN(user_data);
  usb_video_capture_plugin_handle_method_call(plugin, method_call);
}

extern "C" void usb_video_capture_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
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
  
  // Setup event channel for video stream
  plugin->event_channel = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.example.nt_helper/usb_video_stream",
      FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(plugin->event_channel,
                                       event_channel_listen,
                                       event_channel_cancel,
                                       plugin,
                                       nullptr);

  plugin->debug_channel = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.example.nt_helper/usb_video_debug",
      FL_METHOD_CODEC(codec));

  g_object_unref(plugin);
}