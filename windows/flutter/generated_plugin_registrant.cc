//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <pasteboard/pasteboard_plugin.h>
#include <universal_ble/universal_ble_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  PasteboardPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PasteboardPlugin"));
  UniversalBlePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UniversalBlePluginCApi"));
}
