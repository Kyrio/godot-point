extends Control


@onready var dialogs := $Dialogs as Control
@onready var credits_dialog := $Dialogs/Credits as Control
@onready var credits_dialog_ok := $Dialogs/Credits/Container/OK as Control
@onready var third_party_dialog := $Dialogs/ThirdParty as Control
@onready var third_party_dialog_ok := $Dialogs/ThirdParty/Container/OK as Control

@onready var install_directory := %InstallDirectory as Control
@onready var install_directory_edit := install_directory.get_node("Edit") as LineEdit

@onready var save_button = %Save as Button


func _ready():
    dialogs.hide()
    credits_dialog.hide()
    third_party_dialog.hide()
    install_directory_edit.grab_focus()


func _process(_delta):
    if save_button.disabled:
        save_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
        save_button.focus_mode = Control.FOCUS_NONE
    else:
        save_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        save_button.focus_mode = Control.FOCUS_ALL


func _on_credits_pressed():
    dialogs.show()
    credits_dialog.show()
    credits_dialog_ok.grab_focus()


func _on_third_party_pressed():
    dialogs.show()
    third_party_dialog.show()
    third_party_dialog_ok.grab_focus()


func _on_credits_close_pressed():
    credits_dialog.hide()
    dialogs.hide()


func _on_third_party_close_pressed():
    third_party_dialog.hide()
    dialogs.hide()
