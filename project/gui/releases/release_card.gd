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

@onready var _standard := %Standard as DownloadButton
@onready var _mono := %Mono as DownloadButton


func _ready():
    if not release:
        return
    
    _version.text = release.version_name
    _latest.visible = is_latest
    _date.text = Constants.get_pretty_date_from_timestamp(release.publish_date)
    _description.text = release.description
    _mono.visible = has_mono


func _process(_delta):
    match status:
        Status.IDLE:
            if DownloadManager.is_downloading:
                _standard.status = DownloadButton.Status.DISABLED
                _mono.status = DownloadButton.Status.DISABLED
            else:
                _standard.status = DownloadButton.Status.READY
                _mono.status = DownloadButton.Status.READY
        
        Status.DOWNLOADING_STANDARD:
            _update_progress(_standard)
            _mono.status = DownloadButton.Status.DISABLED
        
        Status.DOWNLOADING_MONO:
            _update_progress(_mono)
            _standard.status = DownloadButton.Status.DISABLED


func _update_progress(download_button: DownloadButton):
    if DownloadManager.is_downloading:
        download_button.set_progress(DownloadManager.current_download_progress, String.humanize_size(DownloadManager.current_download_bytes))
    else:
        status = Status.IDLE


func _on_standard_pressed():
    status = Status.DOWNLOADING_STANDARD
    _standard.status = DownloadButton.Status.DOWNLOADING
    started_standard_download.emit(release)


func _on_mono_pressed():
    status = Status.DOWNLOADING_MONO
    _mono.status = DownloadButton.Status.DOWNLOADING
    started_mono_download.emit(release)
