class_name ReleaseCard
extends PanelContainer


signal started_standard_download(release: Release)
signal started_mono_download(release: Release)

enum Status { IDLE, DOWNLOADING_STANDARD, DOWNLOADING_MONO }

var release: Release
var is_latest: bool
var has_mono: bool
var status = Status.IDLE

@onready var _version := %Version as Label
@onready var _latest := %Latest as Label
@onready var _date := %Date as Label
@onready var _description := %Description as Label

@onready var _standard := %Standard as Button
@onready var _mono := %Mono as Button
@onready var _progress := %Progress as ProgressBar
@onready var _progress_status := %ProgressStatus as Label


func _ready():
    if not release:
        return
    
    _version.text = release.version_name
    _latest.visible = is_latest
    _date.text = Constants.get_pretty_date_from_timestamp(release.publish_date)
    _description.text = release.description
    _mono.visible = has_mono
    _progress.visible = false


func _process(_delta):
    _standard.disabled = DownloadManager.is_downloading
    _mono.disabled = DownloadManager.is_downloading
    
    if status == Status.DOWNLOADING_STANDARD:
        _update_progress(_standard)
    elif status == Status.DOWNLOADING_MONO:
        _update_progress(_mono)


func _update_progress(download_button: Button):
    if DownloadManager.is_downloading:
        download_button.visible = false
        _progress.visible = true
        _progress.value = DownloadManager.current_download_progress
        _progress_status.text = String.humanize_size(DownloadManager.current_download_bytes)
    else:
        download_button.visible = true
        _progress.visible = false
        
        status = Status.IDLE


func _on_standard_pressed():
    status = Status.DOWNLOADING_STANDARD
    started_standard_download.emit(release)


func _on_mono_pressed():
    status = Status.DOWNLOADING_MONO
    started_mono_download.emit(release)
