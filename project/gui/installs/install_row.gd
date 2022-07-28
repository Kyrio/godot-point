class_name InstallRow
extends HBoxContainer


const CONFIG_NAMES = [ "Standard", "Mono" ]

var install


@onready var path := %Path as Label
@onready var launch := %Launch as Button


func _ready():
    path.text = ProjectSettings.globalize_path(install.install_path)
    launch.text = CONFIG_NAMES[install.module_config]
