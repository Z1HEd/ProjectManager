extends Node
class_name TaskService

# pid -> listener_id mapping
static var _listeners := {}

static func create_task(
		pid: String,
		data: Dictionary,
		on_success := func(_res):pass,
		on_fail := func(_err):pass) -> int:

	var url = "%s/tasks/%s.json?auth=" % [Firebase.project_db_url, pid]

	data["createdAt"] = { ".sv": "timestamp" }
	data["updatedAt"] = { ".sv": "timestamp" }
	data["lastModifiedBy"] = Session.uid
	data["creatorId"] = Session.uid

	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to create a task:\n%s" % err_msg)
		on_fail.call(err_msg)

	return Firebase.send_request(
			url,
			HTTPClient.METHOD_POST,
			data,
			["Content-Type: application/json"],
			on_success,
			_on_fail)

static func modify_task(
		pid: String, 
		task_id: String, 
		data: Dictionary, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/tasks/%s/%s.json?auth=" % \
			[Firebase.project_db_url, pid, task_id]
	
	data["updatedAt"] = { ".sv": "timestamp" }
	data["lastModifiedBy"] =  Session.uid
	
	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to modify a task:\n%s" % err_msg)
		on_fail.call(err_msg)
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_PATCH, 
			data, 
			["Content-Type: application/json"], 
			on_success, 
			_on_fail)

static func update_status(pid: String, task_id: String, status: String, on_success := func(_res):pass, on_fail := func(_err):pass) -> int:
	var url = "%s/tasks/%s/%s.json?auth=" % [Firebase.project_db_url, pid, task_id]
	
	var body = {
		"status": status,
		"updatedAt": { ".sv": "timestamp" },
		"lastModifiedBy": Session.uid
	}
	
	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to update task status:\n%s" % err_msg)
		on_fail.call(err_msg)
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_PATCH, 
			body, 
			["Content-Type: application/json"], 
			on_success, 
			_on_fail)

static func delete_task(
		pid: String, 
		task_id: String, 
		on_success := func(_res):pass, 
		on_fail := func(_err):pass) -> int:
	
	var url = "%s/tasks/%s/%s.json?auth=" % \
			[Firebase.project_db_url, pid, task_id]
	
	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to delete a task:\n%s" % err_msg)
		on_fail.call(err_msg)
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_DELETE, 
			null, 
			[], 
			on_success, 
			_on_fail)

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
	
	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to fetch tasks data:\n%s" % err_msg)
		on_fail.call(err_msg)
	
	return Firebase.send_request(
			url, 
			HTTPClient.METHOD_GET, 
			{}, 
			[], 
			_on_success, 
			_on_fail)

static func start_listening(pid: String, on_task_updates := func(_res):pass, on_fail := func(_err):pass) -> void:
	if _listeners.has(pid):
		return

	var full_url = "%s/tasks/%s.json?orderBy=%%22updatedAt%%22&auth=" % [Firebase.project_db_url, pid]

	var _on_new = _on_update.bind(on_task_updates)

	var _on_fail = func(err_msg:String):
		_listeners.erase(pid)
		AppNotifications.push("Failed to start a task listener:\n%s" % err_msg)
		on_fail.call(err_msg)

	var listener_id = Streaming.start_listener(full_url, _on_new, _on_fail)

	_listeners[pid] = listener_id

static func stop_listening(pid: String) -> void:
	if not _listeners.has(pid):
		return
	var id = _listeners[pid]
	Streaming.stop_listener(id)
	_listeners.erase(pid)

static func _on_update(parsed, on_task_updates: Callable) -> void:
	var path : String = parsed["path"]
	var payload = parsed["data"]

	var tasks := {}
	if path == "/":
		# payload is dict of id -> task
		for key in payload.keys():
			tasks[key] = payload[key]
	else:
		# child changed/added. path = "/<taskId>"
		var task_id = path.lstrip("/")
		tasks[task_id] = payload.duplicate(true) if payload != null else null

	if tasks.size() > 0:
		on_task_updates.call(tasks)
