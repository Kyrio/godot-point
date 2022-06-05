extends Control


enum Tab { STABLE, NEXT_MINOR, NEXT_MAJOR, COUNT }
enum TabStatus { EMPTY, LOADING, READY }

const RELEASE_SCENE = preload("res://gui/releases/release_card.tscn")

var tab_statuses: Array[TabStatus]
var tab_lists: Array[Container]
var tab_placeholders: Array[ListPlaceholder]
var tab_requests: Array

@onready var tabs := %Tabs as TabContainer
@onready var refresh := %Refresh as Button


static func sort_releases_by_date(a: Release, b: Release):
    return a.publish_date >= b.publish_date


func _ready():
    assert(tabs.get_tab_count() == Tab.COUNT)
    
    for tab in Tab.COUNT:
        tab_statuses.append(TabStatus.EMPTY)
        
        var tab_control = tabs.get_tab_control(tab)
        tab_lists.append(tab_control.get_node("Content/List"))
        tab_placeholders.append(tab_control.get_node("Content/Placeholder"))
        tab_requests.append(tab_control.get_node("Request"))
        
        match tab:
            Tab.STABLE:
                tabs.set_tab_title(tab, "Stable")
                
                var request: HTTPRequest = tab_requests[tab]
                request.request_completed.connect(_on_stable_request_completed)
            
            Tab.NEXT_MINOR:
                tabs.set_tab_title(tab, "Godot " + Constants.NEXT_MINOR_VERSION)
                
                var request: PrereleaseRequest = tab_requests[tab]
                request.results_received.connect(_on_prerelease_results_received.bind(tab))
                request.request_failed.connect(_on_prerelease_request_failed.bind(tab))
            
            Tab.NEXT_MAJOR:
                tabs.set_tab_title(tab, "Godot " + Constants.NEXT_MAJOR_VERSION)
                
                var request: PrereleaseRequest = tab_requests[tab]
                request.results_received.connect(_on_prerelease_results_received.bind(tab))
                request.request_failed.connect(_on_prerelease_request_failed.bind(tab))
    
    _on_tab_changed(tabs.current_tab)


func _process(_delta):
    var current_tab = tabs.current_tab
    match tab_statuses[current_tab]:
        TabStatus.EMPTY:
            _enable_refresh()
            tab_placeholders[current_tab].set_empty()
        
        TabStatus.LOADING:
            _enable_refresh(false)
            tab_placeholders[current_tab].set_loading()
        
        TabStatus.READY:
            _enable_refresh()
            tab_placeholders[current_tab].set_ready()


func fetch_tab_list(tab: Tab):
    var list = tab_lists[tab]
    var child_count = list.get_child_count()

    for i in child_count:
        list.get_child(i).queue_free()
        
    tab_statuses[tab] = TabStatus.LOADING
    
    match tab:
        Tab.STABLE:
            var stable_request: HTTPRequest = tab_requests[tab]
            
            var error = stable_request.request(Constants.STABLE_RELEASES_API, PackedStringArray(Constants.GITHUB_HEADERS))
            if error != OK:
                push_error("Error when creating stable releases request.")
                tab_statuses[Tab.STABLE] = TabStatus.EMPTY
        
        Tab.NEXT_MINOR:
            var next_minor_request: PrereleaseRequest = tab_requests[tab]
            
            var error = next_minor_request.request_releases(Constants.NEXT_MINOR_VERSION)
            if error != OK:
                return
                
        Tab.NEXT_MAJOR:
            var next_major_request: PrereleaseRequest = tab_requests[tab]
            
            var error = next_major_request.request_releases(Constants.NEXT_MAJOR_VERSION)
            if error != OK:
                return


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
    
    var stable_list = tab_lists[Tab.STABLE]

    for i in len(data_received):
        var release_data = data_received[i]

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


func _on_prerelease_results_received(results: Array[Release], tab: Tab):
    var list = tab_lists[tab]

    results.sort_custom(sort_releases_by_date)

    for i in len(results):
        var release = results[i]
        var release_card := RELEASE_SCENE.instantiate() as ReleaseCard
        
        release_card.release = release
        release_card.is_latest = i == 0
        release_card.has_mono = release.version_number != "4.0"

        list.add_child(release_card)
        
    tab_statuses[tab] = TabStatus.READY


func _on_prerelease_request_failed(tab: Tab):
    tab_statuses[tab] = TabStatus.EMPTY


func _on_tab_changed(tab: Tab):
    if tab_statuses[tab] == TabStatus.EMPTY:
        fetch_tab_list(tab)


func _on_refresh_pressed():
    var current_tab = tabs.current_tab
    
    if tab_statuses[current_tab] != TabStatus.LOADING:
        fetch_tab_list(current_tab)


func _enable_refresh(enable = true):
    if enable:
        refresh.disabled = false
        refresh.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    else:
        refresh.disabled = true
        refresh.mouse_default_cursor_shape = Control.CURSOR_ARROW
        refresh.release_focus()
