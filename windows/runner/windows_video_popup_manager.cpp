#include "windows_video_popup_manager.h"

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>
#include <pasteboard/pasteboard_plugin.h>
#include <windows.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "win32_window.h"

extern void UsbVideoCapturePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

namespace {

constexpr char kChannelName[] = "nt_helper/windows_video_popup";
constexpr char kEntryPointArg[] = "windows_video_popup";
constexpr wchar_t kDefaultTitle[] = L"Disting NT Video";

const flutter::EncodableValue* MapValue(const flutter::EncodableMap& map,
                                        const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) {
    return nullptr;
  }
  return &it->second;
}

std::optional<double> MapNumber(const flutter::EncodableMap& map,
                                const char* key) {
  const auto* value = MapValue(map, key);
  if (value == nullptr) {
    return std::nullopt;
  }
  if (const auto* double_value = std::get_if<double>(value)) {
    return *double_value;
  }
  if (const auto* int_value = std::get_if<int>(value)) {
    return static_cast<double>(*int_value);
  }
  if (const auto* int64_value = std::get_if<int64_t>(value)) {
    return static_cast<double>(*int64_value);
  }
  return std::nullopt;
}

bool MapBool(const flutter::EncodableMap& map,
             const char* key,
             bool default_value = false) {
  const auto* value = MapValue(map, key);
  if (value == nullptr) {
    return default_value;
  }
  if (const auto* bool_value = std::get_if<bool>(value)) {
    return *bool_value;
  }
  return default_value;
}

std::optional<std::string> MapString(const flutter::EncodableMap& map,
                                     const char* key) {
  const auto* value = MapValue(map, key);
  if (value == nullptr) {
    return std::nullopt;
  }
  if (const auto* string_value = std::get_if<std::string>(value)) {
    return *string_value;
  }
  return std::nullopt;
}

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return L"";
  }
  const int length =
      MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, nullptr, 0);
  if (length <= 0) {
    return L"";
  }
  std::wstring wide(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.c_str(), -1, wide.data(), length);
  if (!wide.empty() && wide.back() == L'\0') {
    wide.pop_back();
  }
  return wide;
}

std::wstring MapWideString(const flutter::EncodableMap& map,
                           const char* key,
                           const wchar_t* default_value) {
  const auto string_value = MapString(map, key);
  if (!string_value.has_value()) {
    return default_value;
  }
  const auto wide = Utf8ToWide(*string_value);
  return wide.empty() && !string_value->empty() ? default_value : wide;
}

double ScaleFactorForWindow(HWND hwnd) {
  if (hwnd == nullptr) {
    return 1.0;
  }
  HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
  const UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  if (dpi == 0) {
    return 1.0;
  }
  return static_cast<double>(dpi) / 96.0;
}

int LogicalToPhysical(HWND hwnd, double value) {
  return static_cast<int>(std::round(value * ScaleFactorForWindow(hwnd)));
}

double PhysicalToLogical(HWND hwnd, int value) {
  return static_cast<double>(value) / ScaleFactorForWindow(hwnd);
}

void FocusWindow(HWND hwnd) {
  if (hwnd == nullptr) {
    return;
  }

  HWND foreground_window = GetForegroundWindow();
  const DWORD foreground_thread_id =
      foreground_window == nullptr
          ? 0
          : GetWindowThreadProcessId(foreground_window, nullptr);
  const DWORD current_thread_id = GetCurrentThreadId();
  const bool attached =
      foreground_thread_id != 0 && foreground_thread_id != current_thread_id &&
      AttachThreadInput(foreground_thread_id, current_thread_id, TRUE);

  SetForegroundWindow(hwnd);
  SetActiveWindow(hwnd);
  HWND child = GetWindow(hwnd, GW_CHILD);
  if (child != nullptr) {
    SetFocus(child);
  }

  if (attached) {
    AttachThreadInput(foreground_thread_id, current_thread_id, FALSE);
  }
}

}  // namespace

class WindowsVideoPopupWindow : public Win32Window {
 public:
  explicit WindowsVideoPopupWindow(std::string window_arguments)
      : window_arguments_(std::move(window_arguments)) {}

  ~WindowsVideoPopupWindow() override = default;

  bool CreatePopup() {
    SetQuitOnClose(false);
    return Create(kDefaultTitle, Point(10, 10), Size(384, 132));
  }

  bool IsAlive() { return GetHandle() != nullptr; }

