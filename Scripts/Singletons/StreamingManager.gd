extends Node
class_name StreamingManager

var _listeners := {}
var _next_id :=0

func start_listener(
		full_url: String, 
		on_event:= func(_res):pass, 
		on_error:= func(_res):pass) -> int:

	var id = _next_id
	_next_id += 1
	var thread = Thread.new()
	var info = {
		"thread": thread,
		"stop_flag": false,
		"on_event": on_event,
		"on_error": on_error,
		"url": full_url,
		"started": false
	}
	_listeners[id] = info

	# start only after token refresh
	var _on_token_ok = func():
		var err = thread.start(_listener_thread.bind(id))
		if err != OK:
			_listeners.erase(id)
			on_error.call("Failed to start listener thread: %s" % err)
			return
		info["started"] = true

	var _on_token_fail = func(err):
		_listeners.erase(id)
		on_error.call(err)

	# ensure id_token is fresh before starting listener thread
	Session.ensure_fresh_token(_on_token_ok, _on_token_fail)

	return id

func stop_listener(listener_id: int) -> void:
	if not _listeners.has(listener_id):
		return
	var info = _listeners[listener_id]
	info.stop_flag = true
	info.thread.wait_to_finish()
	_listeners.erase(listener_id)

func stop_all() -> void:
	for id in _listeners.keys():
		stop_listener(id)

func _listener_thread(listener_id: int) -> void:
	if not _listeners.has(listener_id):
		return
	var info = _listeners[listener_id]
	var url: String = info.url + Session.id_token

	var trimmed = url.replace("https://", "")

	var slash_idx = trimmed.find("/")
	var host = ""
	var path = ""
	if slash_idx == -1:
		host = trimmed
		path = "/"
	else:
		host = trimmed.substr(0, slash_idx)
		path = "/" + trimmed.substr(slash_idx + 1)

	var port = 443

	var client = HTTPClient.new()
	var connect_err = client.connect_to_host(host, port, TLSOptions.client())
	if connect_err != OK:
		call_deferred("_call_error", listener_id, "connect_failed")
		return
	var start_time = Time.get_unix_time_from_system()
	while client.get_status() != HTTPClient.STATUS_CONNECTED:
		if not _listeners.has(listener_id):
			client.close()
			return
		if _listeners[listener_id].stop_flag:
			client.close()
			return
		var _poll_err = client.poll()
		if Time.get_unix_time_from_system() - start_time > 10:
			call_deferred("_call_error", listener_id, "connect_timeout")
			client.close()
			return
		OS.delay_msec(10)

	var headers = ["Accept: text/event-stream"]
	var request_err = client.request(HTTPClient.METHOD_GET, path, headers)
	if request_err != OK:
		call_deferred("_call_error", listener_id, "request_failed")
		client.close()
		return
	
	var buffer := ""
	while true:
		if not _listeners.has(listener_id):
			break
		var listener_info = _listeners[listener_id]
		if listener_info.stop_flag:
			break

		var _poll_err = client.poll()
		while client.get_status() == HTTPClient.STATUS_BODY:
			var chunk: PackedByteArray = client.read_response_body_chunk()
			if chunk.size() == 0:
				break
			
			var s = chunk.get_string_from_utf8()
			if s != "":
				buffer += s
				buffer = buffer.replace("\r\n", "\n")
				while true:
					var sep_idx = buffer.find("\n\n")
					if sep_idx == -1:
						break
					var block = buffer.substr(0, sep_idx)
					var remaining_start = sep_idx + 2
					var remaining_len = buffer.length() - remaining_start
					if remaining_len > 0:
						buffer = buffer.substr(remaining_start, remaining_len)
					else:
						buffer = ""
					_process_sse_block(listener_id, block)

		if client.get_status() == HTTPClient.STATUS_DISCONNECTED:
			print("disconnected")
			call_deferred("_call_error", listener_id, "disconnected")
			break

		OS.delay_msec(10)

	client.close()
	if _listeners.has(listener_id):
		_listeners.erase(listener_id)

func _process_sse_block(listener_id: int, block: String) -> void:
	var lines = block.split("\n", true)
	var event_type := ""
	var data_lines : PackedStringArray= []
	for l in lines:
		if l.begins_with("event:"):
			var tmp = l.substr(6)
			event_type = tmp.strip_edges()
		elif l.begins_with("data:"):
			var tmp2 = l.substr(5)
			data_lines.append(tmp2)
	
	if event_type=="cancel":
		print("cancelled")
		_call_error(listener_id, "cancel")
		return
	
	var data_text = ""
	if data_lines.size() > 0:
		data_text = "\n".join(data_lines).strip_edges()
	
	var parsed = null
	if data_text != "":
		parsed = FirebaseManager._parse_response_body(data_text)
	
	call_deferred("_deliver_sse_event", listener_id, event_type, parsed)

func _deliver_sse_event(listener_id: int, event_type: String, parsed) -> void:
	var info = _listeners[listener_id]
	var on_event: Callable = info.on_event
	var on_error: Callable = info.on_error
	
	if event_type == "put" or event_type == "patch":
		on_event.call(parsed)
		return
	if event_type == "keep-alive" or event_type == "":
		return
	
	var m = "sse_event_" + event_type
	on_error.call(m)

func _call_error(listener_id: int, message: String) -> void:
	if not _listeners.has(listener_id):
		return
	var on_error: Callable = _listeners[listener_id].on_error
	on_error.call_deferred(message)
	_listeners[listener_id].stop_flag = true
