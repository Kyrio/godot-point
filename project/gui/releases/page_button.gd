class_name PageButton
extends Button


@export var page_url = ""


func _ready():
    if disabled:
        mouse_default_cursor_shape = Control.CURSOR_ARROW
    else:
        mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func set_available(available: bool):
    if available == not disabled:
        return
    
    disabled = not available
    if available:
        mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    else:
        mouse_default_cursor_shape = Control.CURSOR_ARROW
        release_focus()
