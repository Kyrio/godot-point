extends Node


var is_downloading = false
var is_extracting = false
var current_download_release: Release
var current_download_module_config: Release.ModuleConfig
var current_download_progress = 0.0
var current_download_bytes = 0

var _update_countdown = 0.0
var _download_filename: String
var _extract_process = -1
var _extract_dirname: String

@onready var download_request := $DownloadRequest as HTTPRequest


func _process(delta):
    if not is_downloading:
        return
    
    if is_extracting:
        if OS.is_process_running(_extract_process):
            return
        
        _install_release()
        is_downloading = false
        is_extracting = false
    
    _update_countdown -= delta
    if _update_countdown > 0.0:
        return
    
    _update_countdown = 0.5
    
    match download_request.get_http_client_status():
        HTTPClient.STATUS_BODY:
            current_download_bytes = download_request.get_downloaded_bytes()
            var total_bytes = download_request.get_body_size()
            
            if total_bytes > 0:
                current_download_progress = float(current_download_bytes) / total_bytes
            else:
                current_download_progress = 0.0
        
        _:
            current_download_progress = 0.0


func start_download(release: Release, module_config: Release.ModuleConfig):
    if is_downloading:
        return
    
    var mirror = ConfigManager.get_setting("core", "download_mirror")
    var url: String
    
    if mirror == ConfigManager.Mirror.GITHUB and release.status == "stable" and release.publish_date >= Constants.GITHUB_FIRST_RELEASE_TIME:
        url = Constants.get_github_releases_download_url(release, module_config)
    else:
        url = Constants.get_tuxfamily_download_url(release, module_config)

    _download_filename = release.get_download_filename(module_config, OS.get_name(), Constants.BITS)
    download_request.download_file = "user://download_cache".plus_file(_download_filename)
    
    var error = download_request.request(url)
    if error == OK:
        is_downloading = true
        is_extracting = false
        current_download_release = release
        current_download_module_config = module_config
        current_download_progress = 0.0
        current_download_bytes = 0
    else:
        push_error("Error when creating download request.")


func _on_download_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        push_error("Download request returned with error ", result , "and response code ", response_code)
        return
    
    _extract_dirname = _download_filename.get_slice(".zip", 0)
    
    var cache_path = ProjectSettings.globalize_path("user://download_cache")
    var extract_path = cache_path.plus_file(_extract_dirname)
    var zip_path = cache_path.plus_file(_download_filename)
    
    match OS.get_name():
        "Windows", "UWP":
            _extract_process = OS.create_process("powershell.exe", ["-Command", "Expand-Archive", zip_path, "-DestinationPath", extract_path])
            
    if _extract_process < 0:
        push_error("Cannot extract the release, this might be an unsupported platform.")
        is_downloading = false
        return
    
    is_extracting = true


func _install_release():
    var working_dir = Directory.new()
    working_dir.open("user://download_cache")
    
    if not working_dir.dir_exists(_extract_dirname):
        push_error("The release wasn't extracted properly.")
        return
    
    working_dir.remove(_download_filename)
    
    var installs_path = ConfigManager.get_setting("paths", "installs") as String
    var installs_dir = Directory.new()
    if installs_dir.open(installs_path) != OK:
        push_error("Could not open the configured install directory.")
        return
    
    if not installs_dir.dir_exists(current_download_release.version_name):
        if installs_dir.make_dir(current_download_release.version_name) != OK:
            push_error("Could not create a directory for the release.")
            return
    
    var release_path = installs_path.plus_file(current_download_release.version_name)
    match current_download_module_config:
        Release.ModuleConfig.NONE:
            release_path = release_path.plus_file("standard")
        
        Release.ModuleConfig.MONO:
            release_path = release_path.plus_file("mono")
    
    var move_error
    var redundant_dir = _extract_dirname.plus_file(_extract_dirname)
    
    if working_dir.dir_exists(redundant_dir):
        move_error = working_dir.rename(redundant_dir, release_path)
        
        if move_error == OK:
            working_dir.remove(_extract_dirname)
    else:
        move_error = working_dir.rename(_extract_dirname, release_path)

    if move_error != OK:
        push_error("Could not move the release to the configured install directory.")
        return
        
    InstallManager.register_install(current_download_release, current_download_module_config, release_path)
