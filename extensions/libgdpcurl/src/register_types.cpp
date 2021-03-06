#include "register_types.h"

#include <godot/gdnative_interface.h>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include <curl/curl.h>

#include "ftp_request.h"

using namespace godot;

void initialize_gdpcurl_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    curl_global_init(CURL_GLOBAL_DEFAULT);

    ClassDB::register_class<FTPRequest>();
}

void uninitialize_gdpcurl_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    curl_global_cleanup();
}

extern "C" {
    GDNativeBool GDN_EXPORT gdpcurl_library_init(const GDNativeInterface *p_interface, const GDNativeExtensionClassLibraryPtr p_library, GDNativeInitialization *r_initialization) {
        GDExtensionBinding::InitObject init_obj(p_interface, p_library, r_initialization);

        init_obj.register_initializer(initialize_gdpcurl_module);
        init_obj.register_terminator(uninitialize_gdpcurl_module);
        init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

        return init_obj.init();
    }
}
