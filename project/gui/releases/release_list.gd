extends Control


enum Tab { STABLE, NEXT_MINOR, NEXT_MAJOR, COUNT }
enum TabStatus { EMPTY, LOADING, READY }

const RELEASE_SCENE = preload("res://gui/releases/release_card.tscn")

var tab_statuses: Array[TabStatus]
var tab_lists: Array[Control]
var tab_placeholders: Array[ListPlaceholder]
var tab_requests: Array

var _previous_page_regex: RegEx
var _next_page_regex: RegEx

@onready var tabs := %Tabs as TabContainer
@onready var refresh := %Refresh as PageButton
@onready var pagination := %Pagination as Control
@onready var previous_page := pagination.get_node("Previous") as PageButton
@onready var next_page := pagination.get_node("Next") as PageButton


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
            refresh.set_available(true)
            previous_page.set_available(false)
            next_page.set_available(false)
            tab_placeholders[current_tab].set_empty()
        
        TabStatus.LOADING:
            refresh.set_available(false)
            previous_page.set_available(false)
            next_page.set_available(false)
            tab_placeholders[current_tab].set_loading()
        
        TabStatus.READY:
            refresh.set_available(true)
            tab_placeholders[current_tab].set_ready()
            
    if current_tab == Tab.STABLE:
        pagination.show()
    else:
        pagination.hide()


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


func _on_stable_request_completed(result: HTTPRequest.Result, response_code: int, headers: PackedStringArray, body: PackedByteArray):
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
    
    previous_page.page_url = ""
    next_page.page_url = ""
    
    for header in headers:
        if header.begins_with("Link: "):
            var prev_match = _previous_page_regex.search(header)
            if prev_match:
                previous_page.page_url = prev_match.get_string(1)
            
            var next_match = _next_page_regex.search(header)
            if next_match:
                next_page.page_url = next_match.get_string(1)
    
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
        release_card.is_latest = i == 0 and previous_page.page_url.is_empty()
        release_card.has_mono = true

        stable_list.add_child(release_card)
        
        if release.version_name == Constants.EARLIEST_SUPPORTED_RELEASE:
            next_page.page_url = ""
            break
    
    var has_previous = not previous_page.page_url.is_empty()
    var has_next = not next_page.page_url.is_empty()
    previous_page.set_available(has_previous)
    next_page.set_available(has_next)

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
    if previous_page.page_url.is_empty():
        return
    
    var current_tab = tabs.current_tab
    if current_tab != Tab.STABLE or tab_statuses[current_tab] == TabStatus.LOADING:
        return
    
    fetch_tab_list(current_tab, previous_page.page_url)


func _on_next_pressed():
    if next_page.page_url.is_empty():
        return
    
    var current_tab = tabs.current_tab
    if current_tab != Tab.STABLE or tab_statuses[current_tab] == TabStatus.LOADING:
        return
    
    fetch_tab_list(current_tab, next_page.page_url)
