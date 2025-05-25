#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "flutter/encodable_value.h" // Required for flutter::EncodableValue()

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
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

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  // Handle WM_CLOSE specifically to notify Dart and wait for confirmation.
  if (message == WM_CLOSE) {
    if (window_events_channel_) {
      OutputDebugString(L"C++: WM_CLOSE received. Invoking 'windowWillClose' on Dart and waiting for result.\n");
      
      HWND main_hwnd = GetHandle(); // Get the HWND for PostMessage

      window_events_channel_->InvokeMethod(
          "windowWillClose",
          std::make_unique<flutter::EncodableValue>(), // nullptr equivalent
          [main_hwnd](const flutter::EncodableValue* result) { // Success callback
              OutputDebugString(L"C++: Dart 'windowWillClose' handler completed successfully.\n");
              PostMessage(main_hwnd, WM_DESTROY, 0, 0);
          },
          [main_hwnd](const std::string& error_code, const std::string& error_message, const flutter::EncodableValue* error_details) { // Error callback
              OutputDebugString(L"C++: Dart 'windowWillClose' handler failed. Forcing close.\n");
              // TODO: Log error_code, error_message if desired.
              PostMessage(main_hwnd, WM_DESTROY, 0, 0);
          });
      
      return 0; // Crucial: Indicate that we've handled WM_CLOSE.
                  // Prevents DefWindowProc from processing it and closing the window immediately.
    } else {
      OutputDebugString(L"C++: WM_CLOSE received, but MethodChannel is null. Proceeding with default close.\n");
      // Fall through to default handling if channel is not available
      // This will call Win32Window::MessageHandler below.
    }
    // If channel was null, we reach here and then the default handler outside the if/else.
    // If channel was not null, we returned 0.
  }

  // The base class's message handler will be called for other messages,
  // or if WM_CLOSE was received but the channel was null.
  // WM_DESTROY will also be handled by this, which should lead to PostQuitMessage.
  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    // WM_DESTROY is handled by the default Win32Window::MessageHandler below.
    // No specific FlutterWindow cleanup needed for WM_DESTROY beyond what Win32Window does.
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
