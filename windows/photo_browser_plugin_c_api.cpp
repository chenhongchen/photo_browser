#include "include/photo_browser/photo_browser_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "photo_browser_plugin.h"

void PhotoBrowserPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  photo_browser::PhotoBrowserPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
