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

@onready var _standard := get_node("%Standard") as Button
@onready var _mono := get_node("%Mono") as Button


func _ready():
    if not release:
        return
    
    _version.text = release.version_name
    _latest.visible = is_latest
    _date.text = Constants.get_pretty_date_from_timestamp(release.publish_date)
    _description.text = release.description
    _mono.visible = has_mono


func _process(_delta):
    _standard.text = "Standard"
    _mono.text = "Mono"
    
    _standard.disabled = false
    _mono.disabled = false
    
    if DownloadManager.is_downloading:
        _standard.disabled = true
        _mono.disabled = true
        
        if DownloadManager.current_download_release.version_name == release.version_name:
            var percentage = DownloadManager.current_download_progress * 100
            
            if DownloadManager.current_download_module_config == Release.ModuleConfig.MONO:
                _mono.text = "%d%%" % percentage
            else:
                _standard.text = "%d%%" % percentage


func _on_standard_pressed():
    started_standard_download.emit(release)


func _on_mono_pressed():
    started_mono_download.emit(release)
