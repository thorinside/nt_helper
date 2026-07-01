#ifndef RUNNER_WINDOWS_VIDEO_POPUP_MANAGER_H_
#define RUNNER_WINDOWS_VIDEO_POPUP_MANAGER_H_

#include <flutter/encodable_value.h>
#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <string>

class WindowsVideoPopupWindow;

class WindowsVideoPopupManager {
 public:
  static WindowsVideoPopupManager& Instance();

  void RegisterMainEngine(flutter::FlutterEngine* engine, HWND main_window);

 private:
  WindowsVideoPopupManager() = default;
  ~WindowsVideoPopupManager() = default;

  WindowsVideoPopupManager(const WindowsVideoPopupManager&) = delete;
  WindowsVideoPopupManager& operator=(const WindowsVideoPopupManager&) = delete;

  bool OpenOrFocus(const std::string& window_arguments);
  void ForwardDisplayMode(const std::string& mode_name);

  friend class WindowsVideoPopupWindow;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      main_channel_;
  std::unique_ptr<WindowsVideoPopupWindow> popup_window_;
  HWND main_window_ = nullptr;
};

#endif  // RUNNER_WINDOWS_VIDEO_POPUP_MANAGER_H_
