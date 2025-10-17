extends Object
class_name RegisterService

const SIGNUP_ENDPOINT := "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key="

# on_success(session) or on_fail(err_msg)
static func register_user(email: String, password: String, on_success = null, on_fail = null) -> int:
	var url = SIGNUP_ENDPOINT + Firebase.api_key
	var body = {"email": email, "password": password, "returnSecureToken": true}
	# callback when Firebase low-level request succeeds
	var success_cb = _on_register_success.bind(on_success, on_fail)
	var fail_cb = _on_register_fail.bind(on_fail)
	return Firebase.send_request(url, HTTPClient.METHOD_POST, body, ["Content-Type: application/json"], success_cb, fail_cb, "signup")

static func _on_register_success(user_data: Dictionary, on_success: Callable, on_fail: Callable) -> void:
	# initialize session
	if typeof(user_data) == TYPE_DICTIONARY and user_data.has("localId"):
		Session.from_firebase_response(user_data)
		# build minimal profile and write to DB; chain original on_success after profile write
		var profile = {
			"email": Session.email,
			"displayName": user_data.get("displayName", ""),
			"createdAt": int(Time.get_unix_time_from_system())
		}
		var profile_success = _on_profile_then_register_success.bind(on_success)
		var profile_fail = _on_profile_then_register_fail.bind(on_fail)
		# delegate to ProfileService
		ProfileService.create_user_profile(Session.uid, profile, profile_success, profile_fail)
	else:
		if on_fail and on_fail is Callable:
			on_fail.call("Unexpected signup response")

static func _on_register_fail(err_msg: String, on_fail: Callable) -> void:
	if on_fail and on_fail is Callable:
		on_fail.call(err_msg)

static func _on_profile_then_register_success(_uid: String,original_on_success: Callable) -> void:
	if original_on_success and original_on_success is Callable:
		original_on_success.call(UserSession)

static func _on_profile_then_register_fail(_uid: String, err_msg: String, original_on_fail: Callable) -> void:
	if original_on_fail and original_on_fail is Callable:
		original_on_fail.call(err_msg)
