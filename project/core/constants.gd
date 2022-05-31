class_name Constants
extends Object


const NEXT_MINOR_VERSION = "3.5"
const NEXT_MAJOR_VERSION = "4.0"

const STABLE_RELEASES_API = "https://api.github.com/repos/godotengine/godot/releases?per_page=10"
const PRERELEASES_FTP = "ftp://downloads.tuxfamily.org/godotengine/"

const GITHUB_HEADERS = ["Accept: application/vnd.github.text+json"]

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


## Returns the date, and only the date, corresponding to the provided timestamp,
## in the format used by GitHub: e.g. "23 Mar 2022"
static func get_pretty_date_from_timestamp(timestamp: int) -> String:
    var datetime_dict = Time.get_date_dict_from_unix_time(timestamp)
    datetime_dict["month_name"] = MONTHS[datetime_dict["month"] - 1]
    
    return "{day} {month_name} {year}".format(datetime_dict)
