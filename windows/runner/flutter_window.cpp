#include "flutter_window.h"

#include <optional>
#include <fstream>   // Added for file operations
#include <shlobj.h>  // Added for SHGetFolderPath
#include <windows.h> // Already implicitly included, but good for clarity for SHGetKnownFolderPath
#include <pathcch.h> // Added for PathCchAppend

#include "flutter/generated_plugin_registrant.h"
#include "flutter/encodable_value.h" // Required for flutter::EncodableValue()
#include "flutter/method_result.h"   // Changed from method_result_functions.h

// Forward declaration for USB video plugin registration
extern void UsbVideoCapturePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#pragma comment(lib, "Pathcch.lib") // Link Pathcch.lib

// Custom MethodResult for WM_CLOSE handling
namespace
{
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
    OutputDebugStringW(L"GetSavePath: SHGetKnownFolderPath FAILED. Falling back to local file window_placement.dat\n");
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
    OutputDebugStringW((L"GetSavePath: Failed to create/access vendor directory: " + final_path + L". Falling back.\n").c_str());
    return L"window_placement.dat";
  }

  // Append and create app directory
  final_path += (L"\\" + app_dir_name);
  if (!(CreateDirectory(final_path.c_str(), NULL) || GetLastError() == ERROR_ALREADY_EXISTS))
  {
    OutputDebugStringW((L"GetSavePath: Failed to create/access app directory: " + final_path + L". Falling back.\n").c_str());
    return L"window_placement.dat";
  }

  final_path += L"\\window_placement.dat";
  OutputDebugStringW((L"GetSavePath: Using path: " + final_path + L"\n").c_str());
  return final_path;
}

void FlutterWindow::SaveWindowPlacement()
{
  HWND handle = GetHandle();
  if (!handle)
  {
    OutputDebugStringW(L"SaveWindowPlacement: Invalid window handle, cannot save.\n");
    return;
  }

  WINDOWPLACEMENT wp = {sizeof(wp)};
  if (GetWindowPlacement(handle, &wp))
  {
    std::wstring save_path = GetSavePath();
    OutputDebugStringW((L"SaveWindowPlacement: Attempting to save to: " + save_path + L"\n").c_str());

    if (save_path.empty() || save_path == L"window_placement.dat")
    {
      OutputDebugStringW(L"SaveWindowPlacement: GetSavePath returned empty or fallback path, cannot save to roaming profile.\n");
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
        OutputDebugStringW(L"SaveWindowPlacement: Successfully wrote WINDOWPLACEMENT to file.\n");
      }
      else
      {
        OutputDebugStringW(L"SaveWindowPlacement: Failed to write data to file.\n");
      }
      save_file.close();
    }
    else
    {
      OutputDebugStringW((L"SaveWindowPlacement: Failed to open file for writing: " + save_path + L"\n").c_str());
    }
  }
  else
  {
    OutputDebugStringW(L"SaveWindowPlacement: GetWindowPlacement failed.\n");
  }
}

