extends Object
class_name UserService

static func get_user_projects(uid, on_success,on_fail) -> int:
	var url = "%s/users/%s/projects.json?auth=%s" % \
			[Firebase.project_db_url, Session.uid, Session.id_token]
	
	var _on_success = func(result):
		if not result is Dictionary:
			on_fail.call("Invalid response: %s" % result)
		else:
			on_success.call(result)
	
	return Firebase.send_request(url, HTTPClient.METHOD_GET, {}, [], _on_success, on_fail)
