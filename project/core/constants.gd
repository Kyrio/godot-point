class_name Constants
extends Object


const BITS = 64

const NEXT_MINOR_VERSION = "3.5"
const NEXT_MAJOR_VERSION = "4.0"

const EARLIEST_SUPPORTED_MAJOR = 3
const EARLIEST_SUPPORTED_RELEASE = "3.0.6-stable"

const STABLE_RELEASES_API = "https://api.github.com/repos/godotengine/godot/releases?per_page=10"
const PRERELEASES_FTP = "ftp://downloads.tuxfamily.org/godotengine/"

const TUXFAMILY_DOWNLOADS = "https://downloads.tuxfamily.org/godotengine/"
const GITHUB_RELEASES_DOWNLOADS = "https://github.com/godotengine/godot/releases/download/"
const GITHUB_FIRST_RELEASE_TIME = 1562835880

const GITHUB_HEADERS = ["Accept: application/vnd.github.text+json"]

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


## Returns the date, and only the date, corresponding to the provided timestamp,
## in the format used by GitHub: e.g. "23 Mar 2022"
static func get_pretty_date_from_timestamp(timestamp: int) -> String:
    var datetime_dict = Time.get_date_dict_from_unix_time(timestamp)
    datetime_dict["month_name"] = MONTHS[datetime_dict["month"] - 1]
    
    return "{day} {month_name} {year}".format(datetime_dict)


## Returns the URL used to download the given [Release] and [member Release.ModuleConfig]
## (usually empty or "mono") from TuxFamily servers.
static func get_tuxfamily_download_url(release: Release, module_config: Release.ModuleConfig) -> String:
    if module_config == Release.ModuleConfig.MONO:
        return Constants.TUXFAMILY_DOWNLOADS + release.version_number + (
            "/mono/" if release.status == "stable" else "/%s/mono/" % release.status
        ) + release.get_download_filename(module_config, OS.get_name(), BITS)
    else:
        return Constants.TUXFAMILY_DOWNLOADS + release.version_number + (
            "/" if release.status == "stable" else "/%s/" % release.status
        ) + release.get_download_filename(module_config, OS.get_name(), BITS)


## Returns the URL used to download the given [Release] and config from GitHub Releases.
## The URL won't be valid for prereleases, which are not stored on GitHub.
static func get_github_releases_download_url(release: Release, module_config: Release.ModuleConfig) -> String:
    return GITHUB_RELEASES_DOWNLOADS + release.version_name + "/" + release.get_download_filename(module_config, OS.get_name(), BITS)