bool FlutterWindow::RestoreWindowPlacement()
{
  HWND handle = GetHandle();
  if (!handle)
  {
    OutputDebugStringW(L"RestoreWindowPlacement: Invalid window handle.\n");
    return false;
  }

  std::wstring load_path = GetSavePath();
  OutputDebugStringW((L"RestoreWindowPlacement: Attempting to load from: " + load_path + L"\n").c_str());

  if (load_path.empty() || load_path == L"window_placement.dat")
  {
    OutputDebugStringW(L"RestoreWindowPlacement: GetSavePath returned empty or fallback path.\n");
    return false;
  }

  std::ifstream load_file(load_path, std::ios::binary | std::ios::in);
  if (!load_file.is_open())
  {
    OutputDebugStringW((L"RestoreWindowPlacement: Failed to open file: " + load_path + L"\n").c_str());
    return false;
  }

  WINDOWPLACEMENT wp = {sizeof(wp)};
  load_file.read(reinterpret_cast<char *>(&wp), sizeof(wp));

  if (load_file.gcount() != sizeof(wp))
  {
    OutputDebugStringW((L"RestoreWindowPlacement: Read " + std::to_wstring(load_file.gcount()) + L" bytes, expected " + std::to_wstring(sizeof(wp)) + L" bytes.\n").c_str());
    load_file.close();
    return false;
  }
  load_file.close();

  // Validate the loaded placement
  long width = wp.rcNormalPosition.right - wp.rcNormalPosition.left;
  long height = wp.rcNormalPosition.bottom - wp.rcNormalPosition.top;

  if (width <= 0 || height <= 0)
  {
    OutputDebugStringW(L"RestoreWindowPlacement: Invalid dimensions in saved placement.\n");
    return false;
  }

  // Ensure the length field is correct (in case of version mismatch)
  wp.length = sizeof(wp);

  // Use SetWindowPlacement to restore - this handles coordinate systems correctly
  if (SetWindowPlacement(handle, &wp))
  {
    std::wstring log = L"RestoreWindowPlacement: Successfully restored window to (" +
                       std::to_wstring(wp.rcNormalPosition.left) + L", " +
                       std::to_wstring(wp.rcNormalPosition.top) + L") size " +
                       std::to_wstring(width) + L"x" + std::to_wstring(height) + L"\n";
    OutputDebugStringW(log.c_str());
    return true;
  }
  else
  {
    OutputDebugStringW(L"RestoreWindowPlacement: SetWindowPlacement failed.\n");
    return false;
  }
}

bool FlutterWindow::Create(const std::wstring &title, const Point &default_origin, const Size &default_size)
{
  // Always create window with default position/size first
  if (!Win32Window::Create(title, default_origin, default_size))
  {
    OutputDebugStringW(L"Win32Window::Create failed.\n");
    return false;
  }
  OutputDebugStringW(L"Win32Window::Create succeeded.\n");

  // Now restore saved window placement using SetWindowPlacement
  // This properly handles coordinate systems, DPI, and multi-monitor setups
  if (!RestoreWindowPlacement())
  {
    OutputDebugStringW(L"No saved placement found or restore failed, using defaults.\n");
  }

  RECT frame = GetClientArea();
  long view_width = frame.right - frame.left;
  long view_height = frame.bottom - frame.top;

  std::wstring log_msg2 = L"GetClientArea after Win32Window::Create: (" + std::to_wstring(view_width) + L"x" + std::to_wstring(view_height) + L")\n";
  OutputDebugStringW(log_msg2.c_str());

  if (view_width <= 0 || view_height <= 0)
  {
    std::wstring log_msg_fallback = L"Warning: Window client area is zero or negative. Falling back to default Flutter view size: (" + std::to_wstring(default_size.width) + L"x" + std::to_wstring(default_size.height) + L")\n";
    OutputDebugStringW(log_msg_fallback.c_str());
    view_width = default_size.width;
    view_height = default_size.height;
  }

  std::wstring log_msg3 = L"Creating FlutterViewController with size: (" + std::to_wstring(view_width) + L"x" + std::to_wstring(view_height) + L")\n";
  OutputDebugStringW(log_msg3.c_str());

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      view_width, view_height, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view())
  {
    OutputDebugStringW(L"FlutterViewController setup failed.\n");
    return false;
  }
  OutputDebugStringW(L"FlutterViewController setup succeeded.\n");

  window_events_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.nt_helper.app/window_events",
          &flutter::StandardMethodCodec::GetInstance());

  RegisterPlugins(flutter_controller_->engine());

  // Register USB video capture plugin
  UsbVideoCapturePluginRegisterWithRegistrar(
      flutter_controller_->engine()->GetRegistrarForPlugin("UsbVideoCapturePlugin"));

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]()
                                                      {
    OutputDebugStringW(L"SetNextFrameCallback: Calling this->Show().\n");
    RECT client_rect_before_show;
    if (GetHandle()) { // Ensure handle is valid before calling GetClientRect
        GetClientRect(GetHandle(), &client_rect_before_show);
        std::wstring log_msg_show = L"Client RECT before ShowWindow: " +
            std::to_wstring(client_rect_before_show.right - client_rect_before_show.left) + L"x" +
            std::to_wstring(client_rect_before_show.bottom - client_rect_before_show.top) + L"\n";
        OutputDebugStringW(log_msg_show.c_str());
    }
    this->Show(); });
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
