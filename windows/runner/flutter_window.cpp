#include "flutter_window.h"

#include <optional>
#include <fstream>   // Added for file operations
#include <shlobj.h>  // Added for SHGetFolderPath
#include <windows.h> // Already implicitly included, but good for clarity for SHGetKnownFolderPath
#include <pathcch.h> // Added for PathCchAppend

#include "flutter/generated_plugin_registrant.h"
#include "flutter/encodable_value.h" // Required for flutter::EncodableValue()
#include "flutter/method_result.h"   // Changed from method_result_functions.h

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
  std::wstring log_msg_save = L"SaveWindowPlacement: Entered. Handle value from GetHandle(): ";
  if (handle)
  {
    // Use swprintf for safer pointer to string conversion
    wchar_t buffer[20];
    swprintf(buffer, 20, L"%p", reinterpret_cast<void *>(handle));
    log_msg_save += buffer;
  }
  else
  {
    log_msg_save += L"NULL";
  }
  OutputDebugStringW((log_msg_save + L"\n").c_str());

  if (!handle)
  {
    OutputDebugStringW(L"SaveWindowPlacement: Handle is NULL or invalid, cannot save.\n");
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
      save_file.write(reinterpret_cast<char *>(&wp.rcNormalPosition), sizeof(wp.rcNormalPosition));
      if (save_file.good())
      {
        OutputDebugStringW(L"SaveWindowPlacement: Successfully wrote data to file.\n");
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

bool FlutterWindow::LoadWindowPlacement(Point &origin, Size &size)
{
  std::wstring load_path = GetSavePath();
  OutputDebugStringW((L"LoadWindowPlacement: Attempting to load from: " + load_path + L"\n").c_str());

  if (load_path.empty() || load_path == L"window_placement.dat")
  {
    OutputDebugStringW(L"LoadWindowPlacement: GetSavePath returned empty or fallback path. Not loading from roaming profile.\n");
    return false;
  }

  RECT RLYwindow_rect = {0};
  std::ifstream load_file(load_path, std::ios::binary | std::ios::in);

  if (!load_file.is_open())
  {
    OutputDebugStringW((L"LoadWindowPlacement: Failed to open file: " + load_path + L"\n").c_str());
    return false;
  }

  OutputDebugStringW((L"LoadWindowPlacement: Successfully opened file: " + load_path + L"\n").c_str());

  load_file.read(reinterpret_cast<char *>(&RLYwindow_rect), sizeof(RLYwindow_rect));

  if (load_file.gcount() != sizeof(RLYwindow_rect))
  {
    OutputDebugStringW((L"LoadWindowPlacement: Read " + std::to_wstring(load_file.gcount()) + L" bytes, expected " + std::to_wstring(sizeof(RLYwindow_rect)) + L" bytes.\n").c_str());
    load_file.close();
    return false;
  }
  load_file.close();
  OutputDebugStringW(L"LoadWindowPlacement: Successfully read and closed file.\n");

  std::wstring rect_data_log = L"LoadWindowPlacement: Read RECT data - L:" + std::to_wstring(RLYwindow_rect.left) +
                               L" T:" + std::to_wstring(RLYwindow_rect.top) +
                               L" R:" + std::to_wstring(RLYwindow_rect.right) +
                               L" B:" + std::to_wstring(RLYwindow_rect.bottom) + L"\n";
  OutputDebugStringW(rect_data_log.c_str());

  if (RLYwindow_rect.left == 0 && RLYwindow_rect.top == 0 && RLYwindow_rect.right == 0 && RLYwindow_rect.bottom == 0)
  {
    OutputDebugStringW(L"LoadWindowPlacement: RECT data is all zeros, treating as invalid.\n");
    return false;
  }

  long loaded_width = RLYwindow_rect.right - RLYwindow_rect.left;
  long loaded_height = RLYwindow_rect.bottom - RLYwindow_rect.top;

  std::wstring size_log = L"LoadWindowPlacement: Calculated loaded_width: " + std::to_wstring(loaded_width) + L", loaded_height: " + std::to_wstring(loaded_height) + L"\n";
  OutputDebugStringW(size_log.c_str());

  if (loaded_width > 0 && loaded_height > 0)
  {
    origin.x = RLYwindow_rect.left;
    origin.y = RLYwindow_rect.top;
    size.width = loaded_width;
    size.height = loaded_height;
    OutputDebugStringW(L"LoadWindowPlacement: Successfully validated and applied loaded dimensions.\n");
    return true;
  }
  OutputDebugStringW(L"LoadWindowPlacement: Loaded dimensions are invalid (width/height not positive).\n");
  return false;
}

bool FlutterWindow::Create(const std::wstring &title, const Point &default_origin, const Size &default_size)
{
  Point origin = default_origin;
  Size size = default_size;
  bool loaded_successfully = LoadWindowPlacement(origin, size);

  std::wstring log_msg1 = L"Default origin: (" + std::to_wstring(default_origin.x) + L", " + std::to_wstring(default_origin.y) + L") Default size: (" + std::to_wstring(default_size.width) + L"x" + std::to_wstring(default_size.height) + L")\n";
  OutputDebugStringW(log_msg1.c_str());
  if (loaded_successfully)
  {
    std::wstring log_msg_loaded = L"Loaded origin: (" + std::to_wstring(origin.x) + L", " + std::to_wstring(origin.y) + L") Loaded size: (" + std::to_wstring(size.width) + L"x" + std::to_wstring(size.height) + L")\n";
    OutputDebugStringW(log_msg_loaded.c_str());
  }
  else
  {
    OutputDebugStringW(L"Failed to load window placement, using defaults.\n");
  }

  if (!Win32Window::Create(title, origin, size))
  {
    OutputDebugStringW(L"Win32Window::Create failed.\n");
    return false;
  }
  OutputDebugStringW(L"Win32Window::Create succeeded.\n");

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
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]()
                                                      {
    OutputDebugStringW(L"SetNextFrameCallback: Calling this->Show().\n");
    this->Show();
    OutputDebugStringW(L"SetNextFrameCallback: this->Show() completed.\n");

    if (GetHandle() && flutter_controller_ && flutter_controller_->view()) {
        RECT final_client_rect;
        GetClientRect(GetHandle(), &final_client_rect);
        long final_width = final_client_rect.right - final_client_rect.left;
        long final_height = final_client_rect.bottom - final_client_rect.top;

        std::wstring resize_log = L"SetNextFrameCallback: Resizing Flutter view to: " +
                                std::to_wstring(final_width) + L"x" + std::to_wstring(final_height) + L"\n";
        OutputDebugStringW(resize_log.c_str());

        if (final_width > 0 && final_height > 0) {
            flutter_controller_->view()->Resize(final_width, final_height);
            OutputDebugStringW(L"SetNextFrameCallback: Called Resize. Now calling ForceRedraw().\n");
            flutter_controller_->ForceRedraw();
        } else {
            OutputDebugStringW(L"SetNextFrameCallback: final_width or final_height is not positive. Not resizing/redrawing.\n");
        }
    } else {
        OutputDebugStringW(L"SetNextFrameCallback: Handle or flutter_controller/view is null. Cannot resize/redraw.\n");
    } });

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
  HWND current_handle = GetHandle();
  std::wstring log_msg = L"FlutterWindow::OnDestroy: Entered. Handle value from GetHandle() before SaveWindowPlacement: ";
  if (current_handle)
  {
    wchar_t buffer[20];
    swprintf(buffer, 20, L"%p", reinterpret_cast<void *>(current_handle));
    log_msg += buffer;
  }
  else
  {
    log_msg += L"NULL";
  }
  OutputDebugStringW((log_msg + L"\n").c_str());

  SaveWindowPlacement(); // Save window state before destruction.
  if (flutter_controller_)
  {
    OutputDebugStringW(L"FlutterWindow::OnDestroy: Nullifying flutter_controller_.\n");
    flutter_controller_ = nullptr;
  }
  OutputDebugStringW(L"FlutterWindow::OnDestroy: Calling Win32Window::OnDestroy().\n");
  Win32Window::OnDestroy();
  OutputDebugStringW(L"FlutterWindow::OnDestroy: Exited.\n");
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
