#include "flutter_window.h"

#include <optional>
#include <fstream>   // Added for file operations
#include <shlobj.h>  // Added for SHGetFolderPath
#include <windows.h> // Already implicitly included, but good for clarity for SHGetKnownFolderPath
#include <pathcch.h> // Added for PathCchAppend

#include "flutter/generated_plugin_registrant.h"
#include "flutter/encodable_value.h"         // Required for flutter::EncodableValue()
#include "flutter/method_result_functions.h" // Required for custom MethodResult

#pragma comment(lib, "Pathcch.lib") // Link Pathcch.lib

// Custom MethodResult for WM_CLOSE handling
namespace
{
  class WindowCloseResult : public flutter::MethodResult<flutter::EncodableValue>
  {
  public:
    explicit WindowCloseResult(HWND hwnd) : hwnd_(hwnd) {}
    ~WindowCloseResult() override = default;

    void Success(const flutter::EncodableValue *result) override
    {
      PostMessage(hwnd_, WM_DESTROY, 0, 0);
    }
    void Error(const std::string &error_code,
               const std::string &error_message,
               const flutter::EncodableValue *error_details) override
    {
      // Optionally log the error
      PostMessage(hwnd_, WM_DESTROY, 0, 0);
    }
    void NotImplemented() override
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
  // Roaming app data is usually best for user-specific settings that should roam.
  // Use FOLDERID_LocalAppData for local-machine only settings if preferred.
  if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, NULL, &path_app_data)))
  {
    std::wstring save_path_str(path_app_data);
    CoTaskMemFree(path_app_data); // Free the memory allocated by SHGetKnownFolderPath

    // Append your application's folder and filename
    std::wstring app_folder_name = L"\\nt_helper_settings"; // Using nt_helper_settings
    std::wstring app_folder_path = save_path_str + app_folder_name;

    // Create the directory if it doesn't exist.
    // CreateDirectory returns 0 on failure, non-zero on success (or if already exists).
    // We don't strictly need to check the return for this simple case,
    // as fstream will fail gracefully if the path is invalid.
    CreateDirectory(app_folder_path.c_str(), NULL);

    std::wstring file_path = app_folder_path + L"\\window_placement.dat";
    return file_path;
  }
  // Fallback or error: return empty or a local path.
  // For simplicity, returning a local path. A more robust solution would log an error.
  return L"window_placement.dat";
}

void FlutterWindow::SaveWindowPlacement()
{
  HWND handle = GetHandle();
  if (!handle)
    return; // Don't try to save if the handle is invalid

  WINDOWPLACEMENT wp = {sizeof(wp)};
  if (GetWindowPlacement(handle, &wp))
  {
    std::wstring save_path = GetSavePath();
    if (save_path.empty())
      return; // Could not determine save path

    std::ofstream save_file(save_path, std::ios::binary | std::ios::out);
    if (save_file.is_open())
    {
      // We only care about the normal position, not minimized/maximized specifics for simple restore.
      save_file.write(reinterpret_cast<char *>(&wp.rcNormalPosition), sizeof(wp.rcNormalPosition));
      save_file.close();
    }
  }
}

bool FlutterWindow::LoadWindowPlacement(Point &origin, Size &size)
{
  std::wstring load_path = GetSavePath();
  if (load_path.empty())
    return false;

  RECT RLYwindow_rect = {0}; // Renamed to avoid conflict
  std::ifstream load_file(load_path, std::ios::binary | std::ios::in);
  if (load_file.is_open())
  {
    load_file.read(reinterpret_cast<char *>(&RLYwindow_rect), sizeof(RLYwindow_rect));
    load_file.close();

    // Basic validation: ensure width and height are positive.
    // Also check for extremely small or large values if necessary.
    if (RLYwindow_rect.left == 0 && RLYwindow_rect.top == 0 && RLYwindow_rect.right == 0 && RLYwindow_rect.bottom == 0)
    {
      // File might exist but be empty or invalid from a previous error.
      return false;
    }

    long loaded_width = RLYwindow_rect.right - RLYwindow_rect.left;
    long loaded_height = RLYwindow_rect.bottom - RLYwindow_rect.top;

    if (loaded_width > 0 && loaded_height > 0)
    {
      // Optional: Add checks for reasonable min/max dimensions,
      // or ensure it's on a visible monitor.
      // For now, accept any valid positive size.
      origin.x = RLYwindow_rect.left;
      origin.y = RLYwindow_rect.top;
      size.width = loaded_width;
      size.height = loaded_height;
      return true;
    }
  }
  return false;
}

bool FlutterWindow::Create(const std::wstring &title, const Point &default_origin, const Size &default_size)
{
  Point origin = default_origin;
  Size size = default_size;

  // Attempt to load saved placement. If successful, 'origin' and 'size' will be updated.
  LoadWindowPlacement(origin, size);

  // Now call the base Win32Window::Create with the determined origin and size
  if (!Win32Window::Create(title, origin, size))
  {
    return false; // Base creation failed
  }

  // The rest is similar to the original OnCreate logic,
  // now part of this overridden Create method.
  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view())
  {
    return false; // Flutter controller setup failed
  }

  window_events_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.nt_helper.app/window_events",
          &flutter::StandardMethodCodec::GetInstance());

  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]()
                                                      { this->Show(); });
  flutter_controller_->ForceRedraw();

  return true; // Successfully created and initialized Flutter
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
  SaveWindowPlacement(); // Save window state before destruction.
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
