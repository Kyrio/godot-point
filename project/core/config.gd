extends Node


enum Mirrors { TUXFAMILY, GITHUB, COUNT }

const defaults = """
[core]
download_mirror=0

[paths]
installs="user://installs"
"""

var _user_directory = Directory.new()
var _default_config_file = ConfigFile.new()
var _config_file = ConfigFile.new()


func _ready():
    var _error = _default_config_file.parse(defaults)
    
    if _user_directory.open("user://") != OK:
        push_error("Error when opening user data directory")
        return
    
    var default_installs = _default_config_file.get_value("paths", "installs")
    if not _user_directory.dir_exists(default_installs):
        _user_directory.make_dir(default_installs)
    
    _error = _config_file.load("user://config.ini")


func get_setting(section: String, key: String):
    return _config_file.get_value(section, key, get_default_setting(section, key))


func get_default_setting(section: String, key: String):
    return _default_config_file.get_value(section, key)


func validate_setting(section: String, key: String, value: Variant) -> bool:
    match section:
        "paths":
            match key:
                "installs":
                    return value is String and _user_directory.dir_exists(value)
        
        "core":
            match key:
                "download_mirror":
                    return value is int and value >= 0 and value < Mirrors.COUNT
        
    return false


func set_setting(section: String, key: String, value: Variant):
    _config_file.set_value(section, key, value)


func save_settings():
    _config_file.save("user://config.ini")
