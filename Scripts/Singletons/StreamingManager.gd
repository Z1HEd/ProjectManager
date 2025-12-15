extends Node
class_name StreamingManager

const HTTPS_PORT := 443

var _listeners := {}
var _next_id := 0
var event_queue := []
var event_mutex := Mutex.new()

func _process(_delta: float) -> void:
	if event_queue.is_empty():
		return

	var events := []

	event_mutex.lock()
	events = event_queue
	event_queue = []
	event_mutex.unlock()

	for event in events:
		event.callback.call(event.message)

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
		"started": false,
		"reconnect_requested": false,
		"session_cb": null
	}
	_listeners[id] = info

	info.session_cb = func():
		if !_listeners.has(id):
			return
		var listener = _listeners[id]
		if not listener.stop_flag:
			listener.reconnect_requested = true
	
	Session.refreshed.connect(info.session_cb)
	
	var err = thread.start(_listener_thread.bind(id))
	if err != OK:
		on_error.call("Failed to start listener thread: %s" % err)
	else:
		_listeners[id].started = true

	return id

func stop_listener(listener_id: int) -> void:
	if not _listeners.has(listener_id):
		return
	
	var listener = _listeners[listener_id]
	listener.stop_flag = true
	Session.refreshed.disconnect(listener.session_cb)
	listener.thread.wait_to_finish()
	_listeners.erase(listener_id)

func stop_all() -> void:
	for id in _listeners.keys():
		stop_listener(id)

func _listener_thread(listener_id: int) -> void:
	var token := Session.id_token

	while not _listeners[listener_id].stop_flag:
		var info = _listeners[listener_id]
		var url: String = info.url + token
		var trimmed = url.replace("https://", "")

		var slash_idx = trimmed.find("/")
		var host = trimmed.substr(0, slash_idx)
		var path = "/" + trimmed.substr(slash_idx + 1)

		var client = HTTPClient.new()
		var connect_err = client.connect_to_host(host, HTTPS_PORT, TLSOptions.client())
		if connect_err != OK:
			_handle_error(listener_id, "connect_failed")
			break
		
		var start_time = Time.get_unix_time_from_system()
		while client.get_status() != HTTPClient.STATUS_CONNECTED:
			if _listeners[listener_id].stop_flag:
				client.close()
				return
			
			client.poll()
			
			if Time.get_unix_time_from_system() - start_time > 10:
				_handle_error(listener_id, "connect_timeout")
				client.close()
				return
			
			OS.delay_msec(10)

		var headers = ["Accept: text/event-stream"]
		print("Connecting a listener: %s" % path.substr(0,path.find("?")))
		var request_err = client.request(HTTPClient.METHOD_GET, path, headers)
		if request_err != OK:
			_handle_error(listener_id, "request_failed")
			client.close()
			break
		
		var buffer := ""
		while not _listeners[listener_id].stop_flag and \
				not _listeners[listener_id].reconnect_requested:

			client.poll()
			while client.get_status() == HTTPClient.STATUS_BODY:
				var response := client.read_response_body_chunk().get_string_from_utf8()
				if response.length() == 0:
					break
				buffer += response
				buffer = _extract_and_process_sse_blocks(buffer,listener_id)

			if client.get_status() == HTTPClient.STATUS_DISCONNECTED:
				if not _listeners[listener_id].reconnect_requested:
					_handle_error(listener_id, "disconnected")
				break

			OS.delay_msec(10)

		client.close()
		
		info = _listeners[listener_id]
		
		if info.reconnect_requested:
			token = Session.id_token
			info.reconnect_requested = false
			OS.delay_msec(200)
			continue

		OS.delay_msec(200)

	if _listeners.has(listener_id):
		_listeners.erase(listener_id)

func _extract_and_process_sse_blocks(buffer: String, listener_id: int) -> String:
	while true:
		var delimeter := _find_sse_delimiter(buffer)
		var sep_idx := delimeter[0]
		var sep_length := delimeter[1]
		
		if sep_idx == -1:
			break
		
		var block = buffer.substr(0, sep_idx)
		var remaining_start = sep_idx + sep_length
		
		if remaining_start < buffer.length():
			buffer = buffer.substr(remaining_start)
		else:
			buffer = ""
		
		block = block.replace("\r\n", "\n")
		_process_sse_block(listener_id, block)
	
	return buffer

# returns [sep_idx, sep_len] or [-1, 0] if not found
func _find_sse_delimiter(buffer: String) -> Array[int]:
	var idx = buffer.find("\r\n\r\n")
	if idx != -1:
		return [idx, 4]
	
	idx = buffer.find("\n\n")
	if idx != -1:
		return [idx, 2]
	
	return [-1, 0]

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
		_handle_error(listener_id, "cancel")
		return
	
	if event_type == "keep-alive" or event_type == "":
		return
	
	if event_type != "put" and event_type != "patch":
		var m = "sse_event_" + event_type
		push_event({"callback":_listeners[listener_id].on_error,"message":m})
	
	var data_text = ""
	if data_lines.size() > 0:
		data_text = "\n".join(data_lines).strip_edges()
	
	var parsed = null
	if data_text != "":
		parsed = FirebaseManager._parse_response_body(data_text)
	push_event({"callback":_listeners[listener_id].on_event,"message":parsed})

func _handle_error(listener_id: int, message: String) -> void:
	push_event({"callback":_listeners[listener_id].on_error,"message":message})
	_listeners[listener_id].stop_flag = true

func push_event(event:Dictionary):
	event_mutex.lock()
	event_queue.append(event)
	event_mutex.unlock()
