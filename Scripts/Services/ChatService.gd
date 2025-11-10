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



# Start listening to chatMessages/<pid> and call on_new_messages(messages_array) for incoming messages.
# on_fail(error_string) is called on errors.
static func start_listening(
		pid: String, 
		on_new_messages:=func(_res):pass, 
		on_fail:=func(_res):pass) -> void:
	
	if _listeners.has(pid):
		return

	var full_url = "%schatMessages/%s.json?auth=%s" % \
			[ Firebase.project_db_url, pid, Session.id_token]
	
	var _on_new_messages = _on_raw_stream_event.bind(on_new_messages)
	
	var listener_id = Streaming.start_listener(full_url, _on_new_messages, on_fail)
	if listener_id == null:
		on_fail.call("failed_to_start_listener")
		return
	_listeners[pid] = listener_id


static func stop_listening(pid: String) -> void:
	if not _listeners.has(pid):
		return
	var id = _listeners[pid]
	Streaming.stop_listener(id)
	_listeners.erase(pid)

# called by StreamingManager when an SSE "put"/"patch" arrives; runs on main thread
static func _on_raw_stream_event(
		on_new_messages: Callable, 
		parsed) -> void:
	# parsed example: { "path": "/-MzA...","data": { ... } } or { "path": "/", "data": { "<msgId>": {...}, ... } }
	if parsed == null:
		return

	# if it's an initial snapshot (path == "/") it may contain many messages.
	var path = parsed.get("path", "/")
	var payload = parsed.get("data",parsed)

	var messages := []
	if path == "/" and typeof(payload) == TYPE_DICTIONARY:
		# Initial snapshot: payload is dict of id -> message
		for key in payload.keys():
			var m = payload[key]
			if typeof(m) == TYPE_DICTIONARY:
				if not m.has("id"):
					m["id"] = key
				messages.append(m)
	else:
		# child changed/added. path = "/<messageId>" or "/<messageId>/subfield"
		var stripped = path.strip_prefix("/")
		var parts = stripped.split("/")
		if parts.size() >= 1 and parts[0] != "":
			var msg_id = parts[0]
			if typeof(payload) == TYPE_DICTIONARY:
				var m = payload.duplicate(true)
				if not m.has("id"):
					m["id"] = msg_id
				messages.append(m)
			else:
				# payload is primitive (unlikely for chat message) - pass raw
				messages.append({ "id": msg_id, "value": payload })
	if messages.size() > 0:
		on_new_messages.call(messages)
