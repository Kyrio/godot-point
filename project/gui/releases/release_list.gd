extends Control


enum Tab { STABLE, FUTURE, COUNT }
enum TabStatus { EMPTY, LOADING, READY }

const GODOT_STABLE_API = "https://api.github.com/repos/godotengine/godot/releases?per_page=10"
const GODOT4_FTP = "ftp://downloads.tuxfamily.org/godotengine/4.0/"
const GITHUB_HEADERS = ["Accept: application/vnd.github.text+json"]
const RELEASE_SCENE = preload("res://gui/releases/release_card.tscn")

@export var tab_names: Array[String]

var tab_statuses: Array[TabStatus]
var tab_lists: Array[Container]
var tab_placeholders: Array[Container]

var stable_releases: Array
var stable_releases_request: HTTPRequest

var future_releases: Array
var future_releases_request: FTPRequest

@onready var tabs := get_node("%Tabs") as TabContainer


static func get_download_name(version_number: String, status: String, module_config: String, platform: String, bits: int):
    var os = ""
    var exe = ""
    
    match platform:
        "Windows", "UWP":
            os = "win%d" % bits
            exe = "exe"
        "macOS":
            os = "osx"
            exe = "universal"
        "Linux":
            os = "linux" if version_number == "4.0" else "x11"
            exe = "%d" % bits
    
    var module_suffix = ""
    if module_config == "mono":
        module_suffix = "_mono"
    
    var download_name = "Godot_v%s-%s%s_%s.%s.zip" % [version_number, status, module_suffix, os, exe]
    return download_name


func _ready():
    assert(len(tab_names) == Tab.COUNT)
    
    for tab in Tab.COUNT:
        tabs.set_tab_title(tab, tab_names[tab])
        tab_statuses.append(TabStatus.EMPTY)
        
        var tab_control = tabs.get_tab_control(tab)
        tab_lists.append(tab_control.get_node("Content/List"))
        tab_placeholders.append(tab_control.get_node("Content/Placeholder"))
    

func _process(_delta):
    var current_tab = tabs.current_tab
    match tab_statuses[current_tab]:
        TabStatus.EMPTY:
            tab_placeholders[current_tab].show()
            fetch_tab_list(current_tab)
        
        TabStatus.LOADING:
            pass
        
        TabStatus.READY:
            tab_placeholders[current_tab].hide()


func _exit_tree():
    pass


func fetch_tab_list(tab: Tab):
    match tab:
        Tab.STABLE:
            fetch_stable_releases()
        
        Tab.FUTURE:
            pass


func fetch_stable_releases():
    if not stable_releases_request:
        stable_releases_request = HTTPRequest.new()
        add_child(stable_releases_request)
        stable_releases_request.request_completed.connect(_on_stable_request_completed)
    
    var error = stable_releases_request.request(GODOT_STABLE_API, PackedStringArray(GITHUB_HEADERS))
    if error != OK:
        push_error("Error when creating stable releases request.")
        return
    
    tab_statuses[Tab.STABLE] = TabStatus.LOADING
    

func _on_stable_request_completed(result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        push_error("JSON request returned with code ", response_code)
        tab_statuses[Tab.STABLE] = TabStatus.EMPTY
        return
    
    var json = JSON.new()
    var error = json.parse(body.get_string_from_utf8())
    
    if error != OK:
        push_error("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
        tab_statuses[Tab.STABLE] = TabStatus.EMPTY
        return
        
    var data_received = json.get_data()
    if typeof(data_received) != TYPE_ARRAY:
        push_error("Unexpected JSON data")
        tab_statuses[Tab.STABLE] = TabStatus.EMPTY
        return
    
    stable_releases = data_received
    _on_stable_releases_received()


func _on_stable_releases_received():
    var stable_list = tab_lists[Tab.STABLE]
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
        tab_statuses[Tab.STABLE] = TabStatus.READY
    else:
        tab_statuses[Tab.STABLE] = TabStatus.EMPTY
