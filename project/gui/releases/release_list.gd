extends Control


enum Tab { STABLE, NEXT_MINOR, NEXT_MAJOR, COUNT }
enum TabStatus { EMPTY, LOADING, READY }

const RELEASE_SCENE = preload("res://gui/releases/release_card.tscn")

var tab_statuses: Array[TabStatus]
var tab_lists: Array[Container]
var tab_placeholders: Array[Container]

var stable_releases: Array
var stable_releases_request: HTTPRequest

@onready var tabs := get_node("%Tabs") as TabContainer


func _ready():
    assert(tabs.get_tab_count() == Tab.COUNT)
    
    for tab in Tab.COUNT:
        tab_statuses.append(TabStatus.EMPTY)
        
        var tab_control = tabs.get_tab_control(tab)
        tab_lists.append(tab_control.get_node("Content/List"))
        tab_placeholders.append(tab_control.get_node("Content/Placeholder"))
        
        match tab:
            Tab.STABLE:
                tabs.set_tab_title(tab, "Stable")
            Tab.NEXT_MINOR:
                tabs.set_tab_title(tab, "Godot " + Constants.NEXT_MINOR_VERSION)
            Tab.NEXT_MAJOR:
                tabs.set_tab_title(tab, "Godot " + Constants.NEXT_MAJOR_VERSION)
    

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


func fetch_stable_releases():
    if not stable_releases_request:
        stable_releases_request = HTTPRequest.new()
        add_child(stable_releases_request)
        stable_releases_request.request_completed.connect(_on_stable_request_completed)
    
    var error = stable_releases_request.request(Constants.STABLE_RELEASES_API, PackedStringArray(Constants.GITHUB_HEADERS))
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
        var release_data = stable_releases[i]

        if typeof(release_data) != TYPE_DICTIONARY:
            continue
            
        var release_card := RELEASE_SCENE.instantiate() as ReleaseCard

        release_card.release = Release.from_github_release(release_data)
        release_card.is_latest = i == 0
        release_card.has_mono = true

        stable_list.add_child(release_card)

    if stable_list.get_child_count() > 0:
        tab_statuses[Tab.STABLE] = TabStatus.READY
    else:
        tab_statuses[Tab.STABLE] = TabStatus.EMPTY
