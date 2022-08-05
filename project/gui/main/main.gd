extends Control


@onready var releases_button := %Releases as Button
@onready var installs_button := %Installs as Button
@onready var view := $Split/View as View


func _ready():
    if InstallManager.has_installs():
        installs_button.button_pressed = true
        installs_button.grab_focus()
    else:
        releases_button.button_pressed = true
        releases_button.grab_focus()


func _on_installs_toggled(button_pressed: bool):
    if button_pressed:
        view.load_view(&"res://gui/installs/install_list.tscn")


func _on_releases_toggled(button_pressed: bool):
    if button_pressed:
        view.load_view(&"res://gui/releases/release_list.tscn")


func _on_settings_toggled(button_pressed: bool):
    if button_pressed:
        view.load_view(&"res://gui/settings/settings.tscn")
