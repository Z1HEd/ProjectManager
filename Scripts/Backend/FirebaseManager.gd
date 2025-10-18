extends Node
class_name FirebaseManager

signal request_concluded
signal request_success(request_id: int, data)
signal request_fail(request_id: int, error_msg)

@export var api_key: String = "AIzaSyAYDWyOf_ctpewELcbabKZnQ191V5BYg5Y"
@export var project_db_url: String = "https://projectmanager-39d37-default-rtdb.europe-west1.firebasedatabase.app/" # no trailing slash

var http: HTTPRequest
var is_busy: bool = false
var _queue: Array = []
var _current_request: Dictionary = {}
var _request_counter: int = 0

func _ready() -> void:
	http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(Callable(self, "_on_request_completed"))

# body may be Dictionary or String or null
# on_success, on_fail callbacks may be null
func send_request(url: String, method: int = HTTPClient.METHOD_GET, body = null, headers: Array = [], on_success = null, on_fail = null, tag: String = "") -> int:
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
		"tag": tag
	}
	_queue.append(entry)
	_process_next()
	return req_id

func _process_next() -> void:
	if is_busy:
		return
	if _queue.is_empty():
		return
	_current_request = _queue.pop_front()
	is_busy = true

	var url = _current_request.url
	var method = _current_request.method
	var headers = _current_request.headers.duplicate()
	var payload = ""
	if _current_request.body is Dictionary:
		payload = JSON.stringify(_current_request.body)
		if "Content-Type: application/json" not in headers:
			headers.append("Content-Type: application/json")
	elif _current_request.body is String:
		payload = _current_request.body

	var err = http.request(url, headers, method, payload)
	if err != OK:
		var id = _current_request.id
		var fail_cb = _current_request.on_fail
		is_busy = false
		_current_request = {}
		var msg = "failed to start HTTP request: %s" % err
		if fail_cb and fail_cb is Callable:
			fail_cb.call(msg)
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
				if typeof(e) == TYPE_DICTIONARY and e.has("message"):
					return str(e["message"])
				elif typeof(e) == TYPE_STRING:
					return str(e)
			if r.has("message") and typeof(r["message"]) == TYPE_STRING:
				return str(r["message"])
	return ""

func _on_request_completed(_result: int, response_code: int, _headers: Array, body: PackedByteArray) -> void:
	var id = _current_request.get("id", -1)
	var body_text = body.get_string_from_utf8()
	var parsed = null
	var parsed_ok = false
	var raw_parse_result = null

	if body_text.length() > 0:
		# JSON.parse_string returns a wrapper in Godot 4, so unwrap "result" when present
		raw_parse_result = JSON.parse_string(body_text)
		if raw_parse_result is Dictionary and raw_parse_result.has("result"):
			parsed = raw_parse_result["result"]
			parsed_ok = true
		elif raw_parse_result is Dictionary and raw_parse_result.has("error"):
			# keep wrapper so _extract_error_message can inspect it
			parsed = raw_parse_result
			parsed_ok = false
		else:
			# fallback: try to use the raw_parse_result directly if it seems like the parsed JSON object
			if raw_parse_result is Dictionary:
				parsed = raw_parse_result
				parsed_ok = true
			else:
				# not JSON or empty — keep body text
				parsed = body_text
				parsed_ok = false

	var success_cb = _current_request.get("on_success", null)
	var fail_cb = _current_request.get("on_fail", null)

	if response_code >= 200 and response_code < 300:
		# success
		if success_cb and success_cb is Callable:
			# give the callback the unwrapped parsed object when possible
			success_cb.call(parsed if parsed_ok else body_text)
		emit_signal("request_success", id, parsed if parsed_ok else body_text)
	else:
		var err_msg = _extract_error_message(parsed)
		if err_msg == "":
			err_msg = body_text if body_text.size() > 0 else "HTTP %s" % str(response_code)
		if fail_cb and fail_cb is Callable:
			fail_cb.call(err_msg)
		emit_signal("request_fail", id, err_msg)

	is_busy = false
	_current_request = {}
	emit_signal("request_concluded")
	_process_next()
