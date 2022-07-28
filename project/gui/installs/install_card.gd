class_name InstallCard
extends PanelContainer


const ROW_SCENE = preload("res://gui/installs/install_row.tscn")

var version_name: String
var installs: Array

@onready var title := %Title as Label
@onready var rows := %Rows as VBoxContainer


func _ready():
    title.text = version_name
    
    for install in installs:
        var install_row := ROW_SCENE.instantiate() as InstallRow
        install_row.install = install
        rows.add_child(install_row)
