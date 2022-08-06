extends Node


signal registered(version_name: String, module_config: Release.ModuleConfig)
signal unregistered(version_name: String, module_config: Release.ModuleConfig)

const CONFIG_NAMES = [ "standard", "mono" ]

var registry = ConfigFile.new()


func _ready():
    var _error = registry.load("user://registry.ini")


func register_install(version_name: String, module_config: Release.ModuleConfig, install_path: String) -> bool:
    registry.set_value(version_name, CONFIG_NAMES[module_config], install_path)
    registered.emit(version_name, module_config)
    return registry.save("user://registry.ini") == OK


func unregister_install(version_name: String, module_config: Release.ModuleConfig) -> bool:
    registry.erase_section_key(version_name, CONFIG_NAMES[module_config])
    unregistered.emit(version_name, module_config)
    return registry.save("user://registry.ini") == OK


func is_installed(release: Release, module_config: Release.ModuleConfig) -> bool:
    return registry.has_section_key(release.version_name, CONFIG_NAMES[module_config])


func get_installed_versions() -> PackedStringArray:
    return registry.get_sections()


func get_installs(version_name: String) -> Array[Install]:
    var installs: Array[Install] = []
    
    for key in registry.get_section_keys(version_name):
        var module = CONFIG_NAMES.find(key)
        
        if module == -1:
            continue
        
        var install = Install.new()
        install.version_name = version_name
        install.module_config = module
        install.install_path = registry.get_value(version_name, key)
        installs.append(install)
    
    return installs


func has_installs() -> bool:
    return not registry.get_sections().is_empty()
