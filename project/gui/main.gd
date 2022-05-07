extends Control


const GODOT_RELEASES_URL = "https://api.github.com/repos/godotengine/godot/releases?per_page=20"


func _ready():
    var releases_request := HTTPRequest.new()
    add_child(releases_request)
    releases_request.request_completed.connect(self._releases_request_completed)

#    var error = releases_request.request(GODOT_RELEASES_URL)
#    if error != OK:
#        push_error("An error occurred in the HTTP request.")


func _releases_request_completed(result, response_code, _headers, body):
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        push_error("Request returned with code ", response_code)
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