  void Configure(const flutter::EncodableMap& args) {
    HWND hwnd = GetHandle();
    if (hwnd == nullptr) {
      return;
    }

    suppress_bounds_events_ = true;

    const auto title = MapWideString(args, "title", kDefaultTitle);
    SetWindowText(hwnd, title.c_str());

    const int width = std::max(
        1, LogicalToPhysical(hwnd, MapNumber(args, "width").value_or(256.0)));
    const int height = std::max(
        1, LogicalToPhysical(hwnd, MapNumber(args, "height").value_or(100.0)));
    const auto x = MapNumber(args, "x");
    const auto y = MapNumber(args, "y");

    int left = x.has_value() ? LogicalToPhysical(hwnd, *x) : 0;
    int top = y.has_value() ? LogicalToPhysical(hwnd, *y) : 0;
    if (MapBool(args, "center", false)) {
      HWND reference_window = GetForegroundWindow();
      if (reference_window == nullptr) {
        reference_window = hwnd;
      }
      HMONITOR monitor =
          MonitorFromWindow(reference_window, MONITOR_DEFAULTTONEAREST);
      MONITORINFO monitor_info;
      monitor_info.cbSize = sizeof(MONITORINFO);
      if (GetMonitorInfo(monitor, &monitor_info)) {
        const RECT work = monitor_info.rcWork;
        left = work.left + ((work.right - work.left) - width) / 2;
        top = work.top + ((work.bottom - work.top) - height) / 2;
      }
    }

    SetWindowPos(hwnd, nullptr, left, top, width, height,
                 SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOACTIVATE);

    always_on_top_ = MapBool(args, "alwaysOnTop", false);
    if (always_on_top_) {
      SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }

    configured_ = true;
    suppress_bounds_events_ = false;
    Raise();
    SendBoundsChanged();
  }

  void Raise() {
    HWND hwnd = GetHandle();
    if (hwnd == nullptr) {
      return;
    }

    ShowWindow(hwnd, IsIconic(hwnd) ? SW_RESTORE : SW_SHOWNORMAL);
    SetWindowPos(hwnd, always_on_top_ ? HWND_TOPMOST : HWND_TOP, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
    BringWindowToTop(hwnd);
    FocusWindow(hwnd);
  }

  void SetAlwaysOnTop(bool always_on_top) {
    HWND hwnd = GetHandle();
    if (hwnd == nullptr) {
      return;
    }

    always_on_top_ = always_on_top;
    SetWindowPos(hwnd, always_on_top ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0,
                 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    Raise();
  }

  flutter::EncodableMap GetBounds() {
    flutter::EncodableMap result;
    HWND hwnd = GetHandle();
    if (hwnd == nullptr) {
      return result;
    }

    RECT rect;
    if (!GetWindowRect(hwnd, &rect)) {
      return result;
    }

    result[flutter::EncodableValue("x")] =
        flutter::EncodableValue(PhysicalToLogical(hwnd, rect.left));
    result[flutter::EncodableValue("y")] =
        flutter::EncodableValue(PhysicalToLogical(hwnd, rect.top));
    result[flutter::EncodableValue("width")] = flutter::EncodableValue(
        PhysicalToLogical(hwnd, rect.right - rect.left));
    result[flutter::EncodableValue("height")] = flutter::EncodableValue(
        PhysicalToLogical(hwnd, rect.bottom - rect.top));
    return result;
  }

  void SendBoundsChanged() {
    HWND hwnd = GetHandle();
    if (!configured_ || suppress_bounds_events_ || hwnd == nullptr ||
        !IsWindowVisible(hwnd) || channel_ == nullptr) {
      return;
    }

    channel_->InvokeMethod(
        "boundsChanged",
        std::make_unique<flutter::EncodableValue>(GetBounds()));
  }

 protected:
  bool OnCreate() override {
    RECT frame = GetClientArea();
    long view_width = frame.right - frame.left;
    long view_height = frame.bottom - frame.top;
    if (view_width <= 0 || view_height <= 0) {
      view_width = 384;
      view_height = 132;
    }

    flutter::DartProject project(L"data");
    project.set_ui_thread_policy(flutter::UIThreadPolicy::RunOnSeparateThread);
    std::vector<std::string> entrypoint_args = {kEntryPointArg,
                                                window_arguments_};
    project.set_dart_entrypoint_arguments(entrypoint_args);

    flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
        view_width, view_height, project);
    if (!flutter_controller_->engine() || !flutter_controller_->view()) {
      return false;
    }

    PasteboardPluginRegisterWithRegistrar(
        flutter_controller_->engine()->GetRegistrarForPlugin(
            "PasteboardPlugin"));
    UsbVideoCapturePluginRegisterWithRegistrar(
        flutter_controller_->engine()->GetRegistrarForPlugin(
            "UsbVideoCapturePlugin"));

    channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        flutter_controller_->engine()->messenger(), kChannelName,
        &flutter::StandardMethodCodec::GetInstance());
    channel_->SetMethodCallHandler([this](const auto& call, auto result) {
      HandleMethodCall(call, std::move(result));
    });

    SetChildContent(flutter_controller_->view()->GetNativeWindow());
    return true;
  }

