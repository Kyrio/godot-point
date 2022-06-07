extends Control


@onready var installs_button := $Split/Sidebar/Menu/Installs as Button
@onready var view := $Split/View as View


func _ready():
    installs_button.button_pressed = true


func _on_installs_toggled(button_pressed: bool):
    if button_pressed:
        view.load_view(&"res://gui/installs/install_list.tscn")


func _on_releases_toggled(button_pressed: bool):
    if button_pressed:
        view.load_view(&"res://gui/releases/release_list.tscn")


func _on_settings_toggled(button_pressed: bool):
    if button_pressed:
        view.load_view(&"res://gui/settings/settings.tscn")
