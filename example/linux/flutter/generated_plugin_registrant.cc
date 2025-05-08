//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flt_hc_hud/flt_hc_hud_plugin.h>
#include <photo_browser/photo_browser_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flt_hc_hud_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FltHcHudPlugin");
  flt_hc_hud_plugin_register_with_registrar(flt_hc_hud_registrar);
  g_autoptr(FlPluginRegistrar) photo_browser_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PhotoBrowserPlugin");
  photo_browser_plugin_register_with_registrar(photo_browser_registrar);
}
