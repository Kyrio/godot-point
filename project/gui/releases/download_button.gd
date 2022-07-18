class_name DownloadButton
extends VBoxContainer


signal pressed

enum Status { IDLE, DOWNLOADING, DONE }

@export var download_title = "Download"

var status = Status.IDLE

@onready var start_button := $Start as Button
@onready var progress_bar := $Progress as ProgressBar
@onready var progress_label := $Progress/ProgressLabel as Label
@onready var done_button := $Done as Button


func _ready():
    start_button.text = download_title


func _process(_delta):
    start_button.disabled = DownloadManager.is_working
    
    match status:
        Status.IDLE:
            start_button.visible = true
            progress_bar.visible = false
            done_button.visible = false
        
        Status.DOWNLOADING:
            start_button.visible = false
            progress_bar.visible = true
            done_button.visible = false
        
        Status.DONE:
            start_button.visible = false
            progress_bar.visible = false
            done_button.visible = true


func set_progress(value: float, message: String):
    progress_bar.value = value
    progress_label.text = message


func _on_start_pressed():
    pressed.emit()
