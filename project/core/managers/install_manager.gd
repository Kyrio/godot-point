extends Node


const CONFIG_NAMES = [ "standard", "mono" ]

var registry = ConfigFile.new()


func _ready():
    var _error = registry.load("user://registry.ini")


func register_install(release: Release, module_config: Release.ModuleConfig, install_path: String) -> bool:
    registry.set_value(release.version_name, CONFIG_NAMES[module_config], install_path)
    return registry.save("user://registry.ini") == OK


func is_installed(release: Release, module_config: Release.ModuleConfig) -> bool:
    return registry.has_section_key(release.version_name, CONFIG_NAMES[module_config])


func get_installs() -> Dictionary:
    var installs = {}
    
    for section in registry.get_sections():
        var version_installs = []
        
        for key in registry.get_section_keys(section):
            var module = CONFIG_NAMES.find(key)
            
            if module == -1:
                continue
            
            var install = Install.new()
            install.module_config = module
            install.install_path = registry.get_value(section, key)
            version_installs.append(install)
        
        installs[section] = version_installs
    
    return installs


func has_installs() -> bool:
    return not registry.get_sections().is_empty()


class Install extends RefCounted:
    var module_config: Release.ModuleConfig
    var install_path: String
