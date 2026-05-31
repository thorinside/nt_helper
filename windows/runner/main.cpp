#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <cstring>
#include <exception>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command)
{
  StartupLog(L"wWinMain entered");
  StartupLog(L"Command line: " + std::wstring(GetCommandLineW()));

  try
  {
    // Attach to console when present (e.g., 'flutter run') or create a
    // new console when running with a debugger.
    if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent())
    {
      StartupLog(L"Creating debugger console");
      CreateAndAttachConsole();
    }

    // Initialize COM, so that it is available for use in the library and/or
    // plugins.
    HRESULT com_result = ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    StartupLog(L"CoInitializeEx result: " + std::to_wstring(com_result));

    StartupLog(L"Creating DartProject from data directory");
    flutter::DartProject project(L"data");

    std::vector<std::string> command_line_arguments =
        GetCommandLineArguments();
    StartupLog(L"Dart entrypoint argument count: " +
               std::to_wstring(command_line_arguments.size()));

    project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

    FlutterWindow window(project);
    Win32Window::Point default_origin(100, 100); // Default origin if no saved data
    Win32Window::Size default_size(1280, 720);   // Default size if no saved data

    // Call the new Create method which handles loading placement internally
    StartupLog(L"Creating FlutterWindow");
    if (!window.Create(L"nt_helper", default_origin, default_size))
    {
      StartupLog(L"FlutterWindow.Create failed; exiting with failure");
      if (SUCCEEDED(com_result))
      {
        ::CoUninitialize();
      }
      return EXIT_FAILURE;
    }
    StartupLog(L"FlutterWindow.Create succeeded");
    window.SetQuitOnClose(true);

    StartupLog(L"Entering Win32 message loop");
    ::MSG msg;
    while (::GetMessage(&msg, nullptr, 0, 0))
    {
      ::TranslateMessage(&msg);
      ::DispatchMessage(&msg);
    }

    StartupLog(L"Win32 message loop exited");
    if (SUCCEEDED(com_result))
    {
      ::CoUninitialize();
      StartupLog(L"CoUninitialize completed");
    }
    return EXIT_SUCCESS;
  }
  catch (const std::exception &exception)
  {
    StartupLog(L"Unhandled native std::exception during startup: " +
               std::wstring(exception.what(), exception.what() + strlen(exception.what())));
  }
  catch (...)
  {
    StartupLog(L"Unhandled unknown native exception during startup");
  }

  return EXIT_FAILURE;
}
