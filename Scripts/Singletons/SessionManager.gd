extends Node
class_name SessionManager

var uid: String = ""
var email: String = ""
var session_persist : bool = false # default OFF

var id_token: String = ""
var refresh_token: String = ""
var expires_at: int = 0

var refresh_timer : Timer

const REFRESH_DELAY_SECS := 3300
const RETRY_DELAY_SECS := 15
const AUTH_CFG_PATH := "user://auth.cfg"

signal authenticated
signal refreshed

func _ready() -> void:
	session_persist = _load_from_config()
	
	refresh_timer = Timer.new()
	add_child(refresh_timer)
	
	var _on_fail = func(_msg:String):
		refresh_timer.start(RETRY_DELAY_SECS)
	
	refresh_timer.timeout.connect(refresh_tokens.bind(func(_res):pass, _on_fail))

func set_session_persist(enable: bool) -> void:
	if session_persist == enable:
		return
	session_persist = enable
	if session_persist:
		_save_to_config()
	elif FileAccess.file_exists(AUTH_CFG_PATH):
		DirAccess.remove_absolute(AUTH_CFG_PATH)

func refresh_tokens(on_success:=func(_res):pass, on_fail:=func(_err):pass) -> int:
	if refresh_token == "":
		on_fail.call("no_refresh_token")
		return -1

	var _on_success = func(parsed: Dictionary):
		update_from_response(parsed)
		on_success.call(parsed)
		refreshed.emit()
	
	var _on_fail = func(err:String):
		on_fail.call(err)
		AppNotifications.push("Failed to refresh session: \n%s" % err)
	
	return UserService.refresh(refresh_token,_on_success,_on_fail)

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
	
	refresh_timer.start(REFRESH_DELAY_SECS)
	_save_to_config()
	authenticated.emit()

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
	
	refresh_timer.stop()
	
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
		AppNotifications.call_deferred("push",
				"Found saved session!\nAttempting to refresh...")
		refresh_tokens(func(_parsed):
			AppNotifications.push("Authomatically signed in as:\n%s" % email))
		return true
	return false
