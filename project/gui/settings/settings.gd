extends Control


var default_install_directory: String
var default_download_mirror: int

@onready var dialogs := $Dialogs as Control
@onready var credits_dialog := $Dialogs/Credits as Control
@onready var credits_dialog_ok := $Dialogs/Credits/Container/OK as Control
@onready var third_party_dialog := $Dialogs/ThirdParty as Control
@onready var third_party_dialog_ok := $Dialogs/ThirdParty/Container/OK as Control

@onready var install_directory_field := %InstallDirectoryField as LineEdit
@onready var install_directory_undo := install_directory_field.get_node("../Undo") as Button
@onready var download_mirror_options := %DownloadMirrorOptions as OptionButton
@onready var download_mirror_undo := download_mirror_options.get_node("../Undo") as Button

@onready var credits_button = %Credits as Button
@onready var third_party_button = %ThirdParty as Button
@onready var save_button = %Save as Button


func _ready():
    dialogs.hide()
    credits_dialog.hide()
    third_party_dialog.hide()
    
    default_install_directory = Config.get_default_setting("paths", "installs")
    default_download_mirror = Config.get_default_setting("core", "download_mirror")
    
    var install_directory = Config.get_setting("paths", "installs")
    if install_directory != default_install_directory:
        install_directory_field.text = install_directory
    
    install_directory_field.placeholder_text = ProjectSettings.globalize_path(default_install_directory)
    install_directory_field.grab_focus()
    
    download_mirror_options.selected = Config.get_setting("core", "download_mirror")


func _process(_delta):
    install_directory_undo.disabled = install_directory_field.text.is_empty()
    download_mirror_undo.disabled = download_mirror_options.selected == default_download_mirror
    
    if save_button.disabled:
        save_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
    else:
        save_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_install_directory_undo_pressed():
    install_directory_field.text = ""
    save_button.disabled = false


func _on_download_mirror_undo_pressed():
    download_mirror_options.selected = default_download_mirror
    save_button.disabled = false


func _on_install_directory_text_changed(_new_text: String):
    save_button.disabled = false


func _on_download_mirror_item_selected(_index: int):
    save_button.disabled = false


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
    credits_button.grab_focus()


func _on_third_party_close_pressed():
    third_party_dialog.hide()
    dialogs.hide()
    third_party_button.grab_focus()


func _on_save_pressed():
    var install_directory_error = install_directory_field.get_node("../../Error") as Control
    install_directory_error.hide()
    
    var install_directory = default_install_directory if install_directory_field.text.is_empty() else install_directory_field.text
    if not Config.validate_setting("paths", "installs", install_directory):
        install_directory_error.show()
        return
     
    if not Config.validate_setting("core", "download_mirror", download_mirror_options.selected):
        return
    
    Config.set_setting("paths", "installs", install_directory)
    Config.set_setting("core", "download_mirror", download_mirror_options.selected)
    Config.save_settings()
    save_button.disabled = true
