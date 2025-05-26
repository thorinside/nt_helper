#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "flutter/encodable_value.h" // Required for flutter::EncodableValue()

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate()
{
  if (!Win32Window::OnCreate())
  {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view())
  {
    return false;
  }

  // Initialize the MethodChannel
  window_events_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "com.nt_helper.app/window_events",
          &flutter::StandardMethodCodec::GetInstance());

  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]()
                                                      { this->Show(); });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy()
{
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
    // Show a confirmation dialog.
    if (MessageBox(hwnd, L"Are you sure you want to quit?", L"Confirm Close",
                   MB_YESNO | MB_ICONQUESTION) == IDYES)
    {
      HWND main_hwnd = hwnd; // Capture for use in lambdas

      // Prepare MethodResult handler
      auto result_handler = std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
          [main_hwnd](const flutter::EncodableValue *result) { // Success
            // The Dart side might return true/false, but we close regardless.
            // This callback mainly confirms the method was invoked.
            PostMessage(main_hwnd, WM_DESTROY, 0, 0);
          },
          [main_hwnd](const std::string &error_code,
                      const std::string &error_message,
                      const flutter::EncodableValue *error_details) { // Error
            // Log an error if desired, then close.
            // Example: OutputDebugStringA(("Error invoking windowWillClose: " + error_code + " - " + error_message + "\\n").c_str());
            PostMessage(main_hwnd, WM_DESTROY, 0, 0);
          },
          [main_hwnd]() { // Not Implemented
            // Log if desired, then close.
            // Example: OutputDebugStringA("windowWillClose not implemented on Dart side.\\n");
            PostMessage(main_hwnd, WM_DESTROY, 0, 0);
          });

      if (window_events_channel_)
      {
        window_events_channel_->InvokeMethod(
            "windowWillClose",
            nullptr, // No arguments being sent to Dart
            std::move(result_handler));
      }
      else
      {
        // Fallback if channel is somehow null, though it shouldn't be
        PostMessage(main_hwnd, WM_DESTROY, 0, 0);
      }
    }
    return 0; // We've handled WM_CLOSE.
  }

  // The base class's message handler will be called for other messages,
  // or if WM_CLOSE was received but the channel was null.
  // WM_DESTROY will also be handled by this, which should lead to PostQuitMessage.
  switch (message)
  {
  case WM_FONTCHANGE:
    flutter_controller_->engine()->ReloadSystemFonts();
    break;
    // WM_DESTROY is handled by the default Win32Window::MessageHandler below.
    // No specific FlutterWindow cleanup needed for WM_DESTROY beyond what Win32Window does.
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
