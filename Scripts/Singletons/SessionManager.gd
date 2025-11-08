extends Node
class_name SessionManager

var uid: String = ""
var email: String = ""
var session_persist : bool = false # default OFF

var id_token: String = ""
var refresh_token: String = ""
var expires_at: int = 0

var _refresh_in_progress: bool = false
var _refresh_waiters: Array = []

const AUTH_CFG_PATH := "user://auth.cfg"

signal on_authenticated

func _ready() -> void:
	print("HI")
	if _load_from_config():
		print("true")
		session_persist = true
	else:
		print("false")
		session_persist = false

func set_session_persist(enable: bool) -> void:
	if session_persist == enable:
		return
	session_persist = enable
	if session_persist:
		_save_to_config()
	elif FileAccess.file_exists(AUTH_CFG_PATH):
		DirAccess.remove_absolute(AUTH_CFG_PATH)

func ensure_fresh_token(on_ready:=func():pass, on_fail:=func():pass) -> void:
	if not is_token_expired():
		on_ready.call()
		return

	_refresh_waiters.append({
		"on_ready": on_ready,
		"on_fail": on_fail
	})

	if _refresh_in_progress:
		return
	_refresh_in_progress = true

	var _on_refresh_success = func(_resp):
		_refresh_in_progress = false
		for w in _refresh_waiters:
			w["on_ready"].call()
		_refresh_waiters.clear()

	var _on_refresh_fail = func(err):
		_refresh_in_progress = false
		for w in _refresh_waiters:
			w["on_fail"].call(err)
		_refresh_waiters.clear()

	refresh_tokens(_on_refresh_success, _on_refresh_fail)

func refresh_tokens(on_success:=func(_res):pass, on_fail:=func(_err):pass) -> int:
	if refresh_token == "":
		on_fail.call("no_refresh_token")
		return -1
	
	var refresh_url = "https://securetoken.googleapis.com/v1/token?key=%s" % Firebase.api_key
	var refresh_body = "grant_type=refresh_token&refresh_token=%s" % str(refresh_token)
	var refresh_headers = ["Content-Type: application/x-www-form-urlencoded"]

	var _on_refresh_success = func(parsed):
		if parsed == null or not parsed is Dictionary:
			on_fail.call("invalid_refresh_response")
			return
			
		update_from_response(parsed)

		on_success.call(parsed)

	var _on_refresh_fail = func(err):
		on_fail.call(err)

	return Firebase.send_request(
			refresh_url, 
			HTTPClient.METHOD_POST, 
			refresh_body, 
			refresh_headers, 
			_on_refresh_success, 
			_on_refresh_fail,
			"auth"
	)

func update_from_response(response: Dictionary) -> void:
	if response == null:
		return

	if response.has("localId"):
		uid = str(response["localId"])
	elif response.has("user_id"):
		uid = str(response["user_id"])

	if response.has("email"):
		email = str(response["email"])

	if response.has("idToken"):
		id_token = str(response["idToken"])
	elif response.has("id_token"):
		id_token = str(response["id_token"])

	if response.has("refreshToken"):
		refresh_token = str(response["refreshToken"])
	elif response.has("refresh_token"):
		refresh_token = str(response["refresh_token"])

	if response.has("expiresIn"):
		var secs = int(response["expiresIn"])
		expires_at = int(Time.get_unix_time_from_system()) + secs
	elif response.has("expires_in"):
		var secs2 = int(response["expires_in"])
		expires_at = int(Time.get_unix_time_from_system()) + secs2

	_save_to_config()

	if uid != "" and id_token != "":
		emit_signal("on_authenticated")

func is_logged_in() -> bool:
	return uid != "" and id_token != ""

func is_token_expired() -> bool:
	return id_token == "" or int(Time.get_unix_time_from_system()) >= expires_at - 30

func clear() -> void:
	uid = ""
	email = ""
	id_token = ""
	refresh_token = ""
	expires_at = 0
	# always remove persisted file when clearing session
	if FileAccess.file_exists(AUTH_CFG_PATH):
		DirAccess.remove_absolute(AUTH_CFG_PATH)

func _save_to_config() -> void:
	if not session_persist:
		return
	var cfg = ConfigFile.new()
	cfg.load(AUTH_CFG_PATH)
	cfg.set_value("auth", "refresh_token", refresh_token)
	cfg.set_value("auth", "uid", uid)
	cfg.set_value("auth", "email", email)
	cfg.save(AUTH_CFG_PATH)

# Returns true if config existed and was loaded
func _load_from_config() -> bool:
	var cfg = ConfigFile.new()
	if cfg.load(AUTH_CFG_PATH) == OK:
		refresh_token = str(cfg.get_value("auth", "refresh_token", ""))
		uid = str(cfg.get_value("auth", "uid", ""))
		email = str(cfg.get_value("auth", "email", ""))
		refresh_tokens()
		return true
	return false
