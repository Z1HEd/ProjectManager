extends Object
class_name ProfileService

# write profile to /users/{uid}.json (PUT) or PATCH if use_patch true
static func create_user_profile(uid: String, profile: Dictionary, on_success = null, on_fail = null, use_patch: bool = false) -> int:
	if Session.id_token == "":
		if on_fail and on_fail is Callable:
			on_fail.call(uid, "Missing id_token")
		return -1
	var method = HTTPClient.METHOD_PATCH if use_patch else HTTPClient.METHOD_PUT
	var url = "%s/users/%s.json?auth=%s" % [Firebase.project_db_url.trim_suffix("/"), uid, Session.id_token]

	# IMPORTANT: Callable.bind() appends bound args after call-time args.
	# We need the 'parsed' result from Firebase to be passed as the LAST arg to our internal handler,
	# so create small wrapper lambdas that call the real handler with the correct ordering.
	var success_cb = func(parsed):
		# parsed is the JSON response parsed by FirebaseManager; forward in expected order
		_on_profile_write_success(on_success, uid, parsed)

	var fail_cb = func(err_msg):
		_on_profile_write_fail(on_fail, uid, err_msg)

	return Firebase.send_request(url, method, profile, ["Content-Type: application/json"], success_cb, fail_cb, "write_profile")

static func _on_profile_write_success(on_success: Callable, uid: String, _parsed) -> void:
	if on_success and on_success is Callable:
		on_success.call(uid)

static func _on_profile_write_fail(on_fail: Callable, uid: String, err_msg: String) -> void:
	if on_fail and on_fail is Callable:
		on_fail.call(uid, err_msg)
