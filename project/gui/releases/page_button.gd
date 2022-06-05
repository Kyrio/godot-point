class_name PageButton
extends Button


@export var page_url = ""


func set_enabled(enabled: bool):
    if enabled:
        disabled = false
        mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    else:
        disabled = true
        mouse_default_cursor_shape = Control.CURSOR_ARROW
        release_focus()
