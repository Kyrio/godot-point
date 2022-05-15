extends Control


const GODOT_RELEASES_URL = "https://api.github.com/repos/godotengine/godot/releases?per_page=10"
const GODOT_4_DIRECTORY_URL = "ftp://downloads.tuxfamily.org/godotengine/4.0/"

var releases_request := HTTPRequest.new()
var directory_request := FtpRequest.new()


func _ready():
    add_child(releases_request)
    add_child(directory_request)
    releases_request.request_completed.connect(self._releases_request_completed)
    directory_request.request_completed.connect(self._directory_request_completed)
    

func _on_json_pressed():
    var error = releases_request.request(GODOT_RELEASES_URL)
    if error != OK:
        push_error("An error occurred in the JSON request.")


func _on_ftp_pressed():
    var error = directory_request.request_list(GODOT_4_DIRECTORY_URL)
    if error != OK:
        push_error("An error occurred in the FTP request.")


func _releases_request_completed(result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
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
        push_error("Unexpected data")
        return
        
    print("Releases received")


func _directory_request_completed(result: HTTPRequest.Result, body: String):
    if result != HTTPRequest.RESULT_SUCCESS:
        push_error("FTP request returned with an error")
        return
    
    print(body)
