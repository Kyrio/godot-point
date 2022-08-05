class_name InstallRow
extends VBoxContainer


const CONFIG_NAMES = [ "Standard", "Mono" ]

var install

var _global_path: String

@onready var location := %Location as LineEdit
@onready var launch := %Launch as Button
@onready var error_message := $Error as Label


func _ready():
    error_message.hide()
    
    _global_path = ProjectSettings.globalize_path(install.install_path)
    location.text = _global_path
    launch.text = CONFIG_NAMES[install.module_config]


func _on_location_gui_input(event: InputEvent):
    var is_click = event is InputEventMouseButton   \
        and event.button_index == MOUSE_BUTTON_LEFT \
        and event.pressed

    if is_click or event.is_action_pressed("ui_accept"):
        OS.shell_open("file://" + _global_path)


func _on_launch_pressed():
    error_message.hide()
    
    var install_dir = Directory.new()
    if install_dir.open(install.install_path) != OK:
        error_message.text = "Could not find the directory, you may have manually removed it."
        error_message.show()
        return
    
    var extension = ""
    match OS.get_name():
        "Windows", "UWP":
            extension = ".exe"
        
        "Linux":
            extension = "." + str(Constants.BITS)
    
    install_dir.list_dir_begin()
    var filename = install_dir.get_next()
    
    while filename != "":
        if filename.ends_with(extension):
            var full_path = _global_path.plus_file(filename)
            var process = OS.create_process(full_path, PackedStringArray())
            
            if process == -1:
                error_message.text = "An error happened while starting Godot."
                error_message.show()
                
            return
        
        filename = install_dir.get_next()
        
    error_message.text = "Could not find an executable in the directory."
    error_message.show()
