#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <shlobj.h>
#include <stdio.h>
#include <windows.h>

#include <chrono>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>

namespace {

std::wstring GetStartupLogDirectory() {
  std::wstring base_path;

  DWORD env_length = GetEnvironmentVariableW(L"LOCALAPPDATA", nullptr, 0);
  if (env_length > 1) {
    std::wstring env_value(env_length, L'\0');
    DWORD copied = GetEnvironmentVariableW(L"LOCALAPPDATA", env_value.data(),
                                           env_length);
    if (copied > 0 && copied < env_length) {
      env_value.resize(copied);
      base_path = env_value;
    }
  }

  if (base_path.empty()) {
    PWSTR local_app_data = nullptr;
    if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_LocalAppData, KF_FLAG_CREATE,
                                       nullptr, &local_app_data))) {
      base_path = local_app_data;
      CoTaskMemFree(local_app_data);
    }
  }

  if (base_path.empty()) {
    wchar_t temp_path[MAX_PATH];
    DWORD length = GetTempPathW(MAX_PATH, temp_path);
    if (length > 0 && length < MAX_PATH) {
      base_path = temp_path;
    } else {
      base_path = L".";
    }
  }

  std::wstring app_dir = base_path + L"\\nt_helper";
  CreateDirectoryW(app_dir.c_str(), nullptr);

  std::wstring log_dir = app_dir + L"\\logs";
  CreateDirectoryW(log_dir.c_str(), nullptr);
  return log_dir;
}

std::wstring CurrentTimestamp() {
  const auto now = std::chrono::system_clock::now();
  const auto time = std::chrono::system_clock::to_time_t(now);
  const auto millis = std::chrono::duration_cast<std::chrono::milliseconds>(
                          now.time_since_epoch()) %
                      1000;

  std::tm local_time;
  localtime_s(&local_time, &time);

  std::wstringstream stream;
  stream << std::put_time(&local_time, L"%Y-%m-%dT%H:%M:%S") << L"."
         << std::setw(3) << std::setfill(L'0') << millis.count();
  return stream.str();
}

void InitializeStartupLog() {
  static bool initialized = false;
  if (initialized) {
    return;
  }
  initialized = true;

  const std::wstring log_path = GetStartupLogPath();
  const std::wstring previous_log_path =
      GetStartupLogDirectory() + L"\\nt_helper_startup.previous.log";

  DeleteFileW(previous_log_path.c_str());
  MoveFileExW(log_path.c_str(), previous_log_path.c_str(),
              MOVEFILE_REPLACE_EXISTING | MOVEFILE_COPY_ALLOWED);

  std::wofstream file(log_path, std::ios::out | std::ios::trunc);
  if (file.is_open()) {
    file << L"[" << CurrentTimestamp()
         << L"] ============================================================"
         << std::endl;
    file << L"[" << CurrentTimestamp() << L"] nt_helper native startup log"
         << std::endl;
    file << L"[" << CurrentTimestamp() << L"] Log file: " << log_path
         << std::endl;
  }
}

}  // namespace

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout)) {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr)) {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
  }
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr)
    -1; // remove the trailing null character
  int input_length = (int)wcslen(utf16_string);
  std::string utf8_string;
  if (target_length <= 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}

std::wstring GetStartupLogPath() {
  return GetStartupLogDirectory() + L"\\nt_helper_startup.log";
}

void StartupLog(const std::wstring& message) {
  InitializeStartupLog();

  const std::wstring line = L"[" + CurrentTimestamp() + L"] " + message;
  std::wofstream file(GetStartupLogPath(), std::ios::out | std::ios::app);
  if (file.is_open()) {
    file << line << std::endl;
  }

  OutputDebugStringW((message + L"\n").c_str());
}

void StartupLogLastError(const std::wstring& message) {
  const DWORD error = GetLastError();
  StartupLog(message + L" (GetLastError=" + std::to_wstring(error) + L")");
}
