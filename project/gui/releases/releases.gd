extends Control


const GODOT3_RELEASES = "https://api.github.com/repos/godotengine/godot/releases?per_page=10"
const GODOT4_FTP = "ftp://downloads.tuxfamily.org/godotengine/4.0/"

var godot3_request := HTTPRequest.new()
var godot4_request := FtpRequest.new()


func _ready():
    add_child(godot3_request)
    add_child(godot4_request)
    godot3_request.request_completed.connect(self._on_godot3_request_completed)
    godot4_request.request_completed.connect(self._on_godot4_request_completed)


func _on_godot3_request_completed(result: HTTPRequest.Result, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
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


func _on_godot4_request_completed(result: HTTPRequest.Result, body: String):
    if result != HTTPRequest.RESULT_SUCCESS:
        push_error("FTP request returned with an error")
        return
    
    print(body)
