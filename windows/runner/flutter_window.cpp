#include "flutter_window.h"

#include <optional>
#include <cmath>
#include <fstream>   // Added for file operations
#include <shlobj.h>  // Added for SHGetFolderPath
#include <windows.h> // Already implicitly included, but good for clarity for SHGetKnownFolderPath
#include <pathcch.h> // Added for PathCchAppend

#include "flutter/generated_plugin_registrant.h"
#include "desktop_multi_window/desktop_multi_window_plugin.h"
#include "flutter/encodable_value.h" // Required for flutter::EncodableValue()
#include "flutter/method_channel.h"
#include "flutter/method_result.h"   // Changed from method_result_functions.h
#include "flutter/plugin_registrar_windows.h"
#include "flutter/standard_method_codec.h"
#include <flutter_windows.h>
#include "utils.h"

// Forward declaration for USB video plugin registration
extern void UsbVideoCapturePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#pragma comment(lib, "Pathcch.lib") // Link Pathcch.lib

// Custom MethodResult for WM_CLOSE handling
namespace
{
  const flutter::EncodableValue *MapValue(
      const flutter::EncodableMap &map,
      const char *key)
  {
    auto it = map.find(flutter::EncodableValue(key));
    if (it == map.end())
    {
      return nullptr;
    }
    return &it->second;
  }

  std::optional<double> MapNumber(
      const flutter::EncodableMap &map,
      const char *key)
  {
    const auto *value = MapValue(map, key);
    if (value == nullptr)
    {
      return std::nullopt;
    }
    if (const auto *double_value = std::get_if<double>(value))
    {
      return *double_value;
    }
    if (const auto *int_value = std::get_if<int>(value))
    {
      return static_cast<double>(*int_value);
    }
    return std::nullopt;
  }

  bool MapBool(
      const flutter::EncodableMap &map,
      const char *key,
      bool default_value = false)
  {
    const auto *value = MapValue(map, key);
    if (value == nullptr)
    {
      return default_value;
    }
    if (const auto *bool_value = std::get_if<bool>(value))
    {
      return *bool_value;
    }
    return default_value;
  }

  std::wstring MapWideString(
      const flutter::EncodableMap &map,
      const char *key,
      const wchar_t *default_value)
  {
    const auto *value = MapValue(map, key);
    if (value == nullptr)
    {
      return default_value;
    }
    const auto *string_value = std::get_if<std::string>(value);
    if (string_value == nullptr)
    {
      return default_value;
    }
    if (string_value->empty())
    {
      return L"";
    }
    const int length = MultiByteToWideChar(
        CP_UTF8, 0, string_value->c_str(), -1, nullptr, 0);
    if (length <= 0)
    {
      return default_value;
    }
    std::wstring wide(length, L'\0');
    MultiByteToWideChar(
        CP_UTF8, 0, string_value->c_str(), -1, wide.data(), length);
    if (!wide.empty() && wide.back() == L'\0')
    {
      wide.pop_back();
    }
    return wide;
  }

  class WindowControlPlugin : public flutter::Plugin
  {
  public:
    static void RegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar)
    {
      auto view = FlutterDesktopPluginRegistrarGetView(registrar);
      HWND hwnd = view == nullptr ? nullptr : FlutterDesktopViewGetHWND(view);
      HWND root_hwnd = hwnd == nullptr ? nullptr : GetAncestor(hwnd, GA_ROOT);
      auto plugin_registrar =
          flutter::PluginRegistrarManager::GetInstance()
              ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar);

