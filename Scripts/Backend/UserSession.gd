extends Node
class_name UserSession

var uid: String = ""
var email: String = ""
var id_token: String = ""
var refresh_token: String = ""
var expires_at: int = 0

const AUTH_CFG_PATH := "user://auth.cfg"

func _ready() -> void:
	_load_from_config()

func from_firebase_response(data: Dictionary) -> void:
	# data is the parsed auth response from Firebase
	if not data is Dictionary:
		return
	uid = str(data.get("localId", ""))
	email = str(data.get("email", ""))
	id_token = str(data.get("idToken", ""))
	refresh_token = str(data.get("refreshToken", ""))
	var expires_in = int(data.get("expiresIn", 0))
	expires_at = int(Time.get_unix_time_from_system()) + expires_in
	_save_to_config()

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
	var cfg = ConfigFile.new()
	cfg.remove_section("auth")
	cfg.save(AUTH_CFG_PATH)

func _save_to_config() -> void:
	var cfg = ConfigFile.new()
	cfg.load(AUTH_CFG_PATH)
	cfg.set_value("auth", "refresh_token", refresh_token)
	cfg.set_value("auth", "uid", uid)
	cfg.set_value("auth", "email", email)
	cfg.set_value("auth", "expires_at", expires_at)
	cfg.save(AUTH_CFG_PATH)

func _load_from_config() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(AUTH_CFG_PATH) == OK:
		refresh_token = str(cfg.get_value("auth", "refresh_token", ""))
		uid = str(cfg.get_value("auth", "uid", ""))
		email = str(cfg.get_value("auth", "email", ""))
		expires_at = int(cfg.get_value("auth", "expires_at", 0))
