extends Control


enum Tab { STABLE, NEXT_MINOR, NEXT_MAJOR, COUNT }
enum TabStatus { EMPTY, LOADING, READY }
enum ThreadStatus { IDLE, WORKING, RESULTS_READY, REQUEST_FAILED }

const RELEASE_SCENE = preload("res://gui/releases/release_card.tscn")

var tab_statuses: Array[TabStatus]
var tab_lists: Array[Container]
var tab_placeholders: Array[Container]

var stable_releases_request: HTTPRequest
var next_minor_releases_request: FTPRequest

var next_minor_thread: Thread
var next_minor_mutex: Mutex
var next_minor_semaphore: Semaphore
var next_minor_thread_status: ThreadStatus
var next_minor_thread_should_exit: bool
var next_minor_results: Array[Release]

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
    
    stable_releases_request = HTTPRequest.new()
    add_child(stable_releases_request)
    stable_releases_request.request_completed.connect(_on_stable_request_completed)
    
    next_minor_releases_request = FTPRequest.new()
    add_child(next_minor_releases_request)
    
    next_minor_mutex = Mutex.new()
    next_minor_semaphore = Semaphore.new()
    next_minor_thread_status = ThreadStatus.IDLE
    next_minor_thread_should_exit = false
    
    next_minor_thread = Thread.new()
    next_minor_thread.start(_next_minor_thread_function)
    
    _on_tab_changed(tabs.current_tab)


func _process(_delta):
    var current_tab = tabs.current_tab
    match tab_statuses[current_tab]:
        TabStatus.EMPTY:
            tab_placeholders[current_tab].show()
        
        TabStatus.LOADING:
            tab_placeholders[current_tab].show()
            update_tab_list(current_tab)
        
        TabStatus.READY:
            tab_placeholders[current_tab].hide()


func _exit_tree():
    next_minor_mutex.lock()
    next_minor_thread_should_exit = true
    next_minor_mutex.unlock()
    
    next_minor_semaphore.post()
    next_minor_thread.wait_to_finish()
    

func _on_tab_changed(tab: Tab):
    if tab_statuses[tab] == TabStatus.EMPTY:
        tab_statuses[tab] = TabStatus.LOADING
        fetch_tab_list(tab)


func fetch_tab_list(tab: Tab):
    match tab:
        Tab.STABLE:
            fetch_stable_releases()
        
        Tab.NEXT_MINOR:
            fetch_next_minor_releases()
            

func update_tab_list(tab: Tab):
    match tab:
        Tab.STABLE:
            pass
        
        Tab.NEXT_MINOR:
            update_next_minor_releases()


func fetch_stable_releases():
    var error = stable_releases_request.request(Constants.STABLE_RELEASES_API, PackedStringArray(Constants.GITHUB_HEADERS))
    if error != OK:
        push_error("Error when creating stable releases request.")
        tab_statuses[Tab.STABLE] = TabStatus.EMPTY
        return


func fetch_next_minor_releases():
    next_minor_semaphore.post()


func update_next_minor_releases():
    next_minor_mutex.lock()
    var thread_status = next_minor_thread_status
    next_minor_mutex.unlock()
    
    match thread_status:
        ThreadStatus.IDLE, ThreadStatus.WORKING:
            return
        
        ThreadStatus.RESULTS_READY:
            next_minor_mutex.lock()
            var results = next_minor_results.duplicate()
            next_minor_mutex.unlock()
            
            update_prereleases(tab_lists[Tab.NEXT_MINOR], results)
            tab_statuses[Tab.NEXT_MINOR] = TabStatus.READY
        
        ThreadStatus.REQUEST_FAILED:
            tab_statuses[Tab.NEXT_MINOR] = TabStatus.EMPTY
            return


func update_prereleases(list: Container, releases: Array[Release]):
    var child_count = list.get_child_count()

    for i in child_count:
        list.get_child(i).queue_free()

    releases.sort_custom(sort_releases_by_date)

    for i in len(releases):
        var release = releases[i]
        var release_card := RELEASE_SCENE.instantiate() as ReleaseCard
        
        release_card.release = release
        release_card.is_latest = i == 0
        release_card.has_mono = release.version_number != "4.0"

        list.add_child(release_card)


func sort_releases_by_date(a: Release, b: Release):
    return a.publish_date >= b.publish_date


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
    var child_count = stable_list.get_child_count()

    for i in child_count:
        stable_list.get_child(i).queue_free()

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


func _next_minor_thread_function():
    while true:
        next_minor_semaphore.wait()

        next_minor_mutex.lock()
        next_minor_thread_status = ThreadStatus.WORKING
        next_minor_results = []
        var should_exit = next_minor_thread_should_exit
        next_minor_mutex.unlock()

        if should_exit:
            break

        var error = next_minor_releases_request.request_list(Constants.NEXT_MINOR_RELEASES_FTP)
        if error != OK:
            push_error("Error when creating next minor releases request.")
            next_minor_mutex.lock()
            next_minor_thread_status = ThreadStatus.REQUEST_FAILED
            next_minor_mutex.unlock()
            continue
        
        var ftp_list = next_minor_releases_request.get_list()
        var lines = ftp_list.split("\n", false)
        var results = []
        
        for line in lines:
            var status = line.strip_edges()
            if status.begins_with("alpha") or status.begins_with("beta") or status.begins_with("rc"):
                var release = Release.new()
                release.version_number = Constants.NEXT_MINOR_VERSION
                release.status = status
                release.version_name = "%s-%s" % [release.version_number, release.status]
                release.description = "This is a prerelease of the upcoming Godot %s." % release.version_number
                
                var url = Constants.NEXT_MINOR_RELEASES_FTP + status + "/" + release.get_download_name("", OS.get_name(), 64)
                error = next_minor_releases_request.request_filetime(url)
                if error != OK:
                    push_warning("Error when fetching release, ignoring: ", url)
                    continue
                    
                release.publish_date = next_minor_releases_request.get_filetime()
                if release.publish_date <= 0:
                    continue
                
                results.append(release)
        
        next_minor_mutex.lock()
        if len(results) >= 0:
            next_minor_thread_status = ThreadStatus.RESULTS_READY
            next_minor_results = results
        else:
            next_minor_thread_status = ThreadStatus.REQUEST_FAILED
        next_minor_mutex.unlock()
