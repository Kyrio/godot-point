extends Control


enum Tab { STABLE, NEXT_MAJOR, COUNT }
enum TabStatus { EMPTY, LOADING, READY }

const RELEASE_SCENE = preload("res://gui/releases/release_card.tscn")

var tab_statuses: Array[TabStatus]
var tab_lists: Array[Control]
var tab_placeholders: Array[ListPlaceholder]
var tab_requests: Array

var _previous_page_regex: RegEx
var _next_page_regex: RegEx
var _previous_page_url = ""
var _next_page_url = ""

@onready var tabs := %Tabs as TabContainer
@onready var refresh := %Refresh as Button
@onready var pagination := %Pagination as Control
@onready var previous_page := pagination.get_node("Previous") as Button
@onready var next_page := pagination.get_node("Next") as Button
@onready var toolbar_buttons: Array[Button] = [refresh, previous_page, next_page]


static func sort_releases_by_date(a: Release, b: Release):
    return a.publish_date >= b.publish_date


func _ready():
    _previous_page_regex = RegEx.new()
    _next_page_regex = RegEx.new()
    
    _previous_page_regex.compile("<([^<>]+)>; rel=\"prev\"")
    _next_page_regex.compile("<([^<>]+)>; rel=\"next\"")
    
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
            refresh.disabled = false
            tab_placeholders[current_tab].set_empty()
        
        TabStatus.LOADING:
            refresh.disabled = true
            tab_placeholders[current_tab].set_loading()
        
        TabStatus.READY:
            refresh.disabled = DownloadManager.is_working
            tab_placeholders[current_tab].set_ready()
            
    if current_tab == Tab.STABLE:
        pagination.show()
        
        match tab_statuses[current_tab]:
            TabStatus.EMPTY, TabStatus.LOADING:
                previous_page.disabled = true
                next_page.disabled = true
                
            TabStatus.READY:
                previous_page.disabled = DownloadManager.is_working
                next_page.disabled = DownloadManager.is_working   
    else:
        pagination.hide()
        
    for button in toolbar_buttons:
        if button.disabled:
            button.mouse_default_cursor_shape = Control.CURSOR_ARROW
        else:
            button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _input(event: InputEvent):
    if event.is_action_pressed("ui_prev_tab"):
        tabs.current_tab = tabs.current_tab - 1 if tabs.current_tab > 0 else tabs.get_tab_count() - 1
    elif event.is_action_pressed("ui_next_tab"):
        tabs.current_tab = tabs.current_tab + 1 if tabs.current_tab < tabs.get_tab_count() - 1 else 0


func fetch_tab_list(tab: Tab, page_url = ""):
    var list = tab_lists[tab]
    var child_count = list.get_child_count()

    for i in child_count:
        list.get_child(i).queue_free()
        
    tab_statuses[tab] = TabStatus.LOADING
    
    match tab:
        Tab.STABLE:
            var stable_request: HTTPRequest = tab_requests[tab]
            var url = Constants.STABLE_RELEASES_API if page_url.is_empty() else page_url
            
            var error = stable_request.request(url, PackedStringArray(Constants.GITHUB_HEADERS))
            if error != OK:
                push_error("Error when creating stable releases request.")
                tab_statuses[Tab.STABLE] = TabStatus.EMPTY

        Tab.NEXT_MAJOR:
            var next_major_request: PrereleaseRequest = tab_requests[tab]
            
            var error = next_major_request.request_releases(Constants.NEXT_MAJOR_VERSION)
            if error != OK:
                return


func _on_stable_request_completed(result: HTTPRequest.Result, response_code: int, headers: PackedStringArray, body: PackedByteArray):
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        push_error("JSON request returned with error ", result , "and response code ", response_code)
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
    
    _previous_page_url = ""
    _next_page_url = ""
    
    for header in headers:
        if header.begins_with("Link: "):
            var prev_match = _previous_page_regex.search(header)
            if prev_match:
                _previous_page_url = prev_match.get_string(1)
            
            var next_match = _next_page_regex.search(header)
            if next_match:
                _next_page_url = next_match.get_string(1)
    
    var stable_list = tab_lists[Tab.STABLE]

    for i in len(data_received):
        var release_data = data_received[i]

        if typeof(release_data) != TYPE_DICTIONARY:
            continue
            
        var release = Release.from_github_release(release_data)
        
        var major = release.version_number[0].to_int()
        if major < Constants.EARLIEST_SUPPORTED_MAJOR:
            continue
        
        var release_card := RELEASE_SCENE.instantiate() as ReleaseCard
        release_card.release = release
        release_card.is_latest = i == 0 and _previous_page_url.is_empty()
        release_card.has_mono = true

        stable_list.add_child(release_card)
        
        if release.version_name == Constants.EARLIEST_SUPPORTED_RELEASE:
            _next_page_url = ""
            break
    
    previous_page.disabled = _previous_page_url.is_empty()
    next_page.disabled = _next_page_url.is_empty()

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


func _on_previous_pressed():
    if _previous_page_url.is_empty():
        return
    
    var current_tab = tabs.current_tab
    if current_tab != Tab.STABLE or tab_statuses[current_tab] == TabStatus.LOADING:
        return
    
    fetch_tab_list(current_tab, _previous_page_url)


func _on_next_pressed():
    if _next_page_url.is_empty():
        return
    
    var current_tab = tabs.current_tab
    if current_tab != Tab.STABLE or tab_statuses[current_tab] == TabStatus.LOADING:
        return
    
    fetch_tab_list(current_tab, _next_page_url)
