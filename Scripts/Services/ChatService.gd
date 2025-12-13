extends Object
class_name ChatService

# pid -> listener_id mapping
static var _listeners := {}

static func send_message(
		pid: String,
		message: String,
		on_success := func(_res):pass,
		on_fail := func(_err):pass) -> int:

	var url = "%s/chatMessages/%s.json?auth=" % [Firebase.project_db_url, pid]
	
	var body = {
		"authorId": Session.uid,
		"text": message,
		"ts_server": { ".sv": "timestamp" }
	}
	
	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to send a message:\n%s" % err_msg)
		on_fail.call(err_msg)
	
	return Firebase.send_request(
			url,
			HTTPClient.METHOD_POST,
			body,
			["Content-Type: application/json"],
			on_success,
			_on_fail)

static func fetch_recent(
		pid: String,
		limit := 25,
		on_success := func(_res):pass,
		on_fail := func(_err):pass) -> int:

	var url = "%s/chatMessages/%s.json?orderBy=%%22ts_server%%22&limitToLast=%d&auth=" % \
			[Firebase.project_db_url, pid, limit]

	var _on_success = func(response):
		if response == null:
			on_success.call({})
			return
		if not response is Dictionary:
			on_fail.call("Invalid response: %s" % response)
			return
		on_success.call(response)
	
	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to fetch recent messages:\n%s" % err_msg)
		on_fail.call(err_msg)
	
	return Firebase.send_request(
			url,
			HTTPClient.METHOD_GET,
			{},
			[],
			_on_success,
			_on_fail)

static func fetch_before(
		pid: String,
		before_key: String,
		limit := 25,
		on_success := func(_res):pass,
		on_fail := func(_err):pass) -> int:

	var url = "%s/chatMessages/%s.json?orderBy=%%22$key%%22&endAt=%%22%s%%22&limitToLast=%d&auth=" % \
		[Firebase.project_db_url, pid, before_key, limit]
	
	var _on_fail = func(err_msg:String):
		AppNotifications.push("Failed to fetch old messages:\n%s" % err_msg)
		on_fail.call(err_msg)
	
	var _on_success = func(response):
		if response == null:
			on_success.call({})
			return
		if not response is Dictionary:
			_on_fail.call("Invalid response: %s" % response)
			return
		on_success.call(response)
	
	return Firebase.send_request(
		url,
		HTTPClient.METHOD_GET,
		{},
		[],
		_on_success,
		_on_fail)

static func start_listening(
	pid: String,
	limit: int,
	on_new_messages := func(_res):pass,
	on_fail := func(_err):pass) -> void:

	if _listeners.has(pid):
		return

	var full_url = "%s/chatMessages/%s.json?orderBy=%%22ts_server%%22&limitToLast=%d&auth=" % \
			[Firebase.project_db_url, pid, limit]

	var _on_new_messages = _on_update.bind(on_new_messages)
	
	var _on_fail = func(err_msg:String):
		_listeners.erase(pid)
		if err_msg == "cancel":
			return
		AppNotifications.push("Failed to start message listener:\n%s"%err_msg)
		on_fail.call(err_msg)
	
	var listener_id = Streaming.start_listener(full_url, _on_new_messages, _on_fail)
	
	_listeners[pid] = listener_id

static func stop_listening(pid: String) -> void:
	if not _listeners.has(pid):
		return
	var id = _listeners[pid]
	Streaming.stop_listener(id)
	_listeners.erase(pid)

static func _on_update(
		parsed,
		on_new_messages: Callable) -> void:

	var path : String = parsed["path"]
	var payload = parsed["data"]

	if payload == null:
		return
	var messages := []
	if path == "/":
		# Payload is dict of id -> message
		for key in payload.keys():
			var m = payload[key]
			m["id"] = key
			messages.append(m)
	else:
		# child added. path = "/<messageId>"
		var msg_id = path.lstrip("/")
		var m = payload.duplicate(true)
		m["id"] = msg_id
		messages.append(m)
	
	on_new_messages.call(messages)
