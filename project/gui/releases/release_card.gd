class_name ReleaseCard
extends PanelContainer


signal started_standard_download(release: Release)
signal started_mono_download(release: Release)

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


func _on_standard_pressed():
    started_standard_download.emit(release)


func _on_mono_pressed():
    started_mono_download.emit(release)
