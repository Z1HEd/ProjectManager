extends Object
class_name AccountService

const SIGNUP_ENDPOINT := "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key="
const SIGNIN_ENDPOINT := "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="
const DELETE_ACCOUNT_ENDPOINT := "https://identitytoolkit.googleapis.com/v1/accounts:delete?key="

# Firebase Auth account and Firebase Realtime DB entry are two different things
# This code first creates an auth account, recieves id and tokens and then attempts write to DB
# If auth acc is created but database write fails - it will attempt to rollback auth
# Rollback failure will leave auth account hanging, which requires manual cleanup
static func register(
		email: String, 
		password: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = SIGNUP_ENDPOINT + Firebase.api_key
	var body = {"email": email, "password": password, "returnSecureToken": true}

	var _profile_write_success = func(_parsed):
			on_success.call(Session)

	var _profile_write_fail = func(err_msg):
		_attempt_delete_auth_then_report(str(err_msg), on_fail)
	
	# This lambda is ugly but i dont want to pass callbacks into callbacks 
	# so i will leave it as is
	var _signup_success = func(user_data):
		if not user_data is Dictionary or not user_data.has("localId"):
			on_success.call("Unexpected signup response")
			return
		
		Session.update_from_response(user_data)
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
				"auth"
		)

	var _signup_fail = func(err_msg):
			on_fail.call(str(err_msg))

	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_POST, 
			body, 
			["Content-Type: application/json"], 
			_signup_success, 
			_signup_fail
	)

static func _attempt_delete_auth_then_report(
		original_error: String, 
		on_complete: Callable) -> void:
	
	# Auth rolled back
	var _on_delete_success = func():
		var msg = "Profile write failed; created auth account was deleted. Original error: %s" % \
				original_error
		on_complete.call(msg)
	
	# Rollback failed
	var _on_delete_fail = func(err_msg):
		var msg = "Profile write failed; rollback failed: %s. Original error: %s" % \
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
			"auth"
	)

static func login(
		email: String, 
		password: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = SIGNIN_ENDPOINT + Firebase.api_key
	var body = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}

	var _signin_success = func(user_data):
		if not user_data is Dictionary or not user_data.has("localId"):
			on_fail.call("Unexpected sign-in response")
			return
		
		Session.update_from_response(user_data)
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
			"auth"
	)

static func delete_user(
		uid: String, 
		projects_dict: Dictionary, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	for pid in projects_dict.keys():
		if projects_dict[pid] == "owner":
			on_fail.call("Cannot delete owner of any project!")
			return -1
	

	var updates := {}
	for pid in projects_dict.keys():
		updates["projects/%s/members/%s" % [pid, uid]] = null
		updates["users/%s/projects/%s" % [uid, pid]] = null
		updates["invites/%s/%s" % [uid, pid]] = null

	updates["users/%s" % uid] = null
	updates["invites/%s" % uid] = null

	var patch_url = "%s/.json?auth=%s" % \
			[Firebase.project_db_url.trim_suffix("/"), Session.id_token]

	var _on_patch_success = func(_patch_resp):
		var auth_delete_url =  DELETE_ACCOUNT_ENDPOINT + Firebase.api_key
		var auth_delete_body = {"idToken": Session.id_token}
		
		var _on_success = func(_res):
			on_success.call("user_deleted")
		var _on_fail = func(err_msg:String):
			on_fail.call("db_cleaned_but_auth_delete_failed: %s" % err_msg)
		
		return Firebase.send_request(
				auth_delete_url, 
				HTTPClient.METHOD_POST, 
				auth_delete_body, 
				["Content-Type: application/json"], 
				_on_success, 
				_on_fail
		)

	var _on_patch_fail = func(err):
		on_fail.call("db_cleanup_failed: %s" % str(err))

	return Firebase.send_request(
			patch_url, 
			HTTPClient.METHOD_PATCH, 
			updates, 
			["Content-Type: application/json"], 
			_on_patch_success, 
			_on_patch_fail
	)
