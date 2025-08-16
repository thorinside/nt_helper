#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <sstream>

namespace {

class UsbVideoCapturePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  UsbVideoCapturePlugin();

  virtual ~UsbVideoCapturePlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// static
void UsbVideoCapturePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.example.nt_helper/usb_video",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<UsbVideoCapturePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

UsbVideoCapturePlugin::UsbVideoCapturePlugin() {}

UsbVideoCapturePlugin::~UsbVideoCapturePlugin() {}

void UsbVideoCapturePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (method_call.method_name().compare("isSupported") == 0) {
    // Windows USB video capture is not implemented in this stub
    result->Success(flutter::EncodableValue(false));
  } else if (method_call.method_name().compare("listUsbCameras") == 0) {
    // Return empty list for stub implementation
    result->Success(flutter::EncodableValue(flutter::EncodableList()));
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