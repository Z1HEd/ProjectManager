extends Object
class_name ProjectService

# Note: users have a list of ids and roles of projects they are in
# to speed up project list lookup. 
# no project delete if failed to write to users- this is not crucial.

static func create_project(project_name: String, description: String, on_success: Callable, on_fail: Callable) -> int:
	var url = "%s/projects.json?auth=%s" % [Firebase.project_db_url, Session.id_token]
	
	var body = {
		"name": project_name,
		"description": description,
		"owner": Session.uid,
		"creationDate": int(Time.get_unix_time_from_system()),
		"members": {
			Session.uid:"owner"
		}
	}
	
	var _on_project_created = func(response):
		if !response is Dictionary:
			on_fail.call("Invalid response from Firebase: %s" % response)
		var uid = response.get("name","")
		add_project_to_current_user(uid,"owner",on_success,on_fail)
	
	return Firebase.send_request(url, 
			HTTPClient.METHOD_POST, 
			body, 
			["Content-Type: application/json"], 
			_on_project_created, 
			on_fail
	)

static func add_project_to_current_user(uid : String,role : String ,on_success : Callable, on_fail : Callable) -> int:
	var url = "%s/users/%s/projects.json?auth=%s" % [Firebase.project_db_url, Session.uid, Session.id_token]
	var body = { uid: role }
	
	var _on_success = func(response):
		if not response is Dictionary:
			on_fail.call("Invalid response: %s" % response)
		on_success.call(uid)
	
	return Firebase.send_request(url, HTTPClient.METHOD_PATCH, body, ["Content-Type: application/json"], _on_success, on_fail)

static func get_project(pid: String,on_success : Callable, on_fail : Callable) -> int:
	var url = "%s/projects/%s.json?auth=%s" % [Firebase.project_db_url, pid, Session.id_token]
	
	var _on_success = func(response):
		if not response is Dictionary:
			on_fail.call("Invalid response: %s" % response)
		on_success.call(response)
	
	return Firebase.send_request(url, HTTPClient.METHOD_GET, {}, [], _on_success, on_fail)

static func remove_member(project_id: String, user_id: String, on_success: Callable = func(_res):pass, on_fail: Callable = func(_err):pass) -> void:
	var payload = {}
	payload["projects/%s/members/%s" % [project_id, user_id]] = null
	payload["users/%s/projects/%s" % [user_id, project_id]] = null

	var root_patch_url = "%s/.json?auth=%s" % [Firebase.project_db_url.trim_suffix("/"), Session.id_token]

	return Firebase.send_request(
			root_patch_url, 
			HTTPClient.METHOD_PATCH, 
			payload, 
			[], 
			on_success, 
			on_fail
	)

static func edit_project(project_id: String, project_name: String, project_description: String, on_success := func(_res):pass, on_fail := func(_err):pass) -> int:
	var path = "%s/projects/%s.json?auth=%s" % [
		Firebase.project_db_url.trim_suffix("/"),
		project_id,
		Session.id_token
	]

	var payload = {
		"name": project_name,
		"description": project_description,
	}

	return Firebase.send_request(
			path, 
			HTTPClient.METHOD_PATCH, 
			payload, 
			["Content-Type: application/json"], 
			on_success, 
			on_fail
	)

static func delete_project(project_id: String, on_success := func(_res):pass, on_fail := func(_err):pass) -> int:
	var updates := {}
	
	for member_uid in CurrentProject.members.keys():
		updates["users/%s/projects/%s" % [member_uid, project_id]] = null
		updates["invites/%s/%s" % [member_uid, project_id]] = null

	updates["projects/%s" % project_id] = null

	var patch_url = "%s/.json?auth=%s" % [Firebase.project_db_url.trim_suffix("/"), Session.id_token]
	return Firebase.send_request(patch_url, HTTPClient.METHOD_PATCH, updates, ["Content-Type: application/json"], on_success, on_fail)