      auto plugin = std::make_unique<WindowControlPlugin>(
          plugin_registrar, root_hwnd);
      plugin_registrar->AddPlugin(std::move(plugin));
    }

    WindowControlPlugin(
        flutter::PluginRegistrarWindows *registrar,
        HWND hwnd)
        : hwnd_(hwnd)
    {
      channel_ =
          std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
              registrar->messenger(),
              "nt_helper/window_control",
              &flutter::StandardMethodCodec::GetInstance());

      channel_->SetMethodCallHandler(
          [this](const auto &call, auto result)
          {
            if (call.method_name() == "raiseCurrentWindow")
            {
              RaiseCurrentWindow();
              result->Success(flutter::EncodableValue(true));
              return;
            }
            if (call.method_name() == "configureVideoPopup")
            {
              const auto *args = std::get_if<flutter::EncodableMap>(
                  call.arguments());
              if (args == nullptr)
              {
                result->Error("bad_args", "configureVideoPopup requires a map");
                return;
              }
              ConfigureVideoPopup(*args);
              result->Success(flutter::EncodableValue(true));
              return;
            }
            if (call.method_name() == "setAlwaysOnTop")
            {
              const auto *args = std::get_if<flutter::EncodableMap>(
                  call.arguments());
              if (args == nullptr)
              {
                result->Error("bad_args", "setAlwaysOnTop requires a map");
                return;
              }
              SetAlwaysOnTop(MapBool(*args, "alwaysOnTop"));
              result->Success(flutter::EncodableValue(true));
              return;
            }
            if (call.method_name() == "getBounds")
            {
              result->Success(flutter::EncodableValue(GetBounds()));
              return;
            }
            result->NotImplemented();
          });
    }

  private:
    double ScaleFactor()
    {
      if (hwnd_ == nullptr)
      {
        return 1.0;
      }
      const HMODULE user32_module = LoadLibraryA("User32.dll");
      if (user32_module)
      {
        typedef UINT(WINAPI * GetDpiForWindowProc)(HWND hwnd);
        auto get_dpi_for_window =
            reinterpret_cast<GetDpiForWindowProc>(
                GetProcAddress(user32_module, "GetDpiForWindow"));
        if (get_dpi_for_window != nullptr)
        {
          const UINT dpi = get_dpi_for_window(hwnd_);
          FreeLibrary(user32_module);
          if (dpi > 0)
          {
            return static_cast<double>(dpi) / 96.0;
          }
          return 1.0;
        }
        FreeLibrary(user32_module);
      }
      return 1.0;
    }

    int LogicalToPhysical(double value)
    {
      return static_cast<int>(std::round(value * ScaleFactor()));
    }

    double PhysicalToLogical(int value)
    {
      return static_cast<double>(value) / ScaleFactor();
    }

    void ConfigureVideoPopup(const flutter::EncodableMap &args)
    {
      if (hwnd_ == nullptr)
      {
        return;
      }

      const auto title = MapWideString(args, "title", L"Disting NT Video");
      SetWindowText(hwnd_, title.c_str());

      const int width = LogicalToPhysical(
          MapNumber(args, "width").value_or(256.0));
      const int height = LogicalToPhysical(
          MapNumber(args, "height").value_or(100.0));
      const auto x = MapNumber(args, "x");
      const auto y = MapNumber(args, "y");

      int left = x.has_value() ? LogicalToPhysical(*x) : 0;
      int top = y.has_value() ? LogicalToPhysical(*y) : 0;
      if (MapBool(args, "center", false))
      {
        HMONITOR monitor = MonitorFromWindow(hwnd_, MONITOR_DEFAULTTONEAREST);
        MONITORINFO monitor_info;
        monitor_info.cbSize = sizeof(MONITORINFO);
        if (GetMonitorInfo(monitor, &monitor_info))
        {
          const RECT work = monitor_info.rcWork;
          left = work.left + ((work.right - work.left) - width) / 2;
          top = work.top + ((work.bottom - work.top) - height) / 2;
        }
      }

      SetWindowPos(
          hwnd_, nullptr, left, top, width, height,
          SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOACTIVATE);
      SetAlwaysOnTop(MapBool(args, "alwaysOnTop", false));
      RaiseCurrentWindow();
    }

    void SetAlwaysOnTop(bool always_on_top)
    {
      if (hwnd_ == nullptr)
      {
        return;
      }
      SetWindowPos(
          hwnd_,
          always_on_top ? HWND_TOPMOST : HWND_NOTOPMOST,
          0,
          0,
          0,
          0,
          SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }

    flutter::EncodableMap GetBounds()
    {
      flutter::EncodableMap result;
      if (hwnd_ == nullptr)
      {
        return result;
      }
      RECT rect;
      if (!GetWindowRect(hwnd_, &rect))
      {
        return result;
      }
      result[flutter::EncodableValue("x")] =
          flutter::EncodableValue(PhysicalToLogical(rect.left));
      result[flutter::EncodableValue("y")] =
          flutter::EncodableValue(PhysicalToLogical(rect.top));
      result[flutter::EncodableValue("width")] =
          flutter::EncodableValue(PhysicalToLogical(rect.right - rect.left));
      result[flutter::EncodableValue("height")] =
          flutter::EncodableValue(PhysicalToLogical(rect.bottom - rect.top));
      return result;
    }

    void RaiseCurrentWindow()
    {
      if (hwnd_ == nullptr)
      {
        return;
      }

      ShowWindow(hwnd_, SW_SHOWNORMAL);
      SetWindowPos(
          hwnd_, HWND_TOP, 0, 0, 0, 0,
          SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);
      BringWindowToTop(hwnd_);

      HWND foreground_window = GetForegroundWindow();
      DWORD foreground_thread_id =
          foreground_window == nullptr
              ? 0
              : GetWindowThreadProcessId(foreground_window, nullptr);
      DWORD current_thread_id = GetCurrentThreadId();
      const bool attached =
          foreground_thread_id != 0 && foreground_thread_id != current_thread_id &&
          AttachThreadInput(foreground_thread_id, current_thread_id, TRUE);

      SetForegroundWindow(hwnd_);
      SetActiveWindow(hwnd_);
      HWND child = GetWindow(hwnd_, GW_CHILD);
      if (child != nullptr)
      {
        SetFocus(child);
      }

      if (attached)
      {
        AttachThreadInput(foreground_thread_id, current_thread_id, FALSE);
      }
    }

    HWND hwnd_;
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  };

  class WindowCloseResult : public flutter::MethodResult<flutter::EncodableValue>
  {
  public:
    explicit WindowCloseResult(HWND hwnd) : hwnd_(hwnd) {}
    ~WindowCloseResult() override = default;

  protected:
    void SuccessInternal(const flutter::EncodableValue *result) override
    {
      PostMessage(hwnd_, WM_DESTROY, 0, 0);
    }

    void ErrorInternal(const std::string &error_code,
                       const std::string &error_message,
                       const flutter::EncodableValue *error_details) override
    {
      // Optionally log the error
      PostMessage(hwnd_, WM_DESTROY, 0, 0);
    }

    void NotImplementedInternal() override
    {
      // Fallback if Dart side doesn't implement 'windowWillClose'
      PostMessage(hwnd_, WM_DESTROY, 0, 0);
    }

  private:
    HWND hwnd_;
  };
} // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow()
{
  // Ensure placement is saved if OnDestroy wasn't called or if it's safer here.
  // However, OnDestroy is the more idiomatic place.
  // If SaveWindowPlacement() is called in OnDestroy, this might be redundant
  // unless there are paths where OnDestroy isn't hit before handle invalidation.
  // For now, relying on OnDestroy.
}

