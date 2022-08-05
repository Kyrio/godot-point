class_name InstallRow
extends HBoxContainer


const CONFIG_NAMES = [ "Standard", "Mono" ]

var install


@onready var location := %Location as LineEdit
@onready var launch := %Launch as Button


func _ready():
    location.text = ProjectSettings.globalize_path(install.install_path)
    launch.text = CONFIG_NAMES[install.module_config]


func _on_location_gui_input(event: InputEvent):
    var is_click = event is InputEventMouseButton   \
        and event.button_index == MOUSE_BUTTON_LEFT \
        and event.pressed

    if is_click or event.is_action_pressed("ui_accept"):
        OS.shell_open("file://" + ProjectSettings.globalize_path(install.install_path))
