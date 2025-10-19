extends Object
class_name ProjectService


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
	
	# Firebase returns JSON where "name" is created project's uid, pass it just in case
	var _on_project_created = func(response):
		if !response is Dictionary:
			on_fail.call("Invalid response from Firebase: %s" % response)
		on_success.call(response.get("name",""))
	
	return Firebase.send_request(url, 
			HTTPClient.METHOD_POST, 
			body, 
			["Content-Type: application/json"], 
			_on_project_created, 
			on_fail
	)
