extends Object
class_name UserService

const SIGNUP_ENDPOINT := "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key="
const SIGNIN_ENDPOINT := "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="
const DELETE_ACCOUNT_ENDPOINT := "https://identitytoolkit.googleapis.com/v1/accounts:delete?key="
const UPDATE_ENDPOINT = "https://identitytoolkit.googleapis.com/v1/accounts:update?key="

# Firebase Auth account and Firebase Realtime DB entry are two different things
# This code first creates an auth account, recieves id and tokens and then attempts write to DB
# If auth acc is created but database write fails - it will attempt to rollback auth
# Rollback failure will leave auth account hanging, which requires manual cleanup
static func register(
		email: String, 
		user_name:String,
		password: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = SIGNUP_ENDPOINT + Firebase.api_key
	
	var body = {
		"email": email, 
		"displayName":user_name, 
		"password": password, 
		"returnSecureToken": true
	}

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
		
		var profile_url = "%s/users/%s.json" % \
				[Firebase.project_db_url, Session.uid]
		
		Firebase.send_request(
				profile_url,
				HTTPClient.METHOD_PUT,
				profile,
				["Content-Type: application/json"], 
				_profile_write_success,
				_profile_write_fail,
				"auth")

	var _signup_fail = func(err_msg):
			on_fail.call(str(err_msg))

	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_POST, 
			body, 
			["Content-Type: application/json"], 
			_signup_success, 
			_signup_fail,
			"auth")

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
			"auth")

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

	var _on_success = func(user_data):
		if not user_data is Dictionary or not user_data.has("localId"):
			on_fail.call("Unexpected sign-in response")
			return
		
		Session.update_from_response(user_data)
		AppNotifications.push("Signed in as %s" % Session.email)
		on_success.call(Session.uid)
	
	return Firebase.send_request(
			url,
			HTTPClient.METHOD_POST,
			body,
			["Content-Type: application/json"],
			_on_success,
			on_fail,
			"auth")

static func refresh(refresh_token:String,
		on_success:=func(_res):pass, 
		on_fail:=func(_err):pass) -> int:
	
	var refresh_url = "https://securetoken.googleapis.com/v1/token?key=%s" % Firebase.api_key
	var refresh_body = "grant_type=refresh_token&refresh_token=%s" % refresh_token
	var refresh_headers = ["Content-Type: application/x-www-form-urlencoded"]

	var _on_refresh_success = func(parsed):
		if parsed == null or not parsed is Dictionary:
			on_fail.call("invalid_refresh_response")
			return
		
		on_success.call(parsed)

	return Firebase.send_request(
			refresh_url, 
			HTTPClient.METHOD_POST, 
			refresh_body, 
			refresh_headers, 
			_on_refresh_success, 
			on_fail,
			"auth")

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

	updates["users/%s" % uid] = null
	updates["invites/%s" % uid] = null

	var patch_url = "%s/.json?auth=" % [Firebase.project_db_url]

	var _on_patch_success = func(_patch_resp):
		var auth_delete_url =  DELETE_ACCOUNT_ENDPOINT + Firebase.api_key
		var auth_delete_body = {"idToken": Session.id_token}
		
		return Firebase.send_request(
				auth_delete_url, 
				HTTPClient.METHOD_POST, 
				auth_delete_body, 
				["Content-Type: application/json"], 
				on_success, 
				on_fail)

	return Firebase.send_request(
			patch_url, 
			HTTPClient.METHOD_PATCH, 
			updates, 
			["Content-Type: application/json"], 
			_on_patch_success, 
			on_fail)

static func get_user_projects(
		uid, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/users/%s/projects.json?auth=" % [Firebase.project_db_url, Session.uid]
	
	var _on_success = func(result):
		if result == null:
			on_success.call({})
		else:
			on_success.call(result)
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_GET, 
			{}, 
			[], 
			_on_success, 
			on_fail)

static func get_display_name(
		uid: String,
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/users/%s/displayName.json?auth=" % [Firebase.project_db_url, uid]
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_GET, 
			{}, 
			[], 
			on_success, 
			on_fail)

static func get_user_by_email(
		user_email:String,
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var query_url = '%s/users.json?orderBy="email"&equalTo="%s&auth="' % \
			[ Firebase.project_db_url, user_email ]
	
	return Firebase.send_request(
			query_url,
			HTTPClient.METHOD_GET,
			{},
			[],
			on_success,
			on_fail)

static func get_user(
		uid: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/users/%s.json?auth=" % [ Firebase.project_db_url, uid ]
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_GET, 
			{}, 
			[], 
			on_success,
			on_fail)

static func change_name(
		uid: String, 
		new_name: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/users/%s.json?auth=" % [ Firebase.project_db_url, uid ]
	
	var payload = { "displayName": new_name }
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_PATCH, 
			payload, 
			["Content-Type: application/json"], 
			on_success, 
			on_fail)

static func change_email(
		uid: String, 
		new_email: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = UPDATE_ENDPOINT + Firebase.api_key
	
	var auth_body = {
		"idToken": Session.id_token,
		"email": new_email,
		"returnSecureToken": true
	}

	var _on_auth_success = func(resp):
		if resp == null or not resp is Dictionary:
			on_fail.call("invalid_auth_response")
			return

		Session.update_from_response(resp)

		var user_url = "%s/users/%s.json?auth=" % [ Firebase.project_db_url, uid ]
		
		var patch_body = { "email": new_email }

		Firebase.send_request(
				user_url, 
				HTTPClient.METHOD_PATCH, 
				patch_body, 
				["Content-Type: application/json"], 
				on_success, 
				on_fail)

	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_POST, 
			auth_body, 
			["Content-Type: application/json"], 
			_on_auth_success, 
			on_fail)

static func change_password(
		new_password: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = UPDATE_ENDPOINT + Firebase.api_key
	
	var body = {
		"idToken": Session.id_token,
		"password": new_password,
		"returnSecureToken": true
	}
	
	var _on_success = func(resp):
		if resp is Dictionary:
			Session.update_from_response(resp)
		on_success.call(resp)
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_POST, 
			body, 
			["Content-Type: application/json"], 
			_on_success, 
			on_fail)
