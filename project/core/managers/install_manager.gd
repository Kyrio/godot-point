extends Node


const MODULE_CONFIGS = [ "standard", "mono" ]

var registry = ConfigFile.new()


func _ready():
    var _error = registry.load("user://registry.ini")


func register_install(release: Release, module_config: Release.ModuleConfig, install_path: String) -> bool:
    registry.set_value(release.version_name, MODULE_CONFIGS[module_config], install_path)
    return registry.save("user://registry.ini") == OK


func is_installed(release: Release, module_config: Release.ModuleConfig) -> bool:
    return registry.has_section_key(release.version_name, MODULE_CONFIGS[module_config])
