extends Object
class_name ProjectService

# Note: users have a list of ids and roles of projects they are in
# to speed up project list lookup

static func create_project(project_name: String, description: String, on_success: Callable, on_fail: Callable) -> int:
	var url = "%s/projects.json?auth=%s" % [Firebase.project_db_url, Session.id_token]
	
	var body = {
		"name": project_name,
		"description": description,
		"owner": Session.uid,
		"creationDate": int(Time.get_unix_time_from_system()),
		"members": {
			Session.uid:{"role": "owner","joinedDate": int(Time.get_unix_time_from_system())}
		}
	}
	
	var _on_project_created = func(response):
		if !response is Dictionary:
			on_fail.call("Invalid response from Firebase: %s" % response)
		var uid = response.get("name","")
		add_project_to_user(uid,"owner",on_success,on_fail)
	
	return Firebase.send_request(url, 
			HTTPClient.METHOD_POST, 
			body, 
			["Content-Type: application/json"], 
			_on_project_created, 
			on_fail
	)


static func add_project_to_user(uid : String,role : String ,on_success : Callable, on_fail : Callable) -> int:
	var url = "%s/users/%s/projects.json?auth=%s" % [Firebase.project_db_url, Session.uid, Session.id_token]
	var body = { uid: role }
	
	var _on_success = func(response):
		if not response is Dictionary:
			on_fail.call("Invalid response: %s" % response)
		on_success.call(uid)
	
	return Firebase.send_request(url, HTTPClient.METHOD_PATCH, body, ["Content-Type: application/json"], _on_success, on_fail)


static func get_project(uid: String,on_success : Callable, on_fail : Callable) -> int:
	var url = "%s/projects/%s.json?auth=%s" % [Firebase.project_db_url, uid, Session.id_token]
	var body = {}
	
	var _on_success = func(response):
		if not response is Dictionary:
			on_fail.call("Invalid response: %s" % response)
		on_success.call(response)
	
	return Firebase.send_request(url, HTTPClient.METHOD_GET, body, [], _on_success, on_fail)
