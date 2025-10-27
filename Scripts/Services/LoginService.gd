extends Object
class_name LoginService

const SIGNIN_ENDPOINT := "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="

static func login_user(email: String, password: String, on_success: Callable, on_fail: Callable) -> int:
	var url = SIGNIN_ENDPOINT + Firebase.api_key
	var body = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}

	var _signin_success = func(user_data):
		if not user_data is Dictionary or not user_data.has("localId"):
			print(user_data)
			on_fail.call("Unexpected sign-in response")
			return
		
		Session.from_firebase_response(user_data)
		on_success.call(Session)

	var _signin_fail = func(err_msg):
		on_fail.call(str(err_msg))

	return Firebase.send_request(
			url,
			HTTPClient.METHOD_POST,
			body,
			["Content-Type: application/json"],
			_signin_success,
			_signin_fail,
			"signin"
	)