// Helper function to get a settings file path in AppData
std::wstring FlutterWindow::GetSavePath()
{
  PWSTR path_app_data = nullptr;
  if (FAILED(SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, NULL, &path_app_data)))
  {
    StartupLog(L"GetSavePath: SHGetKnownFolderPath FAILED. Falling back to local file window_placement.dat");
    return L"window_placement.dat";
  }

  std::wstring base_path(path_app_data);
  CoTaskMemFree(path_app_data);

  // Path structure: AppData\Roaming\VendorName\AppName\file.dat
  // Adjust VendorName and AppName as per your application's identifier structure.
  // For com.example.nt_helper, using "com.example" as vendor and "nt_helper" as app.
  std::wstring vendor_dir_name = L"com.example";
  std::wstring app_dir_name = L"nt_helper";

  std::wstring final_path = base_path;

  // Append and create vendor directory
  final_path += (L"\\" + vendor_dir_name);
  if (!(CreateDirectory(final_path.c_str(), NULL) || GetLastError() == ERROR_ALREADY_EXISTS))
  {
    StartupLog(L"GetSavePath: Failed to create/access vendor directory: " + final_path + L". Falling back.");
    return L"window_placement.dat";
  }

  // Append and create app directory
  final_path += (L"\\" + app_dir_name);
  if (!(CreateDirectory(final_path.c_str(), NULL) || GetLastError() == ERROR_ALREADY_EXISTS))
  {
    StartupLog(L"GetSavePath: Failed to create/access app directory: " + final_path + L". Falling back.");
    return L"window_placement.dat";
  }

  final_path += L"\\window_placement.dat";
  StartupLog(L"GetSavePath: Using path: " + final_path);
  return final_path;
}

