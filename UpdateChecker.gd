extends Node

const _GITHUB_API = "https://api.github.com/repos/{owner}/{repo}/releases"
const _AUTHOR = "LFind"
const _REPO = "AlbionLogReader"

const STATUS_UNKNOWN = -1
const STATUS_OLD = 0
const STATUS_LATEST = 1

var _response_code:int = -1
var _status:int = STATUS_UNKNOWN
var _list_releases:Array
var _latest_release:Dictionary
var _request = HTTPRequest.new()

signal new_release
signal search_start
signal search_end
signal download_start
signal download_end

func _ready():
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)
	if Settings.get_search_update_on_launch():
		check_updates()

func check_updates():
	search_start.emit()
	_request.request(_GITHUB_API.format({ "owner": _AUTHOR, "repo": _REPO }))

func get_download_link() -> String:
	if _latest_release.has("assets") and _latest_release["assets"].size() > 0:
		return _latest_release["assets"][0]["browser_download_url"]
	else:
		return ""

func get_response() -> int:
	return _response_code

func get_status() -> int:
	return _status

func get_latest_version() -> String:
	return _latest_release.get("tag_name", Settings.VERSION)

func get_latest_release_link() -> String:
	return _latest_release.get("html_url","")

func _on_request_completed(result, response_code, headers, body):
	_response_code = response_code
	if response_code != 200:
		_status = STATUS_UNKNOWN
		_on_search_complete()
		return
	
	_list_releases = str_to_var(body.get_string_from_utf8())
	_latest_release = _list_releases[0]
	var latest_version = _latest_release["tag_name"]
	
	var compare_result = _compare_versions(latest_version, Settings.VERSION)
	if compare_result > 0:
		_status = STATUS_OLD
		var download_url = _latest_release["html_url"]
	elif compare_result == 0:
		_status = STATUS_LATEST
	else:
		_status = STATUS_UNKNOWN
	_on_search_complete()

func _on_search_complete():
	match get_status():
		STATUS_LATEST: 
			print("Current version: v{version}\nNew version not found".format({
				"version": Settings.VERSION
			}))
		STATUS_OLD:
			print("Current version: v{version}\nNew version available: v{new_version}\nLink: {link}"
			.format({
				"version": Settings.VERSION,
				"new_version": get_latest_version(),
				"link": get_download_link()
			}))
		STATUS_UNKNOWN:
			if _response_code != 200:
				printerr("Something wrong on update check! Response: {response}"
				.format({
						"response": _response_code
				}))
			else:
				printerr("Something wrong on update check!. Current version is v{version}, but latest availble: v{new_version}"
				.format({"version": Settings.VERSION,
					"new_version": get_latest_version()
				}))
	
	search_end.emit()

func _compare_versions(version1: String, version2: String) -> int:
	var v1 = version1.replace("b","").to_float()
	var v2 = version2.replace("b","").to_float()
	
	var v1_is_beta = version1.ends_with("b")
	var v2_is_beta = version2.ends_with("b")
	
	# Сравнение релизов
	if v1 > v2:
		return 1
	elif v1 < v2:
		return -1
	
	# Cравнение стадии
	if v1_is_beta and not v2_is_beta:
		return 1
	elif not v1_is_beta and v2_is_beta:
		return -1
	
	return 0
