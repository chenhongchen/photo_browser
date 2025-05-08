//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flt_hc_hud/flt_hc_hud_plugin_c_api.h>
#include <permission_handler_windows/permission_handler_windows_plugin.h>
#include <photo_browser/photo_browser_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FltHcHudPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FltHcHudPluginCApi"));
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
  PhotoBrowserPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PhotoBrowserPluginCApi"));
}
