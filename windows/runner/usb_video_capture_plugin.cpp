#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <memory>
#include <sstream>
#include <vector>
#include <string>
#include <thread>
#include <atomic>
#include <chrono>
#include <mutex>
#include <queue>
#include <map>
#include <windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <mferror.h>
#include <Mfobjects.h>
#include <comdef.h>
#include <atlbase.h>

#pragma comment(lib, "mfplat.lib")
#pragma comment(lib, "mfreadwrite.lib")
#pragma comment(lib, "mfuuid.lib")
#pragma comment(lib, "mf.lib")

namespace {

class UsbVideoCapturePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  UsbVideoCapturePlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~UsbVideoCapturePlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::vector<flutter::EncodableMap> EnumerateVideoCaptureDevices();
  bool StartVideoCapture(const std::string& deviceId);
  void StopVideoCapture();
  void CaptureThread();
  std::vector<uint8_t> EncodeBMP(const uint8_t* rgb_data, int width, int height);

  void ProcessPendingFrames();
  static LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> event_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

  CComPtr<IMFSourceReader> source_reader_;
  std::thread* capture_thread_ = nullptr;
  std::atomic<bool> capturing_{false};
  std::atomic<bool> stream_active_{false};
  bool mf_initialized_ = false;

  // Thread-safe frame queue for posting to platform thread
  std::mutex frame_queue_mutex_;
  std::queue<std::vector<uint8_t>> pending_frames_;
  HWND message_window_ = nullptr;
  int window_proc_id_ = 0;
  static const UINT WM_SEND_FRAME = WM_USER + 1;
};

