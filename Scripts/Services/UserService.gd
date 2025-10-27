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

static func get_display_name(uid,on_success,on_fail):
	var url = "%s/users/%s/displayName.json?auth=%s" % \
			[Firebase.project_db_url, uid, Session.id_token]
	
	return Firebase.send_request(url, HTTPClient.METHOD_GET, {}, [], on_success, on_fail)

static func get_user_by_email(user_email:String,on_success,on_fail):
	var query_url = '%s/users.json?orderBy="email"&equalTo="%s"&auth=%s' % [
		Firebase.project_db_url.trim_suffix("/"),
		user_email,
		Session.id_token
	]

	return Firebase.send_request(
		query_url,
		HTTPClient.METHOD_GET,
		{},
		[],
		on_success,
		on_fail
	)
