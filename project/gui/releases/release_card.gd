class_name ReleaseCard
extends PanelContainer


const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

var is_latest: bool
var release_data: Dictionary

@onready var _version := get_node("%Version") as Label
@onready var _latest := get_node("%Latest") as Label
@onready var _date := get_node("%Date") as Label
@onready var _description := get_node("%Description") as Label


func _ready():
    if release_data.is_empty():
        return
    
    _humanize_release_data()
    
    _version.text = release_data.get("name", "Version")
    _latest.visible = is_latest
    _date.text = release_data.get("pretty_date", "Release date")
    _description.text = release_data.get("short_description", "Description of the release.")


func _humanize_release_data():
    var publish_date := release_data.get("published_at") as String
    var body_text := release_data.get("body_text") as String
    
    if publish_date:
        var datetime = Time.get_datetime_dict_from_datetime_string(publish_date, false)
        datetime["month_name"] = MONTHS[datetime["month"] - 1]
        release_data["pretty_date"] = "{day} {month_name} {year}".format(datetime)
        
    if body_text:
        release_data["short_description"] = body_text.get_slice("\n", 0)
