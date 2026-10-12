#ifndef RUNNER_WINDOWS_VIDEO_POPUP_REMOTE_H_
#define RUNNER_WINDOWS_VIDEO_POPUP_REMOTE_H_

#include <flutter/method_channel.h>
#include <flutter/method_result_functions.h>

#include <memory>
#include <string>

// Remote commands must return the main authority's actual result. A destroyed
// child engine must never receive a late MethodResult callback.
inline void ForwardVideoPopupRemote(
    flutter::MethodChannel<flutter::EncodableValue>* main_channel,
    const std::string& method, const flutter::EncodableValue* arguments,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result,
    std::weak_ptr<bool> child_alive) {
  if (main_channel == nullptr) {
    result->Error("remote_unavailable", "The main connection authority is unavailable.");
    return;
  }
  auto reply = std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(std::move(result));
  const auto usable = [child_alive]() {
    const auto alive = child_alive.lock();
    return alive && *alive;
  };
  main_channel->InvokeMethod(
      method, std::make_unique<flutter::EncodableValue>(
                  arguments ? *arguments : flutter::EncodableValue()),
      std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
          [reply, usable](const auto* value) {
            if (usable()) reply->Success(value ? *value : flutter::EncodableValue());
          },
          [reply, usable](const auto& code, const auto& message, const auto* details) {
            if (!usable()) return;
            if (details) reply->Error(code, message, *details);
            else reply->Error(code, message);
          },
          [reply, usable]() {
            if (usable()) reply->Error("remote_unavailable", "The main remote handler is unavailable.");
          }));
}

#endif  // RUNNER_WINDOWS_VIDEO_POPUP_REMOTE_H_
