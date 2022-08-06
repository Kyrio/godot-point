class_name Install
extends RefCounted

## An installed copy of Godot, characterized by its version, configuration
## and install directory.

## The Godot version, usually comprised of the version number and status
## (e.g. 3.4.4-stable).
var version_name: String

## An install is a specific configuration of a Godot release: [member Release.ModuleConfig.NONE] for a standard build,
## [member Release.ModuleConfig.MONO] for a build with C# support.
var module_config: Release.ModuleConfig

## The path to the directory in which lies the executable.
## This might be in user:// and therefore must be globalized before display.
var install_path: String
