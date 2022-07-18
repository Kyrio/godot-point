class_name ReleaseCard
extends PanelContainer


var release: Release
var is_latest: bool
var has_mono: bool

@onready var standard_button := %Standard as DownloadButton
@onready var mono_button := %Mono as DownloadButton

@onready var _version := %Version as Label
@onready var _latest := %Latest as Label
@onready var _date := %Date as Label
@onready var _description := %Description as Label


func _ready():
    if not release:
        return
    
    _version.text = release.version_name
    _latest.visible = is_latest
    _date.text = Constants.get_pretty_date_from_timestamp(release.publish_date)
    _description.text = release.description
    mono_button.visible = has_mono


func _process(_delta):
    if standard_button.status == DownloadButton.Status.DOWNLOADING:
        _update_progress(standard_button)
    elif mono_button.status == DownloadButton.Status.DOWNLOADING:
        _update_progress(mono_button)


func _update_progress(download_button: DownloadButton):
    if DownloadManager.is_extracting:
        download_button.set_progress(1.0, "Extracting...")
    else:
        download_button.set_progress(DownloadManager.current_download_progress, String.humanize_size(DownloadManager.current_download_bytes))


func _on_standard_pressed():
    var success = DownloadManager.start_download(release, Release.ModuleConfig.NONE)
    
    if success:
        standard_button.status = DownloadButton.Status.DOWNLOADING
        _connect_with_download_manager(standard_button)


func _on_mono_pressed():
    var success = DownloadManager.start_download(release, Release.ModuleConfig.MONO)
    
    if success:
        mono_button.status = DownloadButton.Status.DOWNLOADING
        _connect_with_download_manager(mono_button)


func _connect_with_download_manager(download_button: DownloadButton):
    DownloadManager.download_failed.connect(_on_download_failed.bind(download_button))
    DownloadManager.installed.connect(_on_installed.bind(download_button))


func _disconnect_from_download_manager():
    DownloadManager.download_failed.disconnect(_on_download_failed)
    DownloadManager.installed.disconnect(_on_installed)


func _on_download_failed(download_button: DownloadButton):
    download_button.status = DownloadButton.Status.IDLE
    _disconnect_from_download_manager()


func _on_installed(download_button: DownloadButton):
    download_button.status = DownloadButton.Status.DONE
    _disconnect_from_download_manager()
