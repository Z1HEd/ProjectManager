extends Node
class_name FirebaseManager

signal request_concluded
signal request_success(request_id: int, data)
signal request_fail(request_id: int, error_msg)

@export var api_key: String = "AIzaSyAYDWyOf_ctpewELcbabKZnQ191V5BYg5Y"
@export var project_db_url: String = "https://projectmanager-39d37-default-rtdb.europe-west1.firebasedatabase.app"

var http: HTTPRequest
var is_busy: bool = false
var _queue: Array = []
var _current_request: Dictionary = {}
var _request_counter: int = 0

func _ready() -> void:
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed)

# body may be Dictionary or String or null
func send_request(url: String, method : HTTPClient.Method, body, headers: Array, on_success : Callable, on_fail : Callable, tag := "") -> int:
	var req_id = _request_counter
	_request_counter += 1
	var entry := {
		"id": req_id,
		"url": url,
		"method": method,
		"body": body,
		"headers": headers,
		"on_success": on_success,
		"on_fail": on_fail,
		"tag":tag
	}
	
	if tag == "auth":
		_queue.push_front(entry)
	else:
		_queue.append(entry)
	
	_process_next()
	return req_id

func _process_next() -> void:
	if is_busy:
		return
	if _queue.is_empty():
		return

	var  _on_refresh_failed = func(err) -> void:
		_current_request["on_fail"].call("Failed to refresh session: %s" % err)
		request_fail.emit(_current_request["id"], err)
		
		is_busy = false
		_current_request = {}
		
		request_concluded.emit()
		_process_next()

	if Session.is_token_expired() and _queue[0]["tag"] != "auth":
		Session.ensure_fresh_token(_process_next, _on_refresh_failed)
		return
	
	_current_request = _queue.pop_front()
	is_busy = true
	_send_current_request()

# Starts the HTTP request for the _current_request
func _send_current_request() -> void:
	var url = _current_request.url
	if _current_request.tag != "auth": url+= Session.id_token
	
	var payload = ""
	if _current_request.body is Dictionary:
		payload = JSON.stringify(_current_request.body)
	elif _current_request.body is String:
		payload = _current_request.body
	
	var method = _current_request.method
	var headers = _current_request.headers.duplicate()
	
	var err = http.request(url, headers, method, payload)
	if err != OK:
		
		var id = _current_request.id
		is_busy = false
		var msg = "failed to start HTTP request: %s" % err
		_current_request.on_fail.call(msg)
		
		_current_request = {}
		emit_signal("request_fail", id, msg)
		emit_signal("request_concluded")
		_process_next()

func _extract_error_message(parsed) -> String:
	# Accept either:
	#  - parsed == actual response Dictionary
	#  - parsed == JSON.parse_string() wrapper with keys "result" or "error"
	if parsed is Dictionary:
		# case: wrapper returned by JSON.parse_string() (Godot 4)
		if parsed.has("error"):
			var err_block = parsed["error"]
			if err_block is Dictionary and err_block.has("message"):
				return str(err_block["message"])
			elif err_block is String:
				return str(err_block)
		# case: some Firebase responses put message at top-level
		if parsed.has("message") and parsed["message"] is String:
			return str(parsed["message"])
		# case: the actual result object might itself hold an "error" or "message"
		if parsed.has("result") and parsed["result"] is Dictionary:
			var r = parsed["result"]
			if r.has("error"):
				var e = r["error"]
				if e is Dictionary and e.has("message"):
					return str(e["message"])
				elif e is String:
					return str(e)
			if r.has("message") and r["message"] is String:
				return str(r["message"])
	return ""

static func _parse_response_body(body_text: String) :
	if body_text == null or body_text.strip_edges(true, true) == "":
		return ""

	if body_text == "null":
		return null
	var raw = JSON.parse_string(body_text)

	if raw is Dictionary:
		var err_val = raw.get("error", null)
		if err_val != null:
			return raw
		var res = raw.get("result", null)
		if res != null:
			return res
		return raw
	
	body_text = body_text.trim_prefix('"')
	body_text = body_text.trim_suffix('"')
	
	return body_text

func _on_request_completed(_result: int, response_code: int, _headers: Array, body: PackedByteArray) -> void:
	var id = _current_request.get("id", -1)
	var body_text = body.get_string_from_utf8()

	var parsed = _parse_response_body(body_text)
	
	var success_cb = _current_request["on_success"]
	var fail_cb = _current_request["on_fail"]

	if response_code >= 200 and response_code < 300:
		success_cb.call(parsed)
		is_busy = false
		_current_request = {}
		emit_signal("request_concluded")
		emit_signal("request_success", id, parsed)
		_process_next()
	else:
		var err_msg = _extract_error_message(parsed)
		if err_msg == "": err_msg = _get_error_message_from_result_code(_result)
		var is_perm_error = (response_code == 401) or \
				(err_msg is String and err_msg.findn("Permission denied") != -1)
		var already_retried = _current_request.get("retried", false)

		if !is_perm_error or already_retried:
			is_busy = false
			_current_request = {}
			emit_signal("request_fail", id, err_msg)
			emit_signal("request_concluded")
			fail_cb.call(err_msg)
			_process_next()
			return
		
		var _on_refresh_success = func():
			_current_request["retried"] = true
			_send_current_request()

		var _on_refresh_fail = func(err):
			# refresh failed -> call original fail callback
			var fail_msg = "token_refresh_failed: %s" % str(err)
			is_busy = false
			_current_request = {}
			emit_signal("request_concluded")
			emit_signal("request_fail", id, fail_msg)
			fail_cb.call(fail_msg)
			_process_next()

		Session.ensure_fresh_token(_on_refresh_success, _on_refresh_fail)
		return

func _get_error_message_from_result_code(result:HTTPRequest.Result):
	match result:
		HTTPRequest.RESULT_CANT_CONNECT:
			return "Cannot connect to server."
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "Cannot resolve host."
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "Connection error."
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return "TLS handshake failed."
		HTTPRequest.RESULT_TIMEOUT:
			return "Request timed out."
		HTTPRequest.RESULT_NO_RESPONSE:
			return "No response from server."
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
			return "Invalid chunked response."
		HTTPRequest.RESULT_BODY_DECOMPRESS_FAILED:
			return "Response decompression failed."
	return ""
