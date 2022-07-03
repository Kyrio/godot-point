extends Node


var is_downloading = false
var current_download_release: Release
var current_download_module_config: Release.ModuleConfig

@onready var download_request := $DownloadRequest as HTTPRequest


func start_download(release: Release, module_config: Release.ModuleConfig):
    if is_downloading:
        return
    
    var mirror = ConfigManager.get_setting("core", "download_mirror")
    var url: String
    
    if mirror == ConfigManager.Mirror.GITHUB and release.status == "stable" and release.publish_date >= Constants.GITHUB_FIRST_RELEASE_TIME:
        url = Constants.get_github_releases_download_url(release, module_config)
    else:
        url = Constants.get_tuxfamily_download_url(release, module_config)

    download_request.download_file = "user://download_cache/" + release.get_download_filename(module_config, OS.get_name(), Constants.BITS)
    
    var error = download_request.request(url)
    if error == OK:
        is_downloading = true
    else:
        push_error("Error when creating download request.")


func _on_download_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
    is_downloading = false
    
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        push_error("Download request returned with error ", result , "and response code ", response_code)
        return
    
    var zip_file = ProjectSettings.globalize_path(download_request.download_file)
    var extract_directory = ProjectSettings.globalize_path(download_request.download_file.get_slice(".zip", 0))
    
    print("Unpacking...")

    match OS.get_name():
        "Windows", "UWP":
            OS.create_process("powershell.exe", ["-Command", "Expand-Archive", zip_file, "-DestinationPath", extract_directory])
