class_name ReleaseCard
extends PanelContainer


var release: Release
var is_latest: bool
var has_mono: bool

@onready var _version := get_node("%Version") as Label
@onready var _latest := get_node("%Latest") as Label
@onready var _date := get_node("%Date") as Label
@onready var _description := get_node("%Description") as Label
@onready var _mono := get_node("%Mono") as Button


func _ready():
    if not release:
        return
    
    _version.text = release.version_name
    _latest.visible = is_latest
    _date.text = Constants.get_pretty_date_from_timestamp(release.publish_date)
    _description.text = release.description
    _mono.visible = has_mono
