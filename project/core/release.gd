class_name Release
extends RefCounted

## A released version of Godot, either stable (usually obtained through GitHub)
## or a pre-release (from mirrors).

## A release may come with various module configs: none for a standard build,
## or Mono in a build with C# support.
enum ModuleConfig { NONE, MONO }

## The release's version number without any prefix or suffix, e.g. "3.5" or "4.0".
var version_number: String

## The maturity of the release in the software lifecycle, e.g. "stable", "beta3", "rc1".
var status: String

## A prettier name used on GitHub, usually comprised of the version number and status
## (e.g. 3.4.4-stable).
var version_name: String

## The Unix timestamp at which the release was published either on GitHub or mirrors.
var publish_date: int

## A short description of the release, usually the first line of the GitHub release description.
var description: String


## Returns a [Release] constructed from Godot GitHub release data.
static func from_github_release(data: Dictionary) -> Release:
    var release = Release.new()
    release.version_name = data.get("name", "Version")
    
    var tag_name = data.get("tag_name") as String
    var published_at = data.get("published_at") as String
    var body_text = data.get("body_text") as String
    
    if tag_name:
        var splits = tag_name.split("-", false)
        
        if len(splits) == 2:
            release.version_number = splits[0]
            release.status = splits[1]
    
    if published_at:
        release.publish_date = Time.get_unix_time_from_datetime_string(published_at)
        
    if body_text:
        release.description = body_text.get_slice("\n", 0)
        
    return release


## Returns the name of the archive corresponding to this [Release] and the
## provided [member ModuleConfig], platform (as returned by [method OS.get_name]) and CPU bits.
func get_download_filename(module_config: ModuleConfig, platform: String, bits: int) -> String:
    var os = ""
    var exe = ""
    
    match platform:
        "Windows", "UWP":
            if module_config == ModuleConfig.MONO:
                os = "win%d" % bits
                exe = ""
            else:
                os = "win%d" % bits
                exe = ".exe"
        "macOS":
            if version_number.begins_with("3.3") and module_config == ModuleConfig.MONO:
                os = "osx"
                exe = ".%d" % bits     # Careful, there are no 32-bit releases
            if version_number.begins_with("3.2") or version_number.begins_with("3.1"):
                os = "osx"
                exe = ".%d" % bits     # Careful, there are no 32-bit releases
            elif version_number.begins_with("3.0"):
                os = "osx"
                exe = ".fat"
            else:
                os = "osx"
                exe = ".universal"
        "Linux":
            if module_config == ModuleConfig.MONO:
                os = "x11_%d" % bits
                exe = ""
            else:
                os = "linux" if version_number == "4.0" else "x11"
                exe = ".%d" % bits
    
    var module_suffix = ""
    if module_config == ModuleConfig.MONO:
        module_suffix = "_mono"
    
    var download_name = "Godot_v%s-%s%s_%s%s.zip" % [version_number, status, module_suffix, os, exe]
    return download_name
