class_name View
extends Control


var views = {}
var active: Control


func _ready():
    pass


func load_view(path: StringName):
    if path in views:
        if active:
            active.hide()
            
        active = views[path]
        active.show()
        return

    var packed_scene = load(String(path)) as PackedScene
    if not packed_scene:
        return
        
    var scene = packed_scene.instantiate() as Control
    if not scene:
        return
    
    if active:
        active.hide()
    
    views[path] = scene
    add_child(scene)
    active = scene
