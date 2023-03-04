extends Node

const GITHUB_API = "https://api.github.com/repos/{owner}/{repo}/releases"
const AUTHOR = "LFind"
const REPO = "AlbionLogReader"

var list_releases:Array
var latest_release:Dictionary
var request = HTTPRequest.new()

func _ready():
	add_child(request)
	check_updates()

func check_updates():
	request.request_completed.connect(_on_request_completed)
	request.request(GITHUB_API.format({ "owner": AUTHOR, "repo": REPO }))

func get_download_link() -> String:
	if latest_release.has("assets") and latest_release["assets"].size() > 0:
		return latest_release["assets"][0]["browser_download_url"]
	else:
		return ""

func get_latest_version() -> String:
	return latest_release.get("tag_name", Settings.VERSION)

func get_latest_release_link() -> String:
	return latest_release.get("html_url","")

func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		return
	
	list_releases = str_to_var(body.get_string_from_utf8())
	latest_release = list_releases[0]
	var latest_version = latest_release["tag_name"]
	
	var compare_result = _compare_versions(latest_version, Settings.VERSION)
	if compare_result > 0:
		# There's a newer version available
		var download_url = latest_release["html_url"]
		print("Current version: v", Settings.VERSION)
		print("New version available: ", latest_version)
		print("Download it here: ", download_url)
		Event.new_release.emit()
	elif compare_result == 0:
		print("Current version: v", Settings.VERSION)
		print("New version not found.")
	else:
		printerr("Something wrong on update check!. Current version is v{curr}, but latest availble: v{last}"
			.format({"curr": Settings.VERSION, "last": latest_version}) )

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
