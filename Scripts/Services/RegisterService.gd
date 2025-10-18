extends Object
class_name RegisterService

# Firebase Auth account and Firebase Realtime DB entry are two different things
# This code first creates an auth account, recieves id and tokens and then attempts write to DB
# If auth acc is created but database write fails - it will attempt to rollback auth
# Rollback failure will leave auth account hanging, which requires manual cleanup

const SIGNUP_ENDPOINT := "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key="
const DELETE_ACCOUNT_ENDPOINT := "https://identitytoolkit.googleapis.com/v1/accounts:delete?key="

static func register_user(email: String, password: String, on_success: Callable, on_fail : Callable) -> int:
	var url = SIGNUP_ENDPOINT + Firebase.api_key
	var body = {"email": email, "password": password, "returnSecureToken": true}

	var _profile_write_success = func(_parsed):
			on_success.call(Session)

	var _profile_write_fail = func(err_msg):
		_attempt_delete_auth_then_report(str(err_msg), on_fail)
	
	# This lambda is ugly but i dont want to pass callbacks into callbacks so i will leave it here
	var _signup_success = func(user_data):
		if not user_data is Dictionary or not user_data.has("localId"):
			on_success.call("Unexpected signup response")
			return
		
		Session.from_firebase_response(user_data)
		var profile = {
			"email": Session.email,
			"displayName": user_data.get("displayName", ""),
			"createdAt": int(Time.get_unix_time_from_system())
		}
		
		# Write profile to DB
		var profile_url = "%s/users/%s.json?auth=%s" % \
				[Firebase.project_db_url.trim_suffix("/"), Session.uid, Session.id_token]
		
		Firebase.send_request(
				profile_url,
				HTTPClient.METHOD_PUT,
				profile,
				["Content-Type: application/json"], 
				_profile_write_success,
				_profile_write_fail,
				"write_profile"
		)

	var _signup_fail = func(err_msg):
			on_fail.call(str(err_msg))

	return Firebase.send_request(url, HTTPClient.METHOD_POST, body, ["Content-Type: application/json"], 
			_signup_success, _signup_fail, "signup")

static func _attempt_delete_auth_then_report(original_error: String, on_complete: Callable) -> void:
	
	# Auth rolled back
	var _on_delete_success = func():
		var msg = "Profile write failed; created auth account was deleted. Original error: %s" % \
				original_error
		on_complete.call(msg)
	
	# Rollback failed
	var _on_delete_fail = func(err_msg):
		var msg = "Profile write failed; rollback (delete) failed: %s. Original error: %s" % \
				[err_msg, original_error]
		on_complete.call(msg)

	if Session.id_token == "":
		_on_delete_fail.call("Missing id_token for delete")
		return
	
	var url = DELETE_ACCOUNT_ENDPOINT + Firebase.api_key
	var body = {"idToken": Session.id_token}
	Firebase.send_request(
			url,
			HTTPClient.METHOD_POST,
			body,
			["Content-Type: application/json"],
			_on_delete_success,
			_on_delete_fail,
			"delete_account" 
	)
