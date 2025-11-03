extends Object
class_name UserService

static func get_user_projects(
		uid, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/users/%s/projects.json?auth=%s" % \
			[Firebase.project_db_url, Session.uid, Session.id_token]
	
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
			on_fail
	)

static func get_display_name(
		uid: String,
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/users/%s/displayName.json?auth=%s" % \
			[Firebase.project_db_url, uid, Session.id_token]
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_GET, 
			{}, 
			[], 
			on_success, 
			on_fail
	)

static func get_user_by_email(
		user_email:String,
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
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

static func get_user(
		uid: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/users/%s.json?auth=%s" % [
		Firebase.project_db_url.trim_suffix("/"),
		uid,
		Session.id_token
	]
	
	return Firebase.send_request(
		url, 
		HTTPClient.METHOD_GET, 
		{}, 
		[], 
		on_success,
		on_fail
	)
