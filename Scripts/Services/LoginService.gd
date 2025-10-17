extends Object
class_name LoginService

const SIGNIN_ENDPOINT := "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="

# on_success(session) or on_fail(err_msg)
static func signin_user(email: String, password: String, on_success = null, on_fail = null) -> int:
	var url = SIGNIN_ENDPOINT + Firebase.api_key
	var body = {"email": email, "password": password, "returnSecureToken": true}
	var success_cb = _on_signin_success.bind(on_success, on_fail)
	var fail_cb = _on_signin_fail.bind(on_fail)
	return Firebase.send_request(url, HTTPClient.METHOD_POST, body, ["Content-Type: application/json"], success_cb, fail_cb, "signin")

static func _on_signin_success(user_data: Dictionary, on_success: Callable, on_fail: Callable) -> void:
	if typeof(user_data) == TYPE_DICTIONARY and user_data.has("localId"):
		Session.from_firebase_response(user_data)
		# optionally load profile from DB here; for now call on_success immediately
		if on_success and on_success is Callable:
			on_success.call(UserSession)
	else:
		if on_fail and on_fail is Callable:
			on_fail.call("Unexpected signin response")

static func _on_signin_fail(err_msg: String, on_fail: Callable) -> void:
	if on_fail and on_fail is Callable:
		on_fail.call(err_msg)
