class_name PrereleaseRequest
extends Node

## A [Node] used to fetch a list of prereleases from Godot's FTP mirror.
## It uses its own thread and will emit a signal upon completion.

## Emitted when the request is completed successfully, providing a copy of the
## list of [Release] created in the thread.
signal results_received(results: Array[Release])

## Emitted if the request has failed and no releases have been obtained.
signal request_failed

enum ThreadStatus { IDLE, WORKING, RESULTS_READY, REQUEST_FAILED }

var _version_number: String
var _directory_url: String

var _ftp_request: FTPRequest

var _thread: Thread
var _thread_status: ThreadStatus
var _thread_should_exit: bool
var _thread_results: Array[Release]
var _mutex: Mutex
var _semaphore: Semaphore


func _ready():
    _ftp_request = FTPRequest.new()
    add_child(_ftp_request)
    
    _mutex = Mutex.new()
    _semaphore = Semaphore.new()
    _thread_status = ThreadStatus.IDLE
    _thread_should_exit = false
    
    _thread = Thread.new()
    _thread.start(_thread_function)


func _exit_tree():
    _mutex.lock()
    _thread_should_exit = true
    _mutex.unlock()
    
    _semaphore.post()
    _thread.wait_to_finish()


func _process(_delta):
    _mutex.lock()
    var status = _thread_status
    _mutex.unlock()

    match status:
        ThreadStatus.IDLE, ThreadStatus.WORKING:
            pass

        ThreadStatus.RESULTS_READY:
            _mutex.lock()
            var results = _thread_results.duplicate()
            _thread_status = ThreadStatus.IDLE
            _mutex.unlock()
            
            results_received.emit(results)

        ThreadStatus.REQUEST_FAILED:
            _mutex.lock()
            _thread_status = ThreadStatus.IDLE
            _mutex.unlock()
            
            request_failed.emit()


## Request a list of prereleases for this version number from the server defined
## in [member Constants.PRERELEASES_FTP]. If it succeeds, [signal results_received]
## will be emitted, otherwise [signal request_failed] will be. [br]
## Returns OK if request is successfully created, ERR_BUSY if still processing previous request.
func request_releases(version_number: String) -> int:
    _mutex.lock()
    var status = _thread_status
    _mutex.unlock()
    
    if status != ThreadStatus.IDLE:
        return ERR_BUSY
    
    _mutex.lock()
    _version_number = version_number
    _directory_url = Constants.PRERELEASES_FTP + version_number + "/"
    _mutex.unlock()
    
    _semaphore.post()
    return OK


func _thread_function():
    while true:
        _semaphore.wait()

        _mutex.lock()
        _thread_status = ThreadStatus.WORKING
        var should_exit = _thread_should_exit
        var base_url = _directory_url
        var version = _version_number
        _mutex.unlock()

        if should_exit:
            break

        var error = _ftp_request.request_list(base_url)
        if error != OK:
            push_error("Error when creating request for: ", base_url)
            
            _mutex.lock()
            _thread_status = ThreadStatus.REQUEST_FAILED
            _mutex.unlock()
            continue

        var ftp_list = _ftp_request.get_list()
        var lines = ftp_list.split("\n", false)
        var results = []

        for line in lines:
            var status = line.strip_edges()
            if status.begins_with("alpha") or status.begins_with("beta") or status.begins_with("rc"):
                var release = Release.new()
                release.version_number = version
                release.status = status
                release.version_name = "%s-%s" % [release.version_number, release.status]
                release.description = "This is a prerelease of the upcoming Godot %s." % release.version_number

                var file_url = base_url + status + "/" + release.get_download_name("", OS.get_name(), 64)
                error = _ftp_request.request_filetime(file_url)
                if error != OK:
                    push_warning("Error when fetching release info, ignoring: ", file_url)
                    continue

                release.publish_date = _ftp_request.get_filetime()
                if release.publish_date <= 0:
                    continue

                results.append(release)

        _mutex.lock()
        if len(results) >= 0:
            _thread_status = ThreadStatus.RESULTS_READY
            _thread_results = results
        else:
            _thread_status = ThreadStatus.REQUEST_FAILED
        _mutex.unlock()
