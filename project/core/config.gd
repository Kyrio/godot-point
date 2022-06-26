extends Node


var defaults = {
    "binaries_path": "user://binaries",
    "download_mirror": 0,
}

var current = {}

var _user_directory = Directory.new()
var _config_file = ConfigFile.new()


func _ready():
    if _user_directory.open("user://") != OK:
        push_error("Error when opening user data directory")
        return
    
    if not _user_directory.dir_exists(defaults.binaries_path):
        _user_directory.make_dir(defaults.binaries_path)
    
    var error = _config_file.load("user://config.ini")
    if error == OK:
        current.binaries_path = _config_file.get_value("paths", "binaries", defaults.binaries_path)
        current.download_mirror = _config_file.get_value("downloads", "mirror", defaults.download_mirror)

#    config.save("user://config.ini")