// static
void UsbVideoCapturePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.example.nt_helper/usb_video",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<UsbVideoCapturePlugin>(registrar);

  auto plugin_ptr = plugin.get();

  // Set up event channel for video streaming
  plugin->event_channel_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), "com.example.nt_helper/usb_video_stream",
      &flutter::StandardMethodCodec::GetInstance());

  auto event_handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [plugin_ptr](const flutter::EncodableValue* arguments,
                   std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
                   -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        plugin_ptr->event_sink_ = std::move(events);
        plugin_ptr->stream_active_ = true;
        return nullptr;
      },
      [plugin_ptr](const flutter::EncodableValue* arguments)
                   -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        plugin_ptr->stream_active_ = false;
        plugin_ptr->StopVideoCapture();
        plugin_ptr->event_sink_ = nullptr;
        return nullptr;
      });

  plugin->event_channel_->SetStreamHandler(std::move(event_handler));

  channel->SetMethodCallHandler(
      [plugin_ptr](const auto &call, auto result) {
        plugin_ptr->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

// Static map to look up plugin instances from window handles
static std::map<HWND, UsbVideoCapturePlugin*> g_plugin_instances;

LRESULT CALLBACK UsbVideoCapturePlugin::WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == WM_SEND_FRAME) {
    auto it = g_plugin_instances.find(hwnd);
    if (it != g_plugin_instances.end()) {
      it->second->ProcessPendingFrames();
    }
    return 0;
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

void UsbVideoCapturePlugin::ProcessPendingFrames() {
  std::vector<uint8_t> frame;
  {
    std::lock_guard<std::mutex> lock(frame_queue_mutex_);
    if (pending_frames_.empty()) return;
    frame = std::move(pending_frames_.front());
    pending_frames_.pop();
    // Clear any backlog to prevent memory buildup - keep only latest frame
    while (!pending_frames_.empty()) {
      pending_frames_.pop();
    }
  }

  if (event_sink_ && stream_active_ && !frame.empty()) {
    event_sink_->Success(flutter::EncodableValue(frame));
  }
}

UsbVideoCapturePlugin::UsbVideoCapturePlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar) {
  // Initialize Media Foundation
  OutputDebugStringA("[USB_VIDEO_CPP] Initializing Media Foundation...\n");
  HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
  if (SUCCEEDED(hr)) {
    hr = MFStartup(MF_VERSION);
    if (SUCCEEDED(hr)) {
      mf_initialized_ = true;
      OutputDebugStringA("[USB_VIDEO_CPP] Media Foundation initialized successfully\n");
    } else {
      OutputDebugStringA("[USB_VIDEO_CPP] MFStartup failed\n");
    }
  } else {
    OutputDebugStringA("[USB_VIDEO_CPP] CoInitializeEx failed\n");
  }

  // Create a message-only window for thread communication
  WNDCLASSA wc = {};
  wc.lpfnWndProc = WndProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.lpszClassName = "UsbVideoCapturePluginMessageWindow";
  RegisterClassA(&wc);

  message_window_ = CreateWindowA(
      "UsbVideoCapturePluginMessageWindow",
      nullptr,
      0, 0, 0, 0, 0,
      HWND_MESSAGE,  // Message-only window
      nullptr,
      GetModuleHandle(nullptr),
      nullptr);

  if (message_window_) {
    g_plugin_instances[message_window_] = this;
    OutputDebugStringA("[USB_VIDEO_CPP] Message window created for thread-safe frame delivery\n");
  }
}

UsbVideoCapturePlugin::~UsbVideoCapturePlugin() {
  StopVideoCapture();
  if (message_window_) {
    g_plugin_instances.erase(message_window_);
    DestroyWindow(message_window_);
    message_window_ = nullptr;
  }
  if (mf_initialized_) {
    MFShutdown();
    CoUninitialize();
  }
}

std::vector<flutter::EncodableMap> UsbVideoCapturePlugin::EnumerateVideoCaptureDevices() {
  std::vector<flutter::EncodableMap> devices;

  OutputDebugStringA("[USB_VIDEO_CPP] EnumerateVideoCaptureDevices called\n");

  if (!mf_initialized_) {
    OutputDebugStringA("[USB_VIDEO_CPP] Media Foundation not initialized, returning empty list\n");
    return devices;
  }

  CComPtr<IMFAttributes> attributes;
  HRESULT hr = MFCreateAttributes(&attributes, 1);
  if (FAILED(hr)) {
    OutputDebugStringA("[USB_VIDEO_CPP] MFCreateAttributes failed\n");
    return devices;
  }

  hr = attributes->SetGUID(MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE,
                           MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID);
  if (FAILED(hr)) {
    OutputDebugStringA("[USB_VIDEO_CPP] SetGUID failed\n");
    return devices;
  }

  IMFActivate** ppDevices = nullptr;
  UINT32 count = 0;

  hr = MFEnumDeviceSources(attributes, &ppDevices, &count);

  char debugMsg[256];
  sprintf_s(debugMsg, "[USB_VIDEO_CPP] MFEnumDeviceSources returned %d devices (hr=0x%08X)\n", count, hr);
  OutputDebugStringA(debugMsg);

  if (SUCCEEDED(hr)) {
    for (UINT32 i = 0; i < count; i++) {
      WCHAR* friendlyName = nullptr;
      WCHAR* symbolicLink = nullptr;
      UINT32 nameLength = 0;
      UINT32 linkLength = 0;

      hr = ppDevices[i]->GetAllocatedString(MF_DEVSOURCE_ATTRIBUTE_FRIENDLY_NAME,
                                            &friendlyName, &nameLength);
      if (SUCCEEDED(hr)) {
        hr = ppDevices[i]->GetAllocatedString(
            MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_SYMBOLIC_LINK,
            &symbolicLink, &linkLength);

        if (SUCCEEDED(hr)) {
          flutter::EncodableMap device;

          // Convert wide strings to narrow strings
          int nameSize = WideCharToMultiByte(CP_UTF8, 0, friendlyName, -1, nullptr, 0, nullptr, nullptr);
          std::string name(nameSize - 1, 0);
          WideCharToMultiByte(CP_UTF8, 0, friendlyName, -1, &name[0], nameSize, nullptr, nullptr);

          int linkSize = WideCharToMultiByte(CP_UTF8, 0, symbolicLink, -1, nullptr, 0, nullptr, nullptr);
          std::string link(linkSize - 1, 0);
          WideCharToMultiByte(CP_UTF8, 0, symbolicLink, -1, &link[0], linkSize, nullptr, nullptr);

          // Check if device name contains "disting" (case-insensitive)
          std::string nameLower = name;
          for (auto& c : nameLower) c = static_cast<char>(tolower(c));
          bool isDistingNT = (nameLower.find("disting") != std::string::npos) ||
                             (nameLower.find("nt") != std::string::npos);
          
          char detectMsg[512];
          sprintf_s(detectMsg, "[USB_VIDEO_CPP] Device: %s, isDistingNT: %s\n", name.c_str(), isDistingNT ? "true" : "false");
          OutputDebugStringA(detectMsg);

          device[flutter::EncodableValue("productName")] = flutter::EncodableValue(name);
          device[flutter::EncodableValue("deviceId")] = flutter::EncodableValue(link);
          device[flutter::EncodableValue("vendorId")] = flutter::EncodableValue(0);
          device[flutter::EncodableValue("productId")] = flutter::EncodableValue(0);
          device[flutter::EncodableValue("isDistingNT")] = flutter::EncodableValue(isDistingNT);

          devices.push_back(device);

          CoTaskMemFree(symbolicLink);
        }
        CoTaskMemFree(friendlyName);
      }
      ppDevices[i]->Release();
    }
    CoTaskMemFree(ppDevices);
  }

  return devices;
}

bool UsbVideoCapturePlugin::StartVideoCapture(const std::string& deviceId) {
  StopVideoCapture();

  char debugMsg[512];
  sprintf_s(debugMsg, "[USB_VIDEO_CPP] StartVideoCapture called with device: %s\n", deviceId.c_str());
  OutputDebugStringA(debugMsg);

  if (!mf_initialized_) {
    OutputDebugStringA("[USB_VIDEO_CPP] Media Foundation not initialized\n");
    return false;
  }

  // Convert device ID to wide string
  int size = MultiByteToWideChar(CP_UTF8, 0, deviceId.c_str(), -1, nullptr, 0);
  std::wstring wideDeviceId(size - 1, 0);
  MultiByteToWideChar(CP_UTF8, 0, deviceId.c_str(), -1, &wideDeviceId[0], size);

  CComPtr<IMFAttributes> attributes;
  HRESULT hr = MFCreateAttributes(&attributes, 2);
  if (FAILED(hr)) {
    sprintf_s(debugMsg, "[USB_VIDEO_CPP] MFCreateAttributes failed: 0x%08X\n", hr);
    OutputDebugStringA(debugMsg);
    return false;
  }

  hr = attributes->SetGUID(MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE,
                           MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID);
  if (FAILED(hr)) {
    sprintf_s(debugMsg, "[USB_VIDEO_CPP] SetGUID failed: 0x%08X\n", hr);
    OutputDebugStringA(debugMsg);
    return false;
  }

  hr = attributes->SetString(MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_SYMBOLIC_LINK,
                             wideDeviceId.c_str());
  if (FAILED(hr)) {
    sprintf_s(debugMsg, "[USB_VIDEO_CPP] SetString failed: 0x%08X\n", hr);
    OutputDebugStringA(debugMsg);
    return false;
  }

  CComPtr<IMFMediaSource> source;
  hr = MFCreateDeviceSource(attributes, &source);
  if (FAILED(hr)) {
    sprintf_s(debugMsg, "[USB_VIDEO_CPP] MFCreateDeviceSource failed: 0x%08X\n", hr);
    OutputDebugStringA(debugMsg);
    return false;
  }

  hr = MFCreateSourceReaderFromMediaSource(source, nullptr, &source_reader_);
  if (FAILED(hr)) {
    sprintf_s(debugMsg, "[USB_VIDEO_CPP] MFCreateSourceReaderFromMediaSource failed: 0x%08X\n", hr);
    OutputDebugStringA(debugMsg);
    return false;
  }

  // First, try to get the native media type from the device
  CComPtr<IMFMediaType> nativeType;
  hr = source_reader_->GetNativeMediaType((DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0, &nativeType);
  if (SUCCEEDED(hr)) {
    OutputDebugStringA("[USB_VIDEO_CPP] Got native media type, attempting to use it\n");

    // Try to use the native format directly
    hr = source_reader_->SetCurrentMediaType((DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM,
                                             nullptr, nativeType);
    if (SUCCEEDED(hr)) {
      OutputDebugStringA("[USB_VIDEO_CPP] Using native media type succeeded\n");
    } else {
      sprintf_s(debugMsg, "[USB_VIDEO_CPP] Setting native media type failed: 0x%08X\n", hr);
      OutputDebugStringA(debugMsg);
    }
  }

  // If native format didn't work, try common formats
  if (FAILED(hr)) {
    OutputDebugStringA("[USB_VIDEO_CPP] Trying standard RGB formats\n");

    // Try different video formats in order of preference
    GUID formats[] = {
      MFVideoFormat_YUY2,  // Common USB camera format
      MFVideoFormat_NV12,  // Another common format
      MFVideoFormat_RGB24,
      MFVideoFormat_RGB32,
      MFVideoFormat_MJPG   // MJPEG is often used by USB cameras
    };

    bool formatSet = false;
    for (int i = 0; i < 5; i++) {
      CComPtr<IMFMediaType> mediaType;
      hr = MFCreateMediaType(&mediaType);
      if (FAILED(hr)) continue;

      hr = mediaType->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
      if (FAILED(hr)) continue;

      hr = mediaType->SetGUID(MF_MT_SUBTYPE, formats[i]);
      if (FAILED(hr)) continue;

      // Set resolution hint for Disting NT
      hr = MFSetAttributeSize(mediaType, MF_MT_FRAME_SIZE, 256, 64);

      hr = source_reader_->SetCurrentMediaType((DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM,
                                               nullptr, mediaType);
      if (SUCCEEDED(hr)) {
        sprintf_s(debugMsg, "[USB_VIDEO_CPP] Successfully set format index %d\n", i);
        OutputDebugStringA(debugMsg);
        formatSet = true;
        break;
      }
    }

    if (!formatSet) {
      OutputDebugStringA("[USB_VIDEO_CPP] Failed to set any video format\n");
      return false;
    }
  }

  OutputDebugStringA("[USB_VIDEO_CPP] Video capture initialized successfully, starting capture thread\n");

  // Start the capture thread
  capturing_ = true;
  capture_thread_ = new std::thread(&UsbVideoCapturePlugin::CaptureThread, this);

  // Send a test frame immediately to verify the connection works
  if (event_sink_ && stream_active_) {
    std::vector<uint8_t> test_rgb(256 * 64 * 3);
    for (int i = 0; i < 256 * 64; i++) {
      test_rgb[i * 3] = static_cast<uint8_t>(255);      // R - red
      test_rgb[i * 3 + 1] = static_cast<uint8_t>(0);    // G
      test_rgb[i * 3 + 2] = static_cast<uint8_t>(0);    // B
    }
    std::vector<uint8_t> test_bmp = EncodeBMP(test_rgb.data(), 256, 64);
    event_sink_->Success(flutter::EncodableValue(test_bmp));
    OutputDebugStringA("[USB_VIDEO_CPP] Sent test frame immediately\n");
  }

  return true;
}

void UsbVideoCapturePlugin::StopVideoCapture() {
  if (capturing_) {
    capturing_ = false;
    if (capture_thread_) {
      capture_thread_->join();
      delete capture_thread_;
      capture_thread_ = nullptr;
    }
  }

  if (source_reader_) {
    source_reader_.Release();
  }
}

void UsbVideoCapturePlugin::CaptureThread() {
  OutputDebugStringA("[USB_VIDEO_CPP] Capture thread started\n");

  while (capturing_) {
    if (!stream_active_ || !event_sink_) {
      std::this_thread::sleep_for(std::chrono::milliseconds(100));
      continue;
    }

    // Try to read real video frames
    if (source_reader_) {
      DWORD streamIndex, flags;
      LONGLONG timestamp;
      CComPtr<IMFSample> sample;

      HRESULT hr = source_reader_->ReadSample(
          (DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM,
          0, &streamIndex, &flags, &timestamp, &sample);

      if (FAILED(hr)) {
        char debugMsg[256];
        sprintf_s(debugMsg, "[USB_VIDEO_CPP] ReadSample failed: 0x%08X\n", hr);
        OutputDebugStringA(debugMsg);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        continue;
      }

      if (!sample) {
        std::this_thread::sleep_for(std::chrono::milliseconds(33));
        continue;
      }

      CComPtr<IMFMediaBuffer> buffer;
      hr = sample->ConvertToContiguousBuffer(&buffer);
      if (FAILED(hr)) continue;

      BYTE* data = nullptr;
      DWORD length = 0;
      hr = buffer->Lock(&data, nullptr, &length);
      if (FAILED(hr)) continue;

      // Get the actual media type to understand the format
      CComPtr<IMFMediaType> currentType;
      hr = source_reader_->GetCurrentMediaType((DWORD)MF_SOURCE_READER_FIRST_VIDEO_STREAM, &currentType);

      UINT32 width = 256, height = 64;  // Default to Disting NT dimensions
      GUID subtype = GUID_NULL;
      if (SUCCEEDED(hr)) {
        MFGetAttributeSize(currentType, MF_MT_FRAME_SIZE, &width, &height);
        currentType->GetGUID(MF_MT_SUBTYPE, &subtype);

        char debugMsg[512];
        sprintf_s(debugMsg, "[USB_VIDEO_CPP] Frame format: %dx%d, data length: %d bytes, subtype: %08X-%04X-%04X\n",
                  width, height, length, subtype.Data1, subtype.Data2, subtype.Data3);
        OutputDebugStringA(debugMsg);
      }

      // Calculate expected sizes for different formats
      UINT32 expected_rgb24 = width * height * 3;
      UINT32 expected_rgb32 = width * height * 4;
      UINT32 expected_yuy2 = width * height * 2;

      char sizeMsg[256];
      sprintf_s(sizeMsg, "[USB_VIDEO_CPP] Expected sizes - RGB24: %d, RGB32: %d, YUY2: %d, Actual: %d\n",
                expected_rgb24, expected_rgb32, expected_yuy2, length);
      OutputDebugStringA(sizeMsg);

      std::vector<uint8_t> bmp;

      // Check if it's close to RGB24 size (allowing for some padding)
      if (length >= expected_rgb24 && length <= expected_rgb24 + 100) {
        OutputDebugStringA("[USB_VIDEO_CPP] Processing as RGB24 data\n");
        bmp = EncodeBMP(data, width, height);
      }
      // Check if it's close to RGB32 size
      else if (length >= expected_rgb32 && length <= expected_rgb32 + 100) {
        OutputDebugStringA("[USB_VIDEO_CPP] Processing as RGB32 data (converting to RGB24)\n");
        // Convert RGBA to RGB
        std::vector<uint8_t> rgb_data(width * height * 3);
        for (UINT32 i = 0; i < width * height; i++) {
          rgb_data[i * 3] = data[i * 4];       // R
          rgb_data[i * 3 + 1] = data[i * 4 + 1]; // G
          rgb_data[i * 3 + 2] = data[i * 4 + 2]; // B
          // Skip alpha channel
        }
        bmp = EncodeBMP(rgb_data.data(), width, height);
      }
      // Check if it's YUY2 format
      else if (length >= expected_yuy2 && length <= expected_yuy2 + 100) {
        OutputDebugStringA("[USB_VIDEO_CPP] Processing as YUY2 data (converting to RGB)\n");
        // Convert YUY2 to RGB
        std::vector<uint8_t> rgb_data(width * height * 3);
        for (UINT32 i = 0; i < width * height / 2; i++) {
          // YUY2 format: Y0 U Y1 V (4 bytes for 2 pixels)
          uint8_t y0 = data[i * 4];
          uint8_t u = data[i * 4 + 1];
          uint8_t y1 = data[i * 4 + 2];
          uint8_t v = data[i * 4 + 3];

          // Convert YUV to RGB for pixel 0
          int r0 = static_cast<int>(y0 + 1.402 * (v - 128));
          int g0 = static_cast<int>(y0 - 0.344 * (u - 128) - 0.714 * (v - 128));
          int b0 = static_cast<int>(y0 + 1.772 * (u - 128));

          // Convert YUV to RGB for pixel 1
          int r1 = static_cast<int>(y1 + 1.402 * (v - 128));
          int g1 = static_cast<int>(y1 - 0.344 * (u - 128) - 0.714 * (v - 128));
          int b1 = static_cast<int>(y1 + 1.772 * (u - 128));

          // Clamp values and store
          rgb_data[i * 6] = static_cast<uint8_t>(std::max(0, std::min(255, r0)));
          rgb_data[i * 6 + 1] = static_cast<uint8_t>(std::max(0, std::min(255, g0)));
          rgb_data[i * 6 + 2] = static_cast<uint8_t>(std::max(0, std::min(255, b0)));
          rgb_data[i * 6 + 3] = static_cast<uint8_t>(std::max(0, std::min(255, r1)));
          rgb_data[i * 6 + 4] = static_cast<uint8_t>(std::max(0, std::min(255, g1)));
          rgb_data[i * 6 + 5] = static_cast<uint8_t>(std::max(0, std::min(255, b1)));
        }
        bmp = EncodeBMP(rgb_data.data(), width, height);
      }
      else {
        // Unknown format - create a diagnostic pattern showing the issue
        OutputDebugStringA("[USB_VIDEO_CPP] Unknown format, creating diagnostic pattern\n");
        std::vector<uint8_t> rgb_data(width * height * 3);
        for (UINT32 i = 0; i < width * height; i++) {
          // Create a pattern that shows the data size issue
          rgb_data[i * 3] = static_cast<uint8_t>(255);      // Red to indicate error
          rgb_data[i * 3 + 1] = static_cast<uint8_t>(length % 256); // Green shows length
          rgb_data[i * 3 + 2] = static_cast<uint8_t>((length / 256) % 256); // Blue shows length
        }
        bmp = EncodeBMP(rgb_data.data(), width, height);
      }

      buffer->Unlock();

      // Queue frame for platform thread delivery (thread-safe)
      if (stream_active_ && !bmp.empty() && message_window_) {
        {
          std::lock_guard<std::mutex> lock(frame_queue_mutex_);
          pending_frames_.push(std::move(bmp));
        }
        PostMessage(message_window_, WM_SEND_FRAME, 0, 0);
        OutputDebugStringA("[USB_VIDEO_CPP] Queued real video frame for Flutter\n");
      }
    } else {
      // Fall back to test frames if no source reader
      std::vector<uint8_t> test_rgb(256 * 64 * 3, 64);  // Dark gray
      std::vector<uint8_t> test_bmp = EncodeBMP(test_rgb.data(), 256, 64);
      if (stream_active_ && message_window_) {
        {
          std::lock_guard<std::mutex> lock(frame_queue_mutex_);
          pending_frames_.push(std::move(test_bmp));
        }
        PostMessage(message_window_, WM_SEND_FRAME, 0, 0);
        OutputDebugStringA("[USB_VIDEO_CPP] Queued fallback test frame\n");
      }
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(33)); // ~30 FPS
  }

  OutputDebugStringA("[USB_VIDEO_CPP] Capture thread ending\n");
}

std::vector<uint8_t> UsbVideoCapturePlugin::EncodeBMP(const uint8_t* rgb_data, int width, int height) {
  // BMP file format for 256x64 RGB image
  int row_padding = (4 - (width * 3) % 4) % 4;
  int row_size = width * 3 + row_padding;
  int data_size = row_size * height;
  int file_size = 54 + data_size;

  std::vector<uint8_t> bmp(file_size);

  // BMP Header
  bmp[0] = 'B'; bmp[1] = 'M';
  *(uint32_t*)&bmp[2] = file_size;
  *(uint32_t*)&bmp[6] = 0;
  *(uint32_t*)&bmp[10] = 54;

  // DIB Header
  *(uint32_t*)&bmp[14] = 40;
  *(int32_t*)&bmp[18] = width;
  *(int32_t*)&bmp[22] = -height; // Negative for top-down
  *(uint16_t*)&bmp[26] = 1;
  *(uint16_t*)&bmp[28] = 24;
  *(uint32_t*)&bmp[30] = 0;
  *(uint32_t*)&bmp[34] = data_size;
  *(int32_t*)&bmp[38] = 2835;
  *(int32_t*)&bmp[42] = 2835;
  *(uint32_t*)&bmp[46] = 0;
  *(uint32_t*)&bmp[50] = 0;

  // Copy RGB data
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int src_idx = (y * width + x) * 3;
      int dst_idx = 54 + y * row_size + x * 3;
      // BMP stores BGR, not RGB
      bmp[dst_idx] = rgb_data[src_idx + 2];     // B
      bmp[dst_idx + 1] = rgb_data[src_idx + 1]; // G
      bmp[dst_idx + 2] = rgb_data[src_idx];     // R
    }
  }

  return bmp;
}

void UsbVideoCapturePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  OutputDebugStringA(("[USB_VIDEO_CPP] HandleMethodCall: " + method_call.method_name() + "\n").c_str());

  if (method_call.method_name().compare("isSupported") == 0) {
    OutputDebugStringA(mf_initialized_ ? "[USB_VIDEO_CPP] isSupported: true\n" : "[USB_VIDEO_CPP] isSupported: false\n");
    result->Success(flutter::EncodableValue(mf_initialized_));
  } else if (method_call.method_name().compare("listUsbCameras") == 0) {
    auto devices = EnumerateVideoCaptureDevices();
    flutter::EncodableList device_list;
    for (const auto& device : devices) {
      device_list.push_back(flutter::EncodableValue(device));
    }
    result->Success(flutter::EncodableValue(device_list));
  } else if (method_call.method_name().compare("startVideoStream") == 0) {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGUMENT", "Arguments must be a map");
      return;
    }

    auto device_id_it = arguments->find(flutter::EncodableValue("deviceId"));
    if (device_id_it == arguments->end()) {
      result->Error("INVALID_ARGUMENT", "deviceId is required");
      return;
    }

    const auto* device_id = std::get_if<std::string>(&device_id_it->second);
    if (!device_id) {
      result->Error("INVALID_ARGUMENT", "deviceId must be a string");
      return;
    }

    bool success = StartVideoCapture(*device_id);
    result->Success(flutter::EncodableValue(success));
  } else if (method_call.method_name().compare("stopVideoStream") == 0) {
    StopVideoCapture();
    result->Success(flutter::EncodableValue(true));
  } else if (method_call.method_name().compare("requestUsbPermission") == 0) {
    // Windows doesn't require explicit USB permissions
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void UsbVideoCapturePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  UsbVideoCapturePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}