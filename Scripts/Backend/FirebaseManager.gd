extends Node
class_name FirebaseManager

@export var http_request :HTTPRequest
@export var database_url :String = "https://projectmanager-39d37-default-rtdb.europe-west1.firebasedatabase.app/"

func test_connection()->bool:
	print("Testing connection to Firebase")
	var error = http_request.request(database_url+"/.json")
	
	if error != OK:
		push_error("HTTPRequest error: %s" % error)
		return false
	
	var result = await http_request.request_completed
	
	var response_code = result[1]
	var body = result[3]
	
	if response_code in [200, 204]:
		print("Firebase connection works")
		return true
	else:
		print("Firebase connection failed: error %d" % response_code)
		print("Response:", body.get_string_from_utf8())
		return false
