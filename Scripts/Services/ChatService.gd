extends Object
class_name ChatService

# pid -> listener_id mapping
static var _listeners := {}

static func send_message(
		pid: String,
		message: String,
		on_success := func(_res):pass,
		on_fail := func(_err):pass) -> int:

	var url = "%s/chatMessages/%s.json?auth=%s" % [Firebase.project_db_url, pid, Session.id_token]
	
	var body = {
		"authorId": Session.uid,
		"text": message,
		"ts_server": { ".sv": "timestamp" }
	}

	return Firebase.send_request(
		url,
		HTTPClient.METHOD_POST,
		body,
		["Content-Type: application/json"],
		on_success,
		on_fail
	)

static func fetch_recent(
		pid: String,
		limit := 25,
		on_success := func(_res):pass,
		on_fail := func(_err):pass) -> int:

	var url = "%s/chatMessages/%s.json?orderBy=%%22ts_server%%22&limitToLast=%d&auth=%s" % \
			[Firebase.project_db_url, pid, limit, Session.id_token]

	var _on_success = func(response):
		if response == null:
			on_success.call({})
			return
		if not response is Dictionary:
			on_fail.call("Invalid response: %s" % response)
			return
		on_success.call(response)

	return Firebase.send_request(
			url,
			HTTPClient.METHOD_GET,
			{},
			[],
			_on_success,
			on_fail,
			"chat"
	)

static func fetch_before(
		pid: String,
		before_key: String,
		limit := 25,
		on_success := func(_res):pass,
		on_fail := func(_err):pass) -> int:

	var url = "%s/chatMessages/%s.json?orderBy=%%22$key%%22&endAt=%%22%s%%22&limitToLast=%d&auth=%s" % \
		[Firebase.project_db_url, pid, before_key, limit, Session.id_token]

	var _on_success = func(response):
		if response == null:
			on_success.call({})
			return
		if not response is Dictionary:
			on_fail.call("Invalid response: %s" % response)
			return

		response.erase(before_key)

		on_success.call(response)

	return Firebase.send_request(
		url,
		HTTPClient.METHOD_GET,
		{},
		[],
		_on_success,
		on_fail,
		"chat"
	)

static func start_listening(
	pid: String,
	last_known_key: String,
	on_new_messages := func(_res):pass,
	on_fail := func(_err):pass) -> void:

	if _listeners.has(pid):
		return

	var full_url = "%schatMessages/%s.json?orderBy=%%22$key%%22&startAfter=%%22%s%%22&auth=%s" % \
		[ Firebase.project_db_url, pid, last_known_key, Session.id_token ]

	var _on_new_messages = _on_raw_stream_event.bind(on_new_messages)
	
	var _on_error = func(err:String):
		_listeners.erase(pid)
		on_fail.call(err)
	
	var listener_id = Streaming.start_listener(full_url, _on_new_messages, _on_error)
	
	_listeners[pid] = listener_id

static func stop_listening(pid: String) -> void:
	if not _listeners.has(pid):
		return
	var id = _listeners[pid]
	Streaming.stop_listener(id)
	_listeners.erase(pid)

static func _on_raw_stream_event(
		parsed,
		on_new_messages: Callable) -> void:

	var path : String = parsed["path"]
	var payload = parsed["data"]

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

	if messages.size() > 0:
		on_new_messages.call(messages)
