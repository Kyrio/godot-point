extends Control


enum { STABLE, FUTURE }

const STABLE_RELEASES = "https://api.github.com/repos/godotengine/godot/releases?per_page=10"
const FUTURE_FTP = "ftp://downloads.tuxfamily.org/godotengine/4.0/"
const RELEASE_SCENE = preload("res://gui/releases/release_card.tscn")

var stable_request := HTTPRequest.new()
var future_request := FtpRequest.new()
var stable_releases: Array

var _github_headers = PackedStringArray(["Accept: application/vnd.github.text+json"])

@onready var tabs := get_node("%Tabs") as TabContainer
@onready var stable_list := get_node("%StableList") as VBoxContainer
@onready var stable_placeholder := get_node("%StablePlaceholder") as Control


func _ready():
    add_child(stable_request)
    add_child(future_request)
    
    stable_request.request_completed.connect(self._on_stable_request_completed)
    future_request.request_completed.connect(self._on_future_request_completed)
    
    tabs.set_tab_title(STABLE, "Stable")
    tabs.set_tab_title(FUTURE, "Godot 4.0")
    _on_tab_changed(tabs.current_tab)


func _on_tab_changed(tab):
    match tab:
        STABLE:
            if stable_releases.is_empty():
                _fetch_stable_releases()
        
        FUTURE:
            var error = future_request.request_list(FUTURE_FTP)
            if error != OK:
                push_error("Error when creating future releases request.")
                

func _fetch_stable_releases():
    stable_placeholder.show()
    
    var error = stable_request.request(STABLE_RELEASES, _github_headers)
    if error != OK:
        push_error("Error when creating stable releases request.")


func _on_stable_request_completed(result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        push_error("JSON request returned with code ", response_code)
        return
    
    var json = JSON.new()
    var error = json.parse(body.get_string_from_utf8())
    
    if error != OK:
        push_error("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
        return
        
    var data_received = json.get_data()
    if typeof(data_received) != TYPE_ARRAY:
        push_error("Unexpected JSON data")
        return
    
    stable_releases = data_received
    _refresh_stable_releases()


func _on_future_request_completed(result: HTTPRequest.Result, body: String):
    if result != HTTPRequest.RESULT_SUCCESS:
        push_error("FTP request returned with an error")
        return
    
    print(body)


func _refresh_stable_releases():
    var child_count = stable_list.get_child_count()
    
    for i in child_count:
        stable_list.get_child(i).queue_free()
    
    for i in len(stable_releases):
        var release = stable_releases[i]
        
        if typeof(release) != TYPE_DICTIONARY:
            continue
        
        var release_card := RELEASE_SCENE.instantiate() as ReleaseCard
        
        release_card.release_data = release
        release_card.is_latest = i == 0
        
        stable_list.add_child(release_card)
    
    if stable_list.get_child_count() > 0:
        stable_placeholder.hide()
