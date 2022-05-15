extends Control


@onready var releases_button = $Split/Sidebar/Menu/Releases
@onready var view = $Split/View


func _ready():
    releases_button.button_pressed = true


func _on_releases_toggled(button_pressed: bool):
    if button_pressed:
        view.load_view(&"res://gui/releases/releases.tscn")
