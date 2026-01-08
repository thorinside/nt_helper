#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>        // Added for MethodChannel
#include <flutter/standard_method_codec.h> // Added for MethodChannel

#include <memory>
#include <string> // Added for std::wstring

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window
{
public:
    // Creates a new FlutterWindow hosting a Flutter view running |project|.
    explicit FlutterWindow(const flutter::DartProject &project);
    virtual ~FlutterWindow();

    // Creates the window but first attempts to load saved placement.
    // Overrides the base class method implicitly if not an exact signature match.
    // We will define this in the .cpp file.
    bool Create(const std::wstring &title, const Point &default_origin, const Size &default_size);

protected:
    // Win32Window:
    bool OnCreate() override;
    void OnDestroy() override;
    LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                           LPARAM const lparam) noexcept override;

private:
    // The project to run.
    flutter::DartProject project_;

    // The Flutter instance hosted by this window.
    std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

    // Method channel for window events.
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
        window_events_channel_;

    // Helper to get path for settings file
    std::wstring GetSavePath();

    // Methods for saving and restoring window placement
    void SaveWindowPlacement();
    bool RestoreWindowPlacement();
};

#endif // RUNNER_FLUTTER_WINDOW_H_