void FlutterWindow::SaveWindowPlacement()
{
  HWND handle = GetHandle();
  if (!handle)
  {
    StartupLog(L"SaveWindowPlacement: Invalid window handle, cannot save.");
    return;
  }

  WINDOWPLACEMENT wp = {sizeof(wp)};
  if (GetWindowPlacement(handle, &wp))
  {
    std::wstring save_path = GetSavePath();
    StartupLog(L"SaveWindowPlacement: Attempting to save to: " + save_path);

    if (save_path.empty() || save_path == L"window_placement.dat")
    {
      StartupLog(L"SaveWindowPlacement: GetSavePath returned empty or fallback path, cannot save to roaming profile.");
      if (save_path.empty())
        return;
    }

    std::ofstream save_file(save_path, std::ios::binary | std::ios::out);
    if (save_file.is_open())
    {
      // Save the entire WINDOWPLACEMENT structure for proper restore with SetWindowPlacement
      save_file.write(reinterpret_cast<char *>(&wp), sizeof(wp));
      if (save_file.good())
      {
        StartupLog(L"SaveWindowPlacement: Successfully wrote WINDOWPLACEMENT to file.");
      }
      else
      {
        StartupLog(L"SaveWindowPlacement: Failed to write data to file.");
      }
      save_file.close();
    }
    else
    {
      StartupLog(L"SaveWindowPlacement: Failed to open file for writing: " + save_path);
    }
  }
  else
  {
    StartupLogLastError(L"SaveWindowPlacement: GetWindowPlacement failed.");
  }
}

bool FlutterWindow::RestoreWindowPlacement()
{
  HWND handle = GetHandle();
  if (!handle)
  {
    StartupLog(L"RestoreWindowPlacement: Invalid window handle.");
    return false;
  }

  std::wstring load_path = GetSavePath();
  StartupLog(L"RestoreWindowPlacement: Attempting to load from: " + load_path);

  if (load_path.empty() || load_path == L"window_placement.dat")
  {
    StartupLog(L"RestoreWindowPlacement: GetSavePath returned empty or fallback path.");
    return false;
  }

  std::ifstream load_file(load_path, std::ios::binary | std::ios::in);
  if (!load_file.is_open())
  {
    StartupLog(L"RestoreWindowPlacement: Failed to open file: " + load_path);
    return false;
  }

  WINDOWPLACEMENT wp = {sizeof(wp)};
  load_file.read(reinterpret_cast<char *>(&wp), sizeof(wp));

  if (load_file.gcount() != sizeof(wp))
  {
    StartupLog(L"RestoreWindowPlacement: Read " + std::to_wstring(load_file.gcount()) + L" bytes, expected " + std::to_wstring(sizeof(wp)) + L" bytes.");
    load_file.close();
    return false;
  }
  load_file.close();

  // Validate the loaded placement
  long width = wp.rcNormalPosition.right - wp.rcNormalPosition.left;
  long height = wp.rcNormalPosition.bottom - wp.rcNormalPosition.top;

  if (width <= 0 || height <= 0)
  {
    StartupLog(L"RestoreWindowPlacement: Invalid dimensions in saved placement.");
    return false;
  }

  // Ensure the length field is correct (in case of version mismatch)
  wp.length = sizeof(wp);

  // Force window to stay hidden - window_manager will show it from Dart when Flutter is ready
  // This prevents the white flash before Flutter content renders
  wp.showCmd = SW_HIDE;

  // Use SetWindowPlacement to restore - this handles coordinate systems correctly
  if (SetWindowPlacement(handle, &wp))
  {
    std::wstring log = L"RestoreWindowPlacement: Successfully restored window to (" +
                       std::to_wstring(wp.rcNormalPosition.left) + L", " +
                       std::to_wstring(wp.rcNormalPosition.top) + L") size " +
                       std::to_wstring(width) + L"x" + std::to_wstring(height);
    StartupLog(log);
    return true;
  }
  else
  {
    StartupLogLastError(L"RestoreWindowPlacement: SetWindowPlacement failed.");
    return false;
  }
}

