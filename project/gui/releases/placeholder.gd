class_name ListPlaceholder
extends CenterContainer


@export_multiline var loading_text = ""
@export_multiline var empty_text = ""

@onready var _loading := $Loading as Control
@onready var _empty := $Empty as Control


func _ready():
    $Loading/Label.text = loading_text
    $Empty/Label.text = empty_text


func set_loading():
    _loading.show()
    _empty.hide()


func set_empty():
    _loading.hide()
    _empty.show()


func set_ready():
    _loading.hide()
    _empty.hide()
    
