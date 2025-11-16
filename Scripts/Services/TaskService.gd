extends Node
class_name TaskService

static func create_task(
		pid: String, 
		title: String, 
		description := "", 
		assigned_to := "", 
		priority := "medium", 
		status := "todo", 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/tasks/%s.json?auth=" % [Firebase.project_db_url, pid]
	
	var body = {
		"title": title,
		"description": description,
		"creatorId": Session.uid,
		"createdAt": { ".sv": "timestamp" },
		"updatedAt": { ".sv": "timestamp" },
		"lastModifiedBy": Session.uid,
		"status": status,
		"priority": priority
	}
	
	if assigned_to != "":
		body["assignedTo"] = assigned_to
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_POST, 
			body, 
			["Content-Type: application/json"], 
			on_success, 
			on_fail)

static func delete_task(
		pid: String, 
		task_id: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/tasks/%s/%s.json?auth=" % \
			[Firebase.project_db_url, pid, task_id]
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_DELETE, 
			null, 
			[], 
			on_success, 
			on_fail)

static func get_all(
		pid: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/tasks/%s.json?auth=" % [Firebase.project_db_url, pid]
	
	var _on_success = func(response):
		if response == null:
			on_success.call({})
			return
		on_success.call(response)
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_GET, 
			{}, 
			[], 
			_on_success, 
			on_fail)