  void OnDestroy() override {
    channel_.reset();
    flutter_controller_.reset();
    Win32Window::OnDestroy();
  }

  LRESULT MessageHandler(HWND hwnd,
                         UINT const message,
                         WPARAM const wparam,
                         LPARAM const lparam) noexcept override {
    if (flutter_controller_) {
      std::optional<LRESULT> result =
          flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                        lparam);
      if (result) {
        return *result;
      }
    }

    if (message == WM_CLOSE) {
      SendBoundsChanged();
      DestroyWindow(hwnd);
      return 0;
    }

    if (message == WM_FONTCHANGE && flutter_controller_ &&
        flutter_controller_->engine()) {
      flutter_controller_->engine()->ReloadSystemFonts();
    }

    const LRESULT result =
        Win32Window::MessageHandler(hwnd, message, wparam, lparam);
    if (message == WM_MOVE || message == WM_SIZE ||
        message == WM_EXITSIZEMOVE) {
      SendBoundsChanged();
    }
    return result;
  }

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (call.method_name() == "configureVideoPopup") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (args == nullptr) {
        result->Error("bad_args", "configureVideoPopup requires a map");
        return;
      }
      Configure(*args);
      result->Success(flutter::EncodableValue(true));
      return;
    }

    if (call.method_name() == "raiseCurrentWindow") {
      Raise();
      result->Success(flutter::EncodableValue(true));
      return;
    }

    if (call.method_name() == "setAlwaysOnTop") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (args == nullptr) {
        result->Error("bad_args", "setAlwaysOnTop requires a map");
        return;
      }
      SetAlwaysOnTop(MapBool(*args, "alwaysOnTop"));
      result->Success(flutter::EncodableValue(true));
      return;
    }

    if (call.method_name() == "getBounds") {
      result->Success(flutter::EncodableValue(GetBounds()));
      return;
    }

    if (call.method_name() == "setDisplayMode") {
      const auto* mode_name = std::get_if<std::string>(call.arguments());
      if (mode_name == nullptr) {
        result->Error("bad_args", "setDisplayMode requires a string");
        return;
      }
      WindowsVideoPopupManager::Instance().ForwardDisplayMode(*mode_name);
      result->Success(flutter::EncodableValue(true));
      return;
    }

    result->NotImplemented();
  }

  std::string window_arguments_;
  bool always_on_top_ = false;
  bool configured_ = false;
  bool suppress_bounds_events_ = false;
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

WindowsVideoPopupManager& WindowsVideoPopupManager::Instance() {
  static WindowsVideoPopupManager manager;
  return manager;
}

void WindowsVideoPopupManager::RegisterMainEngine(
    flutter::FlutterEngine* engine) {
  if (engine == nullptr) {
    return;
  }

  main_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), kChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  main_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "openOrFocus") {
      const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
      if (args == nullptr) {
        result->Error("bad_args", "openOrFocus requires a map");
        return;
      }
      const auto window_arguments = MapString(*args, "arguments");
      if (!window_arguments.has_value()) {
        result->Error("bad_args", "openOrFocus requires arguments");
        return;
      }
      result->Success(
          flutter::EncodableValue(OpenOrFocus(*window_arguments)));
      return;
    }

    result->NotImplemented();
  });
}

bool WindowsVideoPopupManager::OpenOrFocus(
    const std::string& window_arguments) {
  if (popup_window_ && !popup_window_->IsAlive()) {
    popup_window_.reset();
  }

  if (popup_window_) {
    popup_window_->Raise();
    return true;
  }

  auto popup_window =
      std::make_unique<WindowsVideoPopupWindow>(window_arguments);
  if (!popup_window->CreatePopup()) {
    return false;
  }

  popup_window_ = std::move(popup_window);
  return true;
}

void WindowsVideoPopupManager::ForwardDisplayMode(
    const std::string& mode_name) {
  if (main_channel_ == nullptr) {
    return;
  }
  main_channel_->InvokeMethod(
      "setDisplayMode",
      std::make_unique<flutter::EncodableValue>(mode_name));
}