bool FlutterWindow::Create(const std::wstring &title, const Point &default_origin, const Size &default_size)
{
  // Always create window with default position/size first
  if (!Win32Window::Create(title, default_origin, default_size))
  {
    StartupLog(L"Win32Window::Create failed.");
    return false;
  }
  StartupLog(L"Win32Window::Create succeeded.");

  // Now restore saved window placement using SetWindowPlacement
  // This properly handles coordinate systems, DPI, and multi-monitor setups
  if (!RestoreWindowPlacement())
  {
    StartupLog(L"No saved placement found or restore failed, using defaults.");
  }

  RECT frame = GetClientArea();
  long view_width = frame.right - frame.left;
  long view_height = frame.bottom - frame.top;

  std::wstring log_msg2 = L"GetClientArea after Win32Window::Create: (" + std::to_wstring(view_width) + L"x" + std::to_wstring(view_height) + L")";
  StartupLog(log_msg2);

  if (view_width <= 0 || view_height <= 0)
  {
    std::wstring log_msg_fallback = L"Warning: Window client area is zero or negative. Falling back to default Flutter view size: (" + std::to_wstring(default_size.width) + L"x" + std::to_wstring(default_size.height) + L")";
    StartupLog(log_msg_fallback);
    view_width = default_size.width;
    view_height = default_size.height;
  }

  std::wstring log_msg3 = L"Creating FlutterViewController with size: (" + std::to_wstring(view_width) + L"x" + std::to_wstring(view_height) + L")";
  StartupLog(log_msg3);

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      view_width, view_height, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view())
  {
    StartupLog(L"FlutterViewController setup failed.");
    return false;
  }
  StartupLog(L"FlutterViewController setup succeeded.");

  window_events_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.nt_helper.app/window_events",
          &flutter::StandardMethodCodec::GetInstance());

  StartupLog(L"Registering Flutter plugins");
  RegisterPlugins(flutter_controller_->engine());
  WindowControlPlugin::RegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("WindowControlPlugin"));
  StartupLog(L"Flutter plugins registered");

  // Register USB video capture plugin
  StartupLog(L"Registering USB video capture plugin");
  UsbVideoCapturePluginRegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("UsbVideoCapturePlugin"));
  StartupLog(L"USB video capture plugin registered");

  DesktopMultiWindowSetWindowCreatedCallback([](void *controller) {
    auto *flutter_view_controller =
        reinterpret_cast<flutter::FlutterViewController *>(controller);
    auto *registry = flutter_view_controller->engine();
    RegisterPlugins(registry);
    WindowControlPlugin::RegisterWithRegistrar(
        registry->GetRegistrarForPlugin("WindowControlPlugin"));
    UsbVideoCapturePluginRegisterWithRegistrar(
        registry->GetRegistrarForPlugin("UsbVideoCapturePlugin"));
  });

  StartupLog(L"Attaching Flutter view native window");
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Note: Window showing is handled by window_manager plugin in Dart code.
  // Do NOT call this->Show() here - it would show the window before Flutter renders.
  flutter_controller_->ForceRedraw();

  return true;
}

bool FlutterWindow::OnCreate()
{
  // This method is now largely superseded by the logic in FlutterWindow::Create.
  // If Win32Window::OnCreate is called by Win32Window::Create, it might still be hit.
  // For safety, ensure it doesn't conflict.
  // The base Win32Window::OnCreate is empty, so calling it is fine.
  // If it was crucial, its content would need to be merged into FlutterWindow::Create.
  // For now, we'll assume its original content (if any beyond calling base) has been
  // moved into the new FlutterWindow::Create method.
  // The current Win32Window::OnCreate() is a no-op, so this is fine.
  return Win32Window::OnCreate();
}

void FlutterWindow::OnDestroy()
{
  // Note: Window placement is saved in WM_CLOSE handler, not here.
  // By the time OnDestroy is called, the window handle is already null.
  if (flutter_controller_)
  {
    flutter_controller_ = nullptr;
  }
  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept
{
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_)
  {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result)
    {
      return *result;
    }
  }

  // Handle WM_CLOSE specifically to notify Dart and wait for confirmation.
  if (message == WM_CLOSE)
  {
    // Save window placement NOW, while handle is still valid.
    // OnDestroy is too late - the handle gets nullified before it's called.
    SaveWindowPlacement();

    if (window_events_channel_)
    {
      HWND main_hwnd = GetHandle();
      auto result_handler = std::make_unique<WindowCloseResult>(main_hwnd);

      window_events_channel_->InvokeMethod(
          "windowWillClose",
          std::make_unique<flutter::EncodableValue>(), // Arguments
          std::move(result_handler)                    // The result handler
      );

      return 0; // Crucial: Indicate that we've handled WM_CLOSE.
    }
    // If channel is null, it will fall through to Win32Window::MessageHandler
  }

  switch (message)
  {
  case WM_FONTCHANGE:
    if (flutter_controller_ && flutter_controller_->engine())
    { // Add null check for engine
      flutter_controller_->engine()->ReloadSystemFonts();
    }
    break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
